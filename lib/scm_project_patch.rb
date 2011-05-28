require_dependency 'project'

module ScmProjectPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            safe_attributes 'scm'

            validates_presence_of :scm, :if => Proc.new { ScmConfig['auto_create'] }

            after_create :create_scm

            def scm=(type)
                @scm = type
            end

            def scm
                @scm
            end
        end
    end

    module ClassMethods
    end

    module InstanceMethods

        def create_scm
            if @scm && ScmConfig['auto_create']
                @repository = Repository.factory(@scm)
                if @repository
                    @repository.project = self

                    if @scm == 'Subversion'
                        svnconf = ScmConfig['svn']
                        path = Redmine::Platform.mswin? ? "#{svnconf['path']}\\#{self.identifier}" : "#{svnconf['path']}/#{self.identifier}"
                        if File.directory?(path)
                            RAILS_DEFAULT_LOGGER.info "Automatically using reporitory: #{path}"
                        else
                            RAILS_DEFAULT_LOGGER.info "Automatically creating SVN reporitory: #{path}"
                            system(svnconf['svnadmin'], 'create', path)
                            @repository.created_with_scm = true
                        end
                        path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
                        @repository.url = "file://#{path}"

                    elsif @scm == 'Git'
                        gitconf = ScmConfig['git']
                        path = Redmine::Platform.mswin? ? "#{gitconf['path']}\\#{self.identifier}" : "#{gitconf['path']}/#{self.identifier}"
                        if File.directory?(path)
                            RAILS_DEFAULT_LOGGER.info "Automatically using reporitory: #{path}"
                        else
                            RAILS_DEFAULT_LOGGER.info "Automatically creating Git reporitory: #{path}"
                            system(gitconf['git'], 'init', '--bare', path)
                            @repository.created_with_scm = true
                        end
                        @repository.url = path
                    end

                    @repository.root_url = @repository.url
                    @repository.save
                end
            end
        end

    end

end
