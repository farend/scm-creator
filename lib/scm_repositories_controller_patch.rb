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

                if params[:operation].present? && params[:operation] == 'add'
                    if attrs

                        if params[:repository_scm] == 'Subversion'
                            svnconf = ScmConfig['svn']
                            path = svnconf['path'].dup
                            path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
                            matches = Regexp.new("^file://#{Regexp.escape(path)}/([^/]+)/?$").match(attrs['url'])
                            if matches
                                repath = Redmine::Platform.mswin? ? "#{svnconf['path']}\\#{matches[1]}" : "#{svnconf['path']}/#{matches[1]}"
                                if File.directory?(repath)
                                    @repository.errors.add(:url, :already_exists)
                                else
                                    RAILS_DEFAULT_LOGGER.info "Creating SVN reporitory: #{repath}"
                                    args = [ svnconf['svnadmin'], 'create', repath ]
                                    if svnconf['options']
                                        if svnconf['options'].is_a?(Array)
                                            args += svnconf['options']
                                        else
                                            args << svnconf['options']
                                        end
                                    end
                                    if system(*args)
                                        @repository.created_with_scm = true
                                        if svnconf['hooks'] && File.directory?(svnconf['hooks'])
                                            args = [ '/bin/cp', '-aR' ]
                                            args += Dir.glob("#{svnconf['hooks']}/*")
                                            args << "#{repath}/hooks/"
                                            unless system(*args)
                                                RAILS_DEFAULT_LOGGER.warn "Hooks copy failed"
                                            end
                                        end
                                    else
                                        RAILS_DEFAULT_LOGGER.error "Repository creation failed"
                                    end
                                end
                                if matches[1] != @project.identifier
                                    flash[:warning] = l(:text_cannot_be_used_redmine_auth)
                                end
                            else
                                @repository.errors.add(:url, :should_be_of_format_local, :format => "file://#{path}/<#{l(:label_repository_format)}>/")
                            end

                        elsif params[:repository_scm] == 'Git'
                            gitconf = ScmConfig['git']
                            path = gitconf['path'].dup
                            path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
                            matches = Regexp.new("^#{Regexp.escape(path)}/([^/]+)/?$").match(attrs['url'])
                            if matches
                                repath = Redmine::Platform.mswin? ? "#{gitconf['path']}\\#{matches[1]}" : "#{gitconf['path']}/#{matches[1]}"
                                if File.directory?(repath)
                                    @repository.errors.add(:url, :already_exists)
                                else
                                    RAILS_DEFAULT_LOGGER.info "Creating Git reporitory: #{repath}"
                                    args = [ gitconf['git'], 'init' ]
                                    if gitconf['options']
                                        if gitconf['options'].is_a?(Array)
                                            args += gitconf['options']
                                        else
                                            args << gitconf['options']
                                        end
                                    end
                                    args << repath
                                    if system(*args)
                                        @repository.created_with_scm = true
                                        if gitconf['update_server_info']
                                            Dir.chdir(repath) do
                                                system(gitconf['git'], 'update-server-info')
                                            end
                                        end
                                        if gitconf['hooks'] && File.directory?(gitconf['hooks'])
                                            args = [ '/bin/cp', '-aR' ]
                                            args += Dir.glob("#{gitconf['hooks']}/*")
                                            args << "#{repath}/hooks/"
                                            unless system(*args)
                                                RAILS_DEFAULT_LOGGER.warn "Hooks copy failed"
                                            end
                                        end
                                    else
                                        RAILS_DEFAULT_LOGGER.error "Repository creation failed"
                                    end
                                end
                                if matches[1] != @project.identifier && matches[1] != "#{@project.identifier}.git"
                                    flash[:warning] = l(:text_cannot_be_used_redmine_auth)
                                end
                            else
                                @repository.errors.add(:url, :should_be_of_format_local, :format => "#{path}/<#{l(:label_repository_format)}>/")
                            end

                        elsif params[:repository_scm] == 'Mercurial'
                            hgconf = ScmConfig['mercurial']
                            path = hgconf['path'].dup
                            path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
                            matches = Regexp.new("^#{Regexp.escape(path)}/([^/]+)/?$").match(attrs['url'])
                            if matches
                                repath = Redmine::Platform.mswin? ? "#{hgconf['path']}\\#{matches[1]}" : "#{hgconf['path']}/#{matches[1]}"
                                if File.directory?(repath)
                                    @repository.errors.add(:url, :already_exists)
                                else
                                    RAILS_DEFAULT_LOGGER.info "Creating Mercurial reporitory: #{repath}"
                                    args = [ hgconf['hg'], 'init' ]
                                    if hgconf['options']
                                        if hgconf['options'].is_a?(Array)
                                            args += hgconf['options']
                                        else
                                            args << hgconf['options']
                                        end
                                    end
                                    args << repath
                                    if system(*args)
                                        @repository.created_with_scm = true
                                        if hgconf['hgrc'] && File.exists?(hgconf['hgrc'])
                                            args = [ '/bin/cp' ]
                                            args << hgconf['hgrc']
                                            args << "#{repath}/.hg/hgrc"
                                            unless system(*args)
                                                RAILS_DEFAULT_LOGGER.warn "File hgrc copy failed"
                                            end
                                        end
                                    else
                                        RAILS_DEFAULT_LOGGER.error "Repository creation failed"
                                    end
                                end
                                if matches[1] != @project.identifier
                                    flash[:warning] = l(:text_cannot_be_used_redmine_auth)
                                end
                            else
                                @repository.errors.add(:url, :should_be_of_format_local, :format => "#{path}/<#{l(:label_repository_format)}>/")
                            end

                        else
                            @repository.errors.add_to_base(:scm_not_supported)
                        end

                    end
                end

                @repository.attributes = attrs
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
