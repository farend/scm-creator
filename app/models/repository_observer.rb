class RepositoryObserver < ActiveRecord::Observer

    def before_destroy(repository)
        if repository.created_with_scm
            case repository.type
            when 'Subversion'
                FileUtils.remove_entry_secure(repository.url.gsub(%r{^file:\/\/}, ''), true) if repository.url =~ %r{^file:\/\/}
            when 'Git', 'Mercurial'
                FileUtils.remove_entry_secure(repository.url, true) if repository.url =~ %r{^\.*\/}
            end
        end
    end

end
