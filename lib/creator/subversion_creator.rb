class SubversionCreator < SCMCreator

    class << self

        def scm_name
            'svn'
        end

        def urlify(path)
            'file://' + (Redmine::Platform.mswin? ? path.gsub(%r{\\}, "/") : path)
        end

        def create_repository(path, options)
            args = [ options['svnadmin'], 'create', path ]
            append_options(args, options)
            system(*args)
        end

    end

end
