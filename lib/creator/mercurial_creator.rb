class MercurialCreator < SCMCreator

    class << self

        def enabled?
            if options
                if options['path']
                    if !options['hg'] || File.executable?(options['hg'])
                        return true
                    else
                        Rails.logger.warn "'#{options['hg']}' cannot be found/executed - ignoring '#{scm_id}"
                    end
                else
                    Rails.logger.warn "missing path for '#{scm_id}'"
                end
            end

            false
        end

        def external_url(repository, regexp = %r{\A(?:https?|ssh)://})
            super
        end

        def create_repository(path, repository = nil)
            args = [ hg_command, 'init' ]
            append_options(args)
            args << path
            system(*args)
        end

    private

        def hg_command
            options['hg'] || Redmine::Scm::Adapters::MercurialAdapter::HG_BIN
        end

    end

end
