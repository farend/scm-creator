require_dependency 'project'

module ScmProjectPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            safe_attributes 'scm' unless Redmine::VERSION::MAJOR == 1 && Redmine::VERSION::MINOR == 0 # Redmine 1.0.x

            validates_presence_of :scm, :if => Proc.new { |project| project.new_record? && ScmConfig['auto_create'] == 'force' }

            validate :repository_exists

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
            if @scm.present? && ScmConfig['auto_create']
                @repository = Repository.factory(@scm)
                if @repository
                    @repository.project = self

                    begin
                        interface = Object.const_get("#{@scm}Creator")
                        config = ScmConfig[interface.scm_name]
                        path = interface.default_path(self.identifier, config)

                        if File.directory?(path)
                            RAILS_DEFAULT_LOGGER.warn "Automatically using reporitory: #{path}"
                        else
                            RAILS_DEFAULT_LOGGER.info "Automatically creating reporitory: #{path}"
                            if interface.create_repository(path, config)
                                @repository.created_with_scm = true
                                unless interface.copy_hooks(path, config)
                                    RAILS_DEFAULT_LOGGER.warn "Hooks copy failed"
                                end
                            else
                                RAILS_DEFAULT_LOGGER.error "Repository creation failed"
                            end
                        end

                        @repository.root_url = @repository.url = interface.urlify(path)
                        @repository.save

                    rescue NameError
                        RAILS_DEFAULT_LOGGER.error "Can't find interface for #{@scm}."
                    end
                end
            end
        end

        def repository_exists
            if @scm.present? && self.identifier.present? && ScmConfig['auto_create']
                if @scm == 'Subversion'
                    svnconf = ScmConfig['svn']
                    path = Redmine::Platform.mswin? ? "#{svnconf['path']}\\#{self.identifier}" : "#{svnconf['path']}/#{self.identifier}"
                    if File.directory?(path)
                        errors.add_to_base(:repository_exists_for_identifier)
                    end
                elsif @scm == 'Git'
                    gitconf = ScmConfig['git']
                    path = Redmine::Platform.mswin? ? "#{gitconf['path']}\\#{self.identifier}" : "#{gitconf['path']}/#{self.identifier}"
                    if File.directory?(path) || File.directory?("#{path}.git")
                        errors.add_to_base(:repository_exists_for_identifier)
                    end
                end # FIXME: Mercurial??!
            end
        end

    end

end
