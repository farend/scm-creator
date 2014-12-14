class SCMCreator
    include Redmine::I18n

    class << self

        # factory-like method that determines the actual creator
        def interface(repository)
            if repository.is_a?(Repository)
                type = repository.class.name
            elsif repository.is_a?(Class)
                type = repository.name
            else
                type = repository.to_s
            end
            Object.const_get("#{type.demodulize}Creator")
        rescue NameError
            nil
        end

        # returns config id used in scm.yml and ScmConfig
        def scm_id
            if self.name =~ %r{\A(.+)Creator\z}
                $1.downcase
            else
                nil
            end
        end

        # returns true if SCM is enabled
        def enabled?
            false
        end

        # returns true if SCM creates local repository
        def local?
            true
        end

        # returns configuration from scm.yml
        def options
            @options ||= ScmConfig[scm_id]
        end

        # can be used to sanitize attribute values
        def sanitize(attributes)
            attributes
        end

        # returns local path used to access repository locally (with optional /.git/ etc)
        def access_url(path, repository = nil)
            if options['append']
                if Redmine::Platform.mswin?
                    "#{access_root_url(path, repository)}\\#{options['append']}"
                else
                    "#{access_root_url(path, repository)}/#{options['append']}"
                end
            else
                access_root_url(path, repository)
            end
        end

        # returns local path used to access repository locally
        def access_root_url(path, repository = nil)
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

        # returns url which can be used to access the repository externally
        def external_url(repository, regexp = %r{\Ahttps?://})
            if options['url'] && name = repository_name(repository.root_url)
                if options['url'] =~ regexp
                    url = "#{options['url']}/#{name}"
                else
                    url = "#{Setting.protocol}://#{Setting.host_name}/#{options['url']}/#{name}"
                end
            else
                nil
            end
        end

        # constructs default path using project identifier
        def default_path(identifier)
            path(identifier)
        end

        # get path of existing repository
        def existing_path(identifier, repository = nil)
            if File.directory?(default_path(identifier))
                default_path(identifier)
            else
                nil
            end
        end

        # extracts repository name from path
        def repository_name(path)
            base = Redmine::Platform.mswin? ? options['path'].gsub(%r{\\}, "/") : options['path']
            matches = Regexp.new("\A#{Regexp.escape(base)}/([^/]+)/?\z").match(path)
            matches ? matches[1] : nil
        end

        # compares repository names (was created for multiple repositories support)
        def belongs_to_project?(name, identifier)
            name =~ %r{\A#{Regexp.escape(identifier)}(\..+)?\z}
        end

        # returns format of repository path which is displayed in the form as a default value
        def repository_format
            path = Redmine::Platform.mswin? ? options['path'].gsub(%r{\\}, "/") : options['path']
            "#{path}/<#{l(:label_repository_format)}>/"
        end

        # checks if repository already exists (was created for Git which can add .git extension)
        def repository_exists?(identifier)
            File.directory?(default_path(identifier))
        end

        # creates repository
        def create_repository(path, repository = nil)
            false
        end

        # removes repository
        def delete_repository(path)
            # See: http://www.ruby-doc.org/stdlib-1.9.3/libdoc/fileutils/rdoc/FileUtils.html#method-c-remove_entry_secure
            FileUtils.remove_entry_secure(path, true)
        end

        # executes custom scripts
        def execute(script, path, project)
            if File.executable?(script)
                project.custom_field_values.each do |custom_value|
                    name = custom_value.custom_field.name.gsub(%r{[^a-z0-9]+}i, '_').upcase
                    ENV["SCM_CUSTOM_FIELD_#{name}"] = custom_value.value unless name.empty?
                end
                system(script, path, scm_id, project.identifier)
            else
                Rails.logger.warn "cannot find/execute: #{script}"
            end
        end

        # initializes required properties of repository (used for Bazaar which requires log_encoding)
        def init_repository(repository)
        end

    private

        def append_options(args)
            if options['options']
                if options['options'].is_a?(Array)
                    args.concat(options['options'])
                else
                    args.push(options['options'])
                end
            end
        end

    end

end
