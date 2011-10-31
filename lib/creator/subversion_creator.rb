class SubversionCreator < SCMCreator

    class << self

        def create_repository(path, options)
            args = [ options['svnadmin'], 'create', path ]
            append_options(args, options)
            system(*args)
        end

    end

end
