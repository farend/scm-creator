class RepositoryObserver < ActiveRecord::Observer

    def before_destroy(repository)
        if repository.created_with_scm
            project = repository.project

            begin
                interface = Object.const_get("#{repository.type}Creator")

                name = interface.repository_name(repository.url)
                if name
                    path = interface.path(name)

                    if ScmConfig['pre_delete'] && File.executable?(ScmConfig['pre_delete'])
                        interface.execute(ScmConfig['pre_delete'], path, project)
                    end

                    FileUtils.remove_entry_secure(path, true)

                    if ScmConfig['post_delete'] && File.executable?(ScmConfig['post_delete'])
                        interface.execute(ScmConfig['post_delete'], path, project)
                    end

                end
            rescue NameError
            end

        end
    end

end
