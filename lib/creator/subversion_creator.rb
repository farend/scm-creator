class SubversionCreator < SCMCreator

    class << self

        def scm_id
            'svn'
        end

        def urlify(path)
            'file://' + (Redmine::Platform.mswin? ? path.gsub(%r{\\}, "/") : path)
        end

        def repository_name(path, options)
            base = Redmine::Platform.mswin? ? options['path'].gsub!(%r{\\}, "/") : options['path']
            matches = Regexp.new("^file://#{Regexp.escape(base)}/([^/]+)/?$").match(path)
            matches ? matches[1] : nil
        end

        def repository_format(options)
            path = Redmine::Platform.mswin? ? options['path'].gsub!(%r{\\}, "/") : options['path']
            "file://#{path}/<#{l(:label_repository_format)}>/"
        end

        def create_repository(path, options)
            args = [ options['svnadmin'], 'create', path ]
            append_options(args, options)
            system(*args)
        end

    end

end
