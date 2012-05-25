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
        file = "#{RAILS_ROOT}/config/scm.yml"
        if File.file?(file)
            config = YAML::load_file(file)
            if config.is_a?(Hash) && config.has_key?(Rails.env)
                @@configs = config[Rails.env]
            else
                Rails.logger.warn "Invalid configuration file or missing configuration for #{Rails.env}: #{RAILS_ROOT}/config/scm.yml"
            end
        else
            Rails.logger.warn "Can't find configuration file: #{RAILS_ROOT}/config/scm.yml"
        end
    end

end
