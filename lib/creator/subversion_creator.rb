class SubversionCreator < SCMCreator

    class << self

        def scm_id
            'svn'
        end

        def enabled?
            if options
                if options['path']
                    if options['svnadmin']
                        if File.executable?(options['svnadmin'])
                            return true
                        else
                            Rails.logger.warn "'#{options['svnadmin']}' cannot be found/executed - ignoring '#{scm_id}"
                        end
                    else
                        Rails.logger.warn "missing path to the 'svnadmin' tool for '#{scm_id}'"
                    end
                else
                    Rails.logger.warn "missing path for '#{scm_id}'"
                end
            end

            false
        end

        def access_url(path)
            if options['append']
                access_root_url(path) + '/' + options['append']
            else
                access_root_url(path)
            end
        end

        def access_root_url(path)
            'file://' + (Redmine::Platform.mswin? ? '/' + path.gsub(%r{\\}, "/") : path)
        end

        def external_url(name, regexp = %r{^(?:file|https?|svn(?:\+[a-z]+)?)://})
            super
        end

        def repository_name(path)
            base = Redmine::Platform.mswin? ? '/' + options['path'].gsub(%r{\\}, "/") : options['path']
            matches = Regexp.new("^file://#{Regexp.escape(base)}/([^/]+)/?$").match(path)
            matches ? matches[1] : nil
        end

        def repository_format
            path = Redmine::Platform.mswin? ? '/' + options['path'].gsub(%r{\\}, "/") : options['path']
            "file://#{path}/<#{l(:label_repository_format)}>/"
        end

        def create_repository(path)
            args = [ options['svnadmin'], 'create', path ]
            append_options(args)
            system(*args)
        end

    end

end
