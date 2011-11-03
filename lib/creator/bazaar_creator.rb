class BazaarCreator < SCMCreator

    class << self

        def url(name, regexp = %r{^(?:sftp|bzr(?:\+[a-z]+)?)://})
            super
        end

        def copy_hooks(path)
        end

        def create_repository(path)
            args = [ options['bzr'], 'init-repository' ]
            append_options(args)
            args << path
            system(*args)
        end

    end

end
