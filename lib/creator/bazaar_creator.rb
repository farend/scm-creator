class BazaarCreator < SCMCreator

    class << self

        def enabled?
            if options
                if options['path']
                    if !options['bzr'] || File.executable?(options['bzr'])
                        return true
                    else
                        Rails.logger.warn "'#{options['bzr']}' cannot be found/executed - ignoring '#{scm_id}"
                    end
                else
                    Rails.logger.warn "missing path for '#{scm_id}'"
                end
            end

            false
        end

        def external_url(repository, regexp = %r{\A(?:sftp|bzr(?:\+[a-z]+)?)://})
            super
        end

        def create_repository(path, repository = nil)
            args = [ bzr_command, options['init'] || 'init-repository' ]
            append_options(args)
            args << path
            system(*args)
        end

        def init_repository(repository)
            if repository.respond_to?(:log_encoding=)
                repository.log_encoding = options['log_encoding'] || 'UTF-8'
            end
        end

    private

        def bzr_command
            options['bzr'] || Redmine::Scm::Adapters::BazaarAdapter::BZR_BIN
        end

    end

end
