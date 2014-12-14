class GitCreator < SCMCreator

    class << self

        def enabled?
            if options
                if options['path']
                    if !options['git'] || File.executable?(options['git'])
                        return true
                    else
                        Rails.logger.warn "'#{options['git']}' cannot be found/executed - ignoring '#{scm_id}"
                    end
                else
                    Rails.logger.warn "missing path for '#{scm_id}'"
                end
            end

            false
        end

        def external_url(repository, regexp = %r{\A(?:https?|git|ssh)://})
            url = super
            if url.present? && repository.root_url =~ %r{\.git\z}
                url + '.git'
            else
                url
            end
        end

        def default_path(identifier)
            if options['git_ext']
                path(identifier) + '.git'
            else
                path(identifier)
            end
        end

        def existing_path(identifier, repository = nil)
            path = path(identifier)
            if File.directory?("#{path}.git")
                path + '.git'
            elsif File.directory?(path)
                path
            else
                false
            end
        end

        def repository_name(path)
            base = Redmine::Platform.mswin? ? options['path'].gsub(%r{\\}, "/") : options['path']
            matches = Regexp.new("\A#{Regexp.escape(base)}/([^/]+?)(\\.git)?/?\z").match(path)
            matches ? matches[1] : nil
        end

        def repository_exists?(identifier)
            path = path(identifier)
            File.directory?(path) || File.directory?("#{path}.git")
        end

        def create_repository(path, repository = nil)
            args = [ git_command, 'init' ]
            append_options(args)
            args << path
            if system(*args)
                if options['update_server_info']
                    Dir.chdir(path) do
                        system(git_command, 'update-server-info')
                    end
                end
                true
            else
                false
            end
        end

    private

        def git_command
            options['git'] || Redmine::Scm::Adapters::GitAdapter::GIT_BIN
        end

    end

end
