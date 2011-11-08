class MercurialCreator < SCMCreator

    class << self

        def enabled?
            options && options['path'] && options['hg'] && File.executable?(options['hg'])
        end

        def url(name, regexp = %r{^(?:https?|ssh)://})
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
                RAILS_DEFAULT_LOGGER.warn "Option 'hgrc' is obsolete - use 'post_create' instead. See: http://projects.andriylesyuk.com/issues/1886."
                if File.exists?(options['hgrc'])
                    args = [ '/bin/cp' ]
                    args << options['hgrc']
                    args << "#{path}/.hg/hgrc"
                    system(*args)
                else
                    RAILS_DEFAULT_LOGGER.error "File #{options['hgrc']} does not exist."
                    false
                end
            else
                true
            end
        end

    end

end
