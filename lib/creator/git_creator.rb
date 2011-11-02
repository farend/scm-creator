class GitCreator < SCMCreator

    class << self

        def default_path(identifier, options)
            if options['git_ext']
                super + '.git'
            else
                super
            end
        end

        def repository_name_equal?(name, identifier)
            name == identifier || name == "#{identifier}.git"
        end

        def repository_exists?(identifier, options)
            path = default_path(identifier, options.reject{ |option, value| option == 'git_ext' })
            File.directory?(path) || File.directory?("#{path}.git")
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
