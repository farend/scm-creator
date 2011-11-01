class GitCreator < SCMCreator

    class << self

        def default_path(identifier, options)
            if options['git_ext']
                super + '.git'
            else
                super
            end
        end

        def create_repository(path, options)
            args = [ options['git'], 'init' ]
            append_options(args, options)
            args << path
            if system(*args)
                if options['update_server_info']
                    Dir.chdir(path) do
                        system(options['git'], 'update-server-info')
                    end
                end
                true
            else
                false
            end
        end

    end

end
