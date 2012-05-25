class MercurialCreator < SCMCreator

    class << self

        def enabled?
            if options
                if options['path']
                    if options['hg']
                        if File.executable?(options['hg'])
                            return true
                        else
                            Rails.logger.warn "'#{options['hg']}' cannot be found/executed - ignoring '#{scm_id}"
                        end
                    else
                        Rails.logger.warn "missing path to the 'hg' tool for '#{scm_id}'"
                    end
                else
                    Rails.logger.warn "missing path for '#{scm_id}'"
                end
            end

            false
        end

        def external_url(name, regexp = %r{^(?:https?|ssh)://})
            super
        end

        def create_repository(path)
            args = [ options['hg'], 'init' ]
            append_options(args)
            args << path
            system(*args)
        end

        def copy_hooks(path)
            if options['hgrc']
                Rails.logger.warn "Option 'hgrc' is obsolete - use 'post_create' instead. See: http://projects.andriylesyuk.com/issues/1886."
                if File.exists?(options['hgrc'])
                    args = [ '/bin/cp' ]
                    args << options['hgrc']
                    args << "#{path}/.hg/hgrc"
                    system(*args)
                else
                    Rails.logger.error "File #{options['hgrc']} does not exist."
                    false
                end
            else
                true
            end
        end

    end

end
