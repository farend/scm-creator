class BazaarCreator < SCMCreator

    class << self

        def enabled?
            options && options['path'] && options['bzr'] && File.executable?(options['bzr'])
        end

        def url(name, regexp = %r{^(?:sftp|bzr(?:\+[a-z]+)?)://})
            super
        end

        def copy_hooks(path)
            true
        end

        def create_repository(path)
            args = [ options['bzr'], options['init'] || 'init-repository' ]
            append_options(args)
            args << path
            system(*args)
        end

        def init_repository(repository)
            if repository.respond_to?(:log_encoding=)
                repository.log_encoding = options['log_encoding'] || 'UTF-8'
            end
        end

    end

end
