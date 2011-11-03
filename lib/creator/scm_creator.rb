class SCMCreator

    class << self

        # returns config id used in scm.yml and ScmConfig
        def scm_id
            if self.name =~ %r{^(.+)Creator$}
                $1.downcase
            else
                nil
            end
        end

        # returns configuration from scm.yml
        def options
            @options ||= ScmConfig[scm_id]
        end

        # returns local path used to access repository locally
        def command_line_path(path)
            path
        end

        # returns local path
        def path(identifier)
            if Redmine::Platform.mswin?
                # Assuming path is in Windows style (contains \'s)
                "#{options['path']}\\#{identifier}"
            else
                "#{options['path']}/#{identifier}"
            end
        end

        # returns url which can used to access the repository externally
        def url(name, regexp = %r{^https?://})
            if options['url'] =~ regexp
                url = "#{options['url']}/#{name}"
            else
                url = "#{Setting.protocol}://#{Setting.host_name}/#{options['url']}/#{name}"
            end
        end

        # constructs default path using project identifier
        def default_path(identifier)
            path(identifier)
        end

        # extracts repository name from path
        def repository_name(path)
            base = Redmine::Platform.mswin? ? options['path'].gsub!(%r{\\}, "/") : options['path']
            matches = Regexp.new("^#{Regexp.escape(base)}/([^/]+)/?$").match(path)
            matches ? matches[1] : nil
        end

        # compares repository names (was created for Git which can add .git extension)
        def repository_name_equal?(name, identifier)
            name == identifier
        end

        # returns format of repository path which is displayed in the form as a default value
        def repository_format
            path = Redmine::Platform.mswin? ? options['path'].gsub!(%r{\\}, "/") : options['path']
            "#{path}/<#{l(:label_repository_format)}>/"
        end

        # checks if repository already exists (was created for Git which can add .git extension)
        def repository_exists?(identifier)
            File.directory?(default_path(identifier))
        end

        # creates repository
        def create_repository(path)
            false
        end

        # copies hooks (obsolete)
        def copy_hooks(path)
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

        def append_options(args)
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
