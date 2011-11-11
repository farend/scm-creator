class SubversionCreator < SCMCreator

    class << self

        def scm_id
            'svn'
        end

        def enabled?
            options && options['path'] && options['svnadmin'] && File.executable?(options['svnadmin'])
        end

        def access_url(path)
            if options['append']
                access_root_url(path) + '/' + options['append']
            else
                access_root_url(path)
            end
        end

        def access_root_url(path)
            'file://' + (Redmine::Platform.mswin? ? path.gsub(%r{\\}, "/") : path)
        end

        def external_url(name, regexp = %r{^(?:file|https?|svn(?:\+[a-z]+)?)://})
            super
        end

        def repository_name(path)
            base = Redmine::Platform.mswin? ? options['path'].gsub!(%r{\\}, "/") : options['path']
            matches = Regexp.new("^file://#{Regexp.escape(base)}/([^/]+)/?$").match(path)
            matches ? matches[1] : nil
        end

        def repository_format
            path = Redmine::Platform.mswin? ? options['path'].gsub!(%r{\\}, "/") : options['path']
            "file://#{path}/<#{l(:label_repository_format)}>/"
        end

        def create_repository(path)
            args = [ options['svnadmin'], 'create', path ]
            append_options(args)
            system(*args)
        end

    end

end