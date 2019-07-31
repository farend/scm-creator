require_dependency 'repository'

module ScmRepositoryPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            before_destroy :remove_repository_files
        end
    end

    module InstanceMethods

        def remove_repository_files
            if created_with_scm
                interface = SCMCreator.interface(self)
                if interface
                    name = interface.repository_name(root_url)
                    if name
                        path = interface.existing_path(name, self)
                        if path
                            interface.execute(ScmConfig['pre_delete'], path, project) if ScmConfig['pre_delete']
                            unless interface.delete_repository(path)
                                throw(:abort)
                            end
                            interface.execute(ScmConfig['post_delete'], path, project) if ScmConfig['post_delete']
                        end
                    end
                end
            end
        end

    end

end
