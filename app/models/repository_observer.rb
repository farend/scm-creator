class RepositoryObserver < ActiveRecord::Observer

    def before_destroy(repository)
        if repository.created_with_scm
            project = repository.project

            if ScmConfig['pre_delete'] && File.executable?(ScmConfig['pre_delete']) # FIXME: test
                interface.execute(ScmConfig['pre_delete'], path, project)
            end

            case repository.type # FIXME: should not it be converted for Windows? + Use *Creator?
            when 'Subversion'
                FileUtils.remove_entry_secure(repository.url.gsub(%r{^file:\/\/}, ''), true) if repository.url =~ %r{^file:\/\/}
            when 'Git', 'Mercurial'
                FileUtils.remove_entry_secure(repository.url, true) if repository.url =~ %r{^\.*\/}
            end

            if ScmConfig['post_delete'] && File.executable?(ScmConfig['post_delete']) # FIXME: test
                interface.execute(ScmConfig['post_delete'], path, project)
            end
        end
    end

end
