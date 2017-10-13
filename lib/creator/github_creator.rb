class GithubCreator < SCMCreator

    class << self

        def enabled?
            if options && api
                if options['path']
                    if api['token'] || (api['username'] && api['password'])
                        if Object.const_defined?(:Octokit)
                            return true
                        else
                            Rails.logger.warn "Ruby Octokit is not available (required for '#{scm_id}')"
                        end
                    else
                        Rails.logger.warn "missing API credentials (token or username/password) for '#{scm_id}'"
                    end
                else
                    Rails.logger.warn "missing path for '#{scm_id}'"
                end
            end

            false
        end

        def local?
            false
        end

        # fix the name to avoid errors
        def sanitize(attributes)
            if attributes.has_key?('url')
                url = attributes['url']
                if url !~ %r{\A(https://github\.com|git@github\.com)}
                    if url.start_with?(':')
                        url = 'git@github.com' + url
                    elsif url.start_with?('/')
                        url = 'https://github.com' + url
                    elsif url.include?('/')
                        url = 'https://github.com/' + url
                    else
                        url = 'https://github.com/user/' + url
                    end
                end
                if url !~ %r{\.git\z}
                    url << '.git' unless url.end_with?('/')
                end
                attributes['url'] = url unless attributes['url'] == url
            end
            attributes
        end

        # path should be the actual URL at this stage
        def access_url(path, repository = nil)
            if path !~ %r{\A(https://github\.com/|git@github\.com:)} &&
               repository.url =~ %r{\A(https://github\.com/|git@github\.com:)}
                repository.url
            else
                path
            end
        end

        # let Repository::Github override it
        def access_root_url(path, repository = nil)
            nil
        end

        # let Redmine use the repository URL
        def external_url(repository, regexp = %r{\A(?:https?://|git@)})
            repository.url
        end

        # just return the name, as it's remote repository
        def default_path(identifier)
            identifier
        end

        def existing_path(identifier, repository = nil)
            repository.root_url
        end

        def repository_name(path)
            matches = %r{\A(?:.*/)?([^/]+?)(\\.git)?/?\z}.match(path)
            matches ? matches[1] : nil
        end

        def repository_format
            "[https://github.com/<username>/]<#{l(:label_repository_format)}>[.git]"
        end

        # to check if repository exists we need username, which is not always available
        def repository_exists?(identifier)
            false
        end

        def create_repository(path, repository = nil)
            response = client.create(repository_name(path), create_options)
            if response.is_a?(Sawyer::Resource) && response.key?(:clone_url)
                repository.merge_extra_info('extra_created_with_scm' => 1)
                if repository && repository.url =~ %r{\Agit@} && repository.login.blank? && response.key?(:ssh_url)
                    response[:ssh_url]
                else
                    response[:clone_url]
                end
            else
                false
            end
        rescue Octokit::Error => error
            Rails.logger.error error.message
            false
        end

        def can_register_hook?
            return false if api['register_hook'] == 'forbid'
            Setting.sys_api_enabled?
        end

        def register_hook(repository, login = nil, password = nil)
            return false unless can_register_hook?
            if login.present? && password.present?
                registrar = Octokit::Client.new(:login => login, :password => password)
            else
                registrar = client
            end
            github_repository = Octokit::Repository.from_url(repository.url.sub(%r{\.git\z}, ''))
            response = client.create_hook(github_repository, 'redmine', {
                :address                             => "#{Setting.protocol}://#{Setting.host_name}",
                :project                             => repository.project.identifier,
                :api_key                             => Setting.sys_api_key,
                :fetch_commits                       => 1,
                :update_redmine_issues_about_commits => 1
            }, {
                :events => ['push'],
                :active => 1
            })
            Rails.logger.info "Registered hook for: #{repository.url}"
            response.is_a?(Sawyer::Resource)
        rescue Octokit::Error => error
            Rails.logger.error error.message
            false
        end

        def api
            @api ||= options && options['api']
        end

    private

        def client
            @client ||= if api['token']
                Octokit::Client.new(:access_token => api['token'])
            else
                Octokit::Client.new(:login => api['username'], :password => api['password'])
            end
        end

        def create_options
            if options['options'] && options['options'].is_a?(Hash)
                options['options'].symbolize_keys
            else
                {}
            end
        end

    end

end
