class SCMCreator

    class << self

        def default_path(identifier, options)
            if Redmine::Platform.mswin?
                # Assuming path is in Windows style (contains \'s)
                "#{options['path']}\\#{identifier}"
            else
                "#{options['path']}/#{identifier}"
            end
        end

        def create_repository(path, options)
            # TODO: raise
        end

        def copy_hooks(path, options)
            if options['hooks']
                RAILS_DEFAULT_LOGGER.warn "Option 'hooks' is obsolete - use 'post_create' instead." # TODO: add issue
                if File.directory?(options['hooks'])
                    args = [ '/bin/cp', '-aR' ]
                    args += Dir.glob("#{options['hooks']}/*")
                    args << "#{path}/hooks/"
                    system(*args)
                else
                    # TODO
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
