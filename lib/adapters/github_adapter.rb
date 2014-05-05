require_dependency 'redmine/scm/adapters/git_adapter'

module Redmine
    module Scm
        module Adapters
            class GithubAdapter < GitAdapter

                def clone
                    cmd_args = %w{clone --mirror}
                    cmd_args << url_with_credentials
                    cmd_args << root_url
                    git_cmd(cmd_args)
                rescue ScmCommandAborted
                end

                def fetch
                    Dir.chdir(root_url) do
                        cmd_args = %{fetch --quiet --all --prune}
                        git_cmd(cmd_args)
                    end
                rescue ScmCommandAborted
                end

            private

                def url_with_credentials
                    if @login.present? && @password.present?
                        if url =~ %r{^https://}
                            url.gsub(%r{^https://}, "https://#{@login}:#{@password}@")
                        else
                            url.gsub(%r{^git@}, "#{@login}:#{@password}@") # FIXME does not work
                        end
                    else
                        url
                    end
                end

            end
        end
    end
end
