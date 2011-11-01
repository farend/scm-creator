class SCMCreator

    class << self

        def scm_name
            if self.name =~ %r{^(.+)Creator$}
                $1.downcase
            else
                nil
            end
        end

        def urlify(path)
            path
        end

        def default_path(identifier, options)
            if Redmine::Platform.mswin?
                # Assuming path is in Windows style (contains \'s)
                "#{options['path']}\\#{identifier}"
            else
                "#{options['path']}/#{identifier}"
            end
        end

        def create_repository(path, options)
            false
        end

        def copy_hooks(path, options)
            if options['hooks']
                RAILS_DEFAULT_LOGGER.warn "Option 'hooks' is obsolete - use 'post_create' instead. See: http://projects.andriylesyuk.com/issues/1886."
                if File.directory?(options['hooks'])
                    args = [ '/bin/cp', '-aR' ]
                    args += Dir.glob("#{options['hooks']}/*")
                    args << "#{path}/hooks/"
                    system(*args)
                else
                    RAILS_DEFAULT_LOGGER.error "Hooks directory #{options['hooks']} does not exist."
                    false
                end
            else
                true
            end
        end

    private

        def append_options(args, options)
            if options['options']
                if options['options'].is_a?(Array)
                    args += options['options']
                else
                    args << options['options']
                end
            end
        end

    end

end
