class RepositoryObserver < ActiveRecord::Observer

    def before_destroy(repository)
        if repository.created_with_scm
            project = repository.project

            begin
                interface = Object.const_get("#{repository.type}Creator")

                name = interface.repository_name(repository.root_url)
                if name
                    path = interface.path(name)

                    interface.execute(ScmConfig['pre_delete'], path, project) if ScmConfig['pre_delete']

                    FileUtils.remove_entry_secure(path, true)

                    interface.execute(ScmConfig['post_delete'], path, project) if ScmConfig['post_delete']

                end
            rescue NameError
            end

        end
    end

end
