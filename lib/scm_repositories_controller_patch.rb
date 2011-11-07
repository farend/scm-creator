require_dependency 'repositories_controller'

module ScmRepositoriesControllerPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            before_filter :delete_scm, :only => :destroy
            alias_method :edit, :edit_with_add
        end
    end

    module ClassMethods
    end

    module InstanceMethods

        def delete_scm
            if @repository.created_with_scm && ScmConfig['deny_delete']
                RAILS_DEFAULT_LOGGER.info "Deletion denied: #{@repository.url}"
                render_403
            end
        end

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
        #            if k =~ /^extra_/
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

        def edit_with_add
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
                    if name =~ %r{^extra_}
                        extra[name] = value
                    else
                        attrs[name] = value
                    end
                end
                @repository.attributes = attrs

                if @repository.valid? && params[:operation].present? && params[:operation] == 'add'
                    if attrs

                        begin
                            interface = Object.const_get("#{params[:repository_scm]}Creator")

                            name = interface.repository_name(attrs['url'])
                            if name
                                path = interface.path(name)
                                if File.directory?(path)
                                    @repository.errors.add(:url, :already_exists)
                                else
                                    RAILS_DEFAULT_LOGGER.info "Creating reporitory: #{path}"
                                    interface.execute(ScmConfig['pre_create'], path, @project) if ScmConfig['pre_create']
                                    if interface.create_repository(path)
                                        interface.execute(ScmConfig['post_create'], path, @project) if ScmConfig['post_create']
                                        @repository.created_with_scm = true
                                        unless interface.copy_hooks(path)
                                            RAILS_DEFAULT_LOGGER.warn "Hooks copy failed"
                                        end
                                    else
                                        RAILS_DEFAULT_LOGGER.error "Repository creation failed"
                                    end
                                end
                                if !interface.repository_name_equal?(name, @project.identifier)
                                    flash[:warning] = l(:text_cannot_be_used_redmine_auth)
                                end
                            else
                                @repository.errors.add(:url, :should_be_of_format_local, :format => interface.repository_format)
                            end

                        rescue NameError
                            RAILS_DEFAULT_LOGGER.error "Can't find interface for #{params[:repository_scm]}."
                            @repository.errors.add_to_base(:scm_not_supported)
                        end
                    end
                end

                if @repository.errors.empty?
                    @repository.merge_extra_info(extra) if @repository.respond_to?(:merge_extra_info)
                    @repository.root_url = @repository.url
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
        end

    end

end
