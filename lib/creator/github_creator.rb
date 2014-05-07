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

        # Path should be the actual URL at this stage
        def access_url(path)
            path
        end

        # Let Repository::Github override it
        def access_root_url(path)
            nil
        end

        # Let Redmine use the repository URL
        def external_url(repository, regexp = %r{^(?:https?://|git@)})
            repository.url
        end

        # Just return the name, as it's remote repository
        def default_path(identifier)
            identifier
        end

        def existing_path(identifier, repository = nil)
            repository.root_url
        end

        def repository_name(path)
            matches = %r{^(?:.*/)?([^/]+?)(\\.git)?/?$}.match(path)
            matches ? matches[1] : nil
        end

        def repository_format
            "[[https://github.com/|git@github.com:]<username>/]<#{l(:label_repository_format)}>[.git]"
        end

        # To check if repository exists we need username, which is not always available
        def repository_exists?(identifier)
            false
        end

        def create_repository(path, params = {})
            response = client.create(repository_name(path), create_options)
            if response.is_a?(Hash) && response.has_key?(:clone_url)
                if params.has_key?(:url) && params[:url] =~ %r{^git@} && response.has_key?(:ssh_url)
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

    private

        def api
            @api ||= ScmConfig[scm_id] && ScmConfig[scm_id]['api']
        end

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
