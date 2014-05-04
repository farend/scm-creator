require_dependency 'redmine/scm/adapters/git_adapter'

module Redmine
    module Scm
        module Adapters
            class GithubAdapter < GitAdapter

                def clone
                    cmd_args = %w{clone --mirror}
                    cmd_args << url
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

            end
        end
    end
end
