require_dependency File.expand_path('../../../../lib/adapters/github_adapter', __FILE__)

class Repository::Github < Repository::Git
    validates_format_of :url, :with => %r{^(https://github\.com/|git@github\.com:)?([a-z0-9\-]+/)?[a-z0-9\-]+(\.git/?)?$}i, :allow_blank => true

    # TODO validate :repo_create_validation, :on => :create

    before_save :set_local_url

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

    def extra_register_hook
        return false if extra_info.nil?
        value = extra_info['extra_report_last_commit']
        return false if value.nil?
        value.to_s != '0'
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

    def set_local_url
        if new_record? && url.present? && root_url.blank? && GithubCreator.options && GithubCreator.options['path']
            # TODO if Redmine::Platform.mswin?
            self.root_url = GithubCreator.options['path'] + '/' + url.gsub(%r{^.*[@/]github.com[:/]}, '')
        end
    end

end
