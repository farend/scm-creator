class GitCreator < SCMCreator

    class << self

        def enabled?
            if options
                if options['path']
                    if options['git']
                        if File.executable?(options['git'])
                            return true
                        else
                            Rails.logger.warn "'#{options['git']}' cannot be found/executed - ignoring '#{scm_id}"
                        end
                    else
                        Rails.logger.warn "missing path to the 'git' tool for '#{scm_id}'"
                    end
                else
                    Rails.logger.warn "missing path for '#{scm_id}'"
                end
            end

            false
        end

        def external_url(name, regexp = %r{^(?:https?|git|ssh)://})
            super
        end

        def default_path(identifier)
            if options['git_ext']
                path(identifier) + '.git'
            else
                path(identifier)
            end
        end

        def repository_name_equal?(name, identifier)
            name == identifier || name == "#{identifier}.git"
        end

        def repository_exists?(identifier)
            path = path(identifier)
            File.directory?(path) || File.directory?("#{path}.git")
        end

        def create_repository(path)
            args = [ options['git'], 'init' ]
            append_options(args)
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
