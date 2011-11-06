class BazaarCreator < SCMCreator

    class << self

        def url(name, regexp = %r{^(?:sftp|bzr(?:\+[a-z]+)?)://})
            super
        end

        def copy_hooks(path)
            true
        end

        def create_repository(path)
            args = [ options['bzr'], 'init-repository' ]
            append_options(args)
            args << path
            system(*args)
        end

        def init_repository(repository)
            repository.log_encoding = 'UTF-8'
        end

    end

end
