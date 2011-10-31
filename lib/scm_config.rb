class ScmConfig

    @@instance = nil
    @@configs = {}

    def self.[](config)
        if @@instance.nil?
            @@instance = new
        end
        @@configs[config]
    end

protected

    def initialize
        file = "#{RAILS_ROOT}/config/scm.yml" # FIXME: support scm.yml in plugin's dir
        if File.file?(file)
            config = YAML::load_file(file)
            if config.is_a?(Hash) && config.has_key?(Rails.env)
                @@configs = config[Rails.env]
            end
        end
    end

end
