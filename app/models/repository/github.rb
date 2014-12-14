require_dependency File.expand_path('../../../../lib/adapters/github_adapter', __FILE__)

class Repository::Github < Repository::Git
    validates_format_of :url, :with => %r{\A(https://github\.com/|git@github\.com:)[a-z0-9\-_]+/[a-z0-9\-_]+\.git\z}i, :allow_blank => true

    before_save :set_local_url
    before_save :register_hook

    def self.human_attribute_name(attribute, *args)
        attribute_name = attribute.to_s
        if attribute_name == 'url'
            attribute_name = 'github_url'
        end
        super(attribute_name, *args)
    end

    def self.scm_adapter_class
        Redmine::Scm::Adapters::GithubAdapter
    end

    def self.scm_name
        'Github'
    end

    def self.scm_available
        super && GithubCreator.options && GithubCreator.options['path']
    end

    def extra_created_with_scm
        extra_boolean_attribute('extra_created_with_scm')
    end

    def extra_register_hook
        if new_record? && (extra_info.nil? || extra_info['extra_register_hook'].nil?)
            default_value = GithubCreator.api['register_hook']
            return true if default_value == 'force'
            if default_value.is_a?(TrueClass) || default_value.is_a?(FalseClass)
                return default_value
            end
        end
        extra_boolean_attribute('extra_register_hook')
    end

    def extra_hook_registered
        extra_boolean_attribute('extra_hook_registered')
    end

    def extra_report_last_commit
        true
    end

    def fetch_changesets
        if File.directory?(GithubCreator.options['path'])
            scm_brs = branches
            if scm_brs.blank?
                path = File.dirname(root_url)
                Dir.mkdir(path) unless File.directory?(path)
                Rails.logger.info "Cloning #{url} to #{root_url}"
                scm.clone
            elsif File.directory?(root_url)
                Rails.logger.info "Fetching updates for #{root_url}"
                scm.fetch
            end
        end
        super
    end

    def clear_extra_info_of_changesets
    end

protected

    def extra_boolean_attribute(name)
        return false if extra_info.nil?
        value = extra_info[name]
        return false if value.nil?
        value.to_s != '0'
    end

    def set_local_url
        if new_record? && url.present? && root_url.blank? && GithubCreator.options && GithubCreator.options['path']
            path = url.sub(%r{\A.*[@/]github.com[:/]}, '')
            if Redmine::Platform.mswin?
                self.root_url = "#{GithubCreator.options['path']}\\#{path.gsub(%r{/}, '\\')}"
            else
                self.root_url = "#{GithubCreator.options['path']}/#{path}"
            end
        end
    end

    def register_hook
        return if extra_hook_registered
        if (new_record? && GithubCreator.api['register_hook'] == 'force') || extra_register_hook
            if extra_created_with_scm
                result = GithubCreator.register_hook(self)
            else
                result = GithubCreator.register_hook(self, login, password)
            end
            if result
                self.merge_extra_info('extra_hook_registered' => 1)
                self.merge_extra_info('extra_register_hook'   => 1) unless extra_register_hook
            else
                self.merge_extra_info('extra_register_hook' => 0)
            end
        end
    end

end
