class ScmHook  < Redmine::Hook::ViewListener

    def controller_project_aliases_rename_after(context = {})
        if context[:project].repository && context[:project].repository.created_with_scm

            type = context[:project].repository.class.name.demodulize

            begin
                interface = Object.const_get("#{type}Creator")

                name = interface.repository_name(context[:project].repository.root_url)
                if name && interface.belongs_to_project?(name, context[:old_identifier])
                    old_path = interface.existing_path(name)
                    if old_path
                        new_path = interface.default_path(context[:new_identifier])
                        File.rename(old_path, new_path)

                        url = interface.access_url(new_path)
                        root_url = interface.access_root_url(new_path)
                        context[:project].repository.update_attributes(:root_url => root_url, :url => url)
                    end
                end
            rescue NameError
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
        options_for_select(options, selected)
    end

end
