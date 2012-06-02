require_dependency 'project'

module ScmProjectPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            safe_attributes 'scm' unless Redmine::VERSION::MAJOR == 1 && Redmine::VERSION::MINOR == 0 # Redmine 1.0.x

            validates_presence_of :scm, :if => Proc.new { |project| project.new_record? && project.module_enabled?(:repository) && ScmConfig['auto_create'] == 'force' }

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
            if @scm.present? && self.module_enabled?(:repository) && ScmConfig['auto_create']
                @repository = Repository.factory(@scm)
                if @repository
                    @repository.project = self

                    begin
                        interface = Object.const_get("#{@scm}Creator")
                        path = interface.default_path(self.identifier)

                        if File.directory?(path)
                            Rails.logger.warn "Automatically using reporitory: #{path}"
                        else
                            Rails.logger.info "Automatically creating reporitory: #{path}"
                            interface.execute(ScmConfig['pre_create'], path, self) if ScmConfig['pre_create']
                            if interface.create_repository(path)
                                interface.execute(ScmConfig['post_create'], path, self) if ScmConfig['post_create']
                                @repository.created_with_scm = true
                                unless interface.copy_hooks(path)
                                    Rails.logger.warn "Hooks copy failed"
                                end
                            else
                                Rails.logger.error "Repository creation failed"
                            end
                        end

                        interface.init_repository(@repository) if @repository.new_record?
                        @repository.root_url = interface.access_root_url(path)
                        @repository.url = interface.access_url(path)
                        @repository.save

                    rescue NameError
                        Rails.logger.error "Can't find interface for #{@scm}."
                    end
                end
            end
        end

        def repository_exists
            if @scm.present? && self.identifier.present? && self.module_enabled?(:repository) && ScmConfig['auto_create']
                begin
                    interface = Object.const_get("#{@scm}Creator")
                    if interface.repository_exists?(self.identifier)
                        errors.add(:base, :repository_exists_for_identifier)
                    end
                rescue NameError
                    Rails.logger.error "Can't find interface for #{@scm}."
                end
            end
        end

    end

end
