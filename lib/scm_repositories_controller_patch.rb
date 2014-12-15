require_dependency 'repositories_controller'

module ScmRepositoriesControllerPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            before_filter :delete_scm, :only => :destroy

            alias_method_chain :destroy, :confirmation

            if Project.method_defined?(:repositories)
                alias_method_chain :create, :scm
                alias_method_chain :update, :scm
            else
                alias_method_chain :edit, :scm
            end
        end
    end

    module InstanceMethods

        def delete_scm
            if @repository.created_with_scm && ScmConfig['deny_delete']
                Rails.logger.info "Deletion denied: #{@repository.root_url}"
                render_403
            end
        end

        # Redmine >= 1.4.x
        if Project.method_defined?(:repositories)

            # Original function
            #def create
            #    attrs = pickup_extra_info
            #    @repository = Repository.factory(params[:repository_scm])
            #    @repository.safe_attributes = params[:repository]
            #    if attrs[:attrs_extra].keys.any?
            #        @repository.merge_extra_info(attrs[:attrs_extra])
            #    end
            #    @repository.project = @project
            #    if request.post? && @repository.save
            #        redirect_to settings_project_path(@project, :tab => 'repositories')
            #    else
            #        render :action => 'new'
            #    end
            #end

            def create_with_scm
                interface = SCMCreator.interface(params[:repository_scm])

                if (interface && (interface < SCMCreator) && interface.enabled? &&
                  ((params[:operation].present? && params[:operation] == 'add') || ScmConfig['only_creator'])) ||
                   !ScmConfig['allow_add_local']

                    attributes = {}
                    extra_attrs = {}
                    params[:repository].each do |name, value|
                        if name =~ %r{\Aextra_}
                            extra_attrs[name] = value
                        else
                            attributes[name] = value
                        end
                    end

                    if params[:operation].present? && params[:operation] == 'add'
                        attributes = interface.sanitize(attributes)
                    end

                    @repository = Repository.factory(params[:repository_scm])
                    if @repository.respond_to?(:safe_attribute_names) && @repository.safe_attribute_names.any?
                        @repository.safe_attributes = attributes
                    else # Redmine < 2.2
                        @repository.attributes = attributes
                    end
                    if extra_attrs.any?
                        @repository.merge_extra_info(extra_attrs)
                    end

                    if @repository
                        @repository.project = @project

                        if @repository.valid? && params[:operation].present? && params[:operation] == 'add'
                            if !ScmConfig['max_repos'] || ScmConfig['max_repos'].to_i == 0 ||
                               @project.repositories.select{ |r| r.created_with_scm }.size < ScmConfig['max_repos'].to_i
                                scm_create_repository(@repository, interface, attributes['url'])
                            else
                                @repository.errors.add(:base, :scm_repositories_maximum_count_exceeded, :max => ScmConfig['max_repos'].to_i)
                            end
                        end

                        if ScmConfig['only_creator'] && request.post? && @repository.errors.empty? && !@repository.created_with_scm
                            @repository.errors.add(:base, :scm_only_creator)
                        elsif !ScmConfig['allow_add_local'] && request.post? && @repository.errors.empty? && !@repository.created_with_scm &&
                            attributes['url'] =~ %r{\A(file://|([a-z]:)?\.*[\\/])}i
                            @repository.errors.add(:base, :scm_local_repositories_denied)
                        end

                        if request.post? && @repository.errors.empty? && @repository.save
                            redirect_to(settings_project_path(@project, :tab => 'repositories'))
                        else
                            render(:action => 'new')
                        end
                    else
                        render(:action => 'new')
                    end

                else
                    create_without_scm
                end
            end

            def update_with_scm
                update_without_scm

                if @repository.is_a?(Repository::Github) && # special case for Github
                   params[:repository][:extra_register_hook] == '1' && !@repository.extra_hook_registered
                    flash[:warning] = l(:warning_github_hook_registration_failed)
                end
            end

        # Redmine < 1.4.x or ChiliProject
        else

            # Original function
            #def edit
            #    @repository = @project.repository
            #    if !@repository && !params[:repository_scm].blank?
            #        @repository = Repository.factory(params[:repository_scm])
            #        @repository.project = @project if @repository
            #    end
            #    if request.post? && @repository
            #        p1 = params[:repository]
            #        p       = {}
            #        p_extra = {}
            #        p1.each do |k, v|
            #            if k =~ /\Aextra_/
            #                p_extra[k] = v
            #            else
            #                p[k] = v
            #            end
            #        end
            #        @repository.attributes = p
            #        @repository.merge_extra_info(p_extra)
            #        @repository.save
            #    end
            #    render(:update) do |page|
            #        page.replace_html("tab-content-repository", :partial => 'projects/settings/repository')
            #        if @repository && !@project.repository
            #            @project.reload
            #            page.replace_html("main-menu", render_main_menu(@project))
            #        end
            #    end
            #end

            def edit_with_scm
                interface = SCMCreator.interface(params[:repository_scm])

                if (interface && (interface < SCMCreator) && interface.enabled? &&
                  ((params[:operation].present? && params[:operation] == 'add') || ScmConfig['only_creator'])) ||
                   !ScmConfig['allow_add_local']

                    @repository = @project.repository
                    if !@repository && !params[:repository_scm].blank?
                        @repository = Repository.factory(params[:repository_scm])
                        @repository.project = @project if @repository
                    end

                    if request.post? && @repository
                        attributes = params[:repository]
                        attrs = {}
                        extra = {}
                        attributes.each do |name, value|
                            if name =~ %r{\Aextra_}
                                extra[name] = value
                            else
                                attrs[name] = value
                            end
                        end
                        if params[:operation].present? && params[:operation] == 'add'
                            attrs = interface.sanitize(attrs)
                        end
                        @repository.attributes = interface.sanitize(attrs)

                        if @repository.valid? && params[:operation].present? && params[:operation] == 'add'
                            scm_create_repository(@repository, interface, attrs['url']) if attrs
                        end

                        if ScmConfig['only_creator'] && @repository.errors.empty? && !@repository.created_with_scm
                            @repository.errors.add(:base, :scm_only_creator)
                        elsif !ScmConfig['allow_add_local'] && @repository.errors.empty? && !@repository.created_with_scm &&
                            attrs['url'] =~ %r{\A(file://|([a-z]:)?\.*[\\/])}i
                            @repository.errors.add(:base, :scm_local_repositories_denied)
                        end

                        if @repository.errors.empty?
                            @repository.merge_extra_info(extra) if @repository.respond_to?(:merge_extra_info)
                            @repository.save
                        end
                    end

                    render(:update) do |page|
                        page.replace_html("tab-content-repository", :partial => 'projects/settings/repository')
                        if @repository && !@project.repository
                            @project.reload
                            page.replace_html("main-menu", render_main_menu(@project))
                        end
                    end

                else
                    edit_without_scm
                end
            end

        end

        def destroy_with_confirmation
            if @repository.created_with_scm
                if params[:confirm]
                    unless params[:confirm_with_scm]
                        @repository.created_with_scm = false
                    end

                    destroy_without_confirmation
                end
            else
                destroy_without_confirmation
            end
        end

    private

        def scm_create_repository(repository, interface, url)
            name = interface.repository_name(url)
            if name
                path = interface.default_path(name)
                if interface.repository_exists?(name)
                    repository.errors.add(:url, :already_exists)
                else
                    Rails.logger.info "Creating reporitory: #{path}"
                    interface.execute(ScmConfig['pre_create'], path, @project) if ScmConfig['pre_create']
                    if result = interface.create_repository(path, repository)
                        path = result if result.is_a?(String)
                        interface.execute(ScmConfig['post_create'], path, @project) if ScmConfig['post_create']
                        repository.created_with_scm = true
                    else
                        repository.errors.add(:base, :scm_repository_creation_failed)
                        Rails.logger.error "Repository creation failed"
                    end
                end

                repository.root_url = interface.access_root_url(path, repository)
                repository.url      = interface.access_url(path, repository)

                if interface.local? && !interface.belongs_to_project?(name, @project.identifier)
                    flash[:warning] = l(:text_cannot_be_used_redmine_auth)
                end
            else
                repository.errors.add(:url, :should_be_of_format_local, :repository_format => interface.repository_format)
            end

            # Otherwise input field will be disabled
            if repository.errors.any?
                repository.root_url = nil
                repository.url = nil
            end
        end

    end

end
