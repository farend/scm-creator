class BazaarCreator < SCMCreator

    class << self

        def enabled?
            if options
                if options['path']
                    if options['bzr']
                        if File.executable?(options['bzr'])
                            return true
                        else
                            Rails.logger.warn "'#{options['bzr']}' cannot be found/executed - ignoring '#{scm_id}"
                        end
                    else
                        Rails.logger.warn "missing path to the 'bzr' tool for '#{scm_id}'"
                    end
                else
                    Rails.logger.warn "missing path for '#{scm_id}'"
                end
            end

            false
        end

        def external_url(name, regexp = %r{^(?:sftp|bzr(?:\+[a-z]+)?)://})
            super
        end

        def copy_hooks(path)
            true
        end

        def create_repository(path)
            args = [ options['bzr'], options['init'] || 'init-repository' ]
            append_options(args)
            args << path
            system(*args)
        end

        def init_repository(repository)
            if repository.respond_to?(:log_encoding=)
                repository.log_encoding = options['log_encoding'] || 'UTF-8'
            end
        end

    end

end
