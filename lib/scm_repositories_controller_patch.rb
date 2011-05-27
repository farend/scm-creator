require_dependency 'repositories_controller'

module ScmRepositoriesControllerPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            before_filter :delete_scm, :only => :destroy
            alias_method_chain :edit, :add # FIXME: just alias_method?
        end
    end

    module ClassMethods
    end

    module InstanceMethods

        def delete_scm # TODO
            RAILS_DEFAULT_LOGGER.info " ***> DELETE_SCM"
            #render_403
        end

        # NOTE: is a copy of RepositoriesController::edit
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
                            svnconf = SvnConfig['svn']
                            path = svnconf['path'].dup
                            path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
                            matches = Regexp.new("^file://#{Regexp.escape(path)}/([^/]+)/?$").match(params[:repository]['url'])
                            if matches
                                repath = Redmine::Platform.mswin? ? "#{svnconf['path']}\\#{matches[1]}" : "#{svnconf['path']}/#{matches[1]}"
                                if File.directory?(repath)
                                    @repository.errors.add(:url, :already_exists)
                                else
                                    system(svnconf['svnadmin'], 'create', repath)
                                end
                            else
                                @repository.errors.add(:url, :should_be_of_format_local, :format => "file://#{path}/<#{l(:label_repository_format)}>/")
                            end
                        elsif params[:repository_scm] == 'Git'
                            gitconf = SvnConfig['git']
                            path = gitconf['path'].dup
                            path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
                            matches = Regexp.new("^#{Regexp.escape(path)}/([^/]+)/?$").match(params[:repository]['url'])
                            if matches
                                repath = Redmine::Platform.mswin? ? "#{gitconf['path']}\\#{matches[1]}" : "#{gitconf['path']}/#{matches[1]}"
                                if File.directory?(repath)
                                    @repository.errors.add(:url, :already_exists)
                                else
                                    # TODO: test + separate
                                    #if Redmine::Platform.mswin?
                                    #    system("mkdir #{matches}& #{gitconf['git']} init --bare #{matches}& XCACLS #{matches} /G #{gitconf['owner']}:F /y ")
                                    #else
                                    #    system("mkdir #{matches}; #{gitconf['git']} init --bare #{matches}; chown -R #{gitconf['owner']} #{matches}")
                                    #end
                                end
                            else
                                @repository.errors.add(:url, :should_be_of_format_local, :format => "file://#{path}/<#{l(:label_repository_format)}>/") # FIXME: file://?
                            end
                        else
                            # TODO: @repository.errors.add(:url, :scm_not_supported)
                        end
                    end
                end
                @repository.attributes = params[:repository]
                if @repository.errors.empty?
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
