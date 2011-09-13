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
        #    if !@repository
        #        @repository = Repository.factory(params[:repository_scm])
        #        @repository.project = @project if @repository
        #    end
        #    if request.post? && @repository
        #        @repository.attributes = params[:repository]
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
            if !@repository
                @repository = Repository.factory(params[:repository_scm])
                @repository.project = @project if @repository
            end

            if request.post? && @repository
                if params[:operation].present? && params[:operation] == 'add'
                    if params[:repository]

                        if params[:repository_scm] == 'Subversion'
                            svnconf = ScmConfig['svn']
                            path = svnconf['path'].dup
                            path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
                            matches = Regexp.new("^file://#{Regexp.escape(path)}/([^/]+)/?$").match(params[:repository]['url'])
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
                            matches = Regexp.new("^#{Regexp.escape(path)}/([^/]+)/?$").match(params[:repository]['url'])
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
                            # TODO

                        else
                            @repository.errors.add_to_base(:scm_not_supported)
                        end

                    end
                end

                @repository.attributes = params[:repository]
                if @repository.errors.empty?
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
