class ScmConfig

    @@instance = nil
    @@configs = {}

    def self.[](config)
        instantiate
        @@configs[config]
    end

    def self.configured?
        instantiate
        @@configs.any?
    end

protected

    def self.instantiate
        if @@instance.nil?
            @@instance = new
        end
    end

    def initialize
        file = "#{Rails.root}/config/scm.yml"
        if File.file?(file)
            config = YAML::load_file(file)
            if config.is_a?(Hash) && config.has_key?(Rails.env)
                @@configs = config[Rails.env]
            else
                Rails.logger.warn "Invalid configuration file or missing configuration for #{Rails.env}: #{Rails.root}/config/scm.yml"
            end
        else
            Rails.logger.warn "Can't find configuration file: #{Rails.root}/config/scm.yml"
        end
    end

end
