class ScmHook  < Redmine::Hook::ViewListener

    def controller_project_aliases_rename_after(context = {})
        if context[:project].repository && context[:project].repository.created_with_scm
            repository = context[:project].repository
            interface  = SCMCreator.interface(repository)
            if interface

                name = interface.repository_name(repository.root_url)
                if name && interface.local? && interface.belongs_to_project?(name, context[:old_identifier])
                    old_path = interface.existing_path(name, repository)
                    if old_path
                        new_path = interface.default_path(context[:new_identifier])
                        File.rename(old_path, new_path)

                        url      = interface.access_url(new_path, repository)
                        root_url = interface.access_root_url(new_path, repository)

                        repository.update_attributes(:root_url => root_url, :url => url)
                    end
                end
            end
        end
    end

    render_on :view_projects_form, :partial => 'projects/scm'

private

    def project_scm_options_for_select(selected = nil)
        options = []
        options << [ '' ]           if ScmConfig['auto_create'] != 'force'
        options << [ 'Subversion' ] if SubversionCreator.enabled?
        options << [ 'Mercurial' ]  if MercurialCreator.enabled?
        options << [ 'Bazaar' ]     if BazaarCreator.enabled?
        options << [ 'Git' ]        if GitCreator.enabled?
        options << [ 'Github' ]     if GithubCreator.enabled?
        options_for_select(options, selected)
    end

end
