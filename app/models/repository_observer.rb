class RepositoryObserver < ActiveRecord::Observer

    def before_destroy(repository) # FIXME: does not get executed
        Rails.logger.info "#2017: before_destroy" # FIXME
        if repository.created_with_scm
            project = repository.project

            type = repository.type
            type.gsub!(%r{^Repository::}, '')

            Rails.logger.info "#2017: repository.created_with_scm" # FIXME
            begin
                interface = Object.const_get("#{type}Creator")

                name = interface.repository_name(repository.root_url)
                if name
                    path = interface.path(name)

                    interface.execute(ScmConfig['pre_delete'], path, project) if ScmConfig['pre_delete']

                    Rails.logger.info "#2017: #{path}" # FIXME
                    FileUtils.remove_entry_secure(path, true) # FIXME: make a note http://www.ruby-doc.org/stdlib-1.9.3/libdoc/fileutils/rdoc/FileUtils.html#method-c-remove_entry_secure

                    interface.execute(ScmConfig['post_delete'], path, project) if ScmConfig['post_delete']

                end
            rescue NameError
            end

        end
    end

end
