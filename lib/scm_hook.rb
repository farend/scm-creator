class ScmHook  < Redmine::Hook::ViewListener

    def view_projects_form(context = {})
        if context[:project].new_record? && ScmConfig['auto_create']
            count = [ SubversionCreator, GitCreator, MercurialCreator, BazaarCreator ].inject(0) do |sum, scm|
                sum += 1 if scm.enabled?
                sum
            end
            if (count > 1) || (ScmConfig['auto_create'] != 'force')
                row = ''
                row << label_tag('project[scm]', l(:field_scm) + (ScmConfig['auto_create'] == 'force' ? ' ' + content_tag(:span, '*', :class => 'required') : ''))
                row << select_tag('project[scm]', project_scm_options_for_select(context[:request].params[:project] ? context[:request].params[:project][:scm] : nil))
                row << '<br />' + content_tag(:em, l(:text_cannot_be_changed_later)) if ScmConfig['auto_create'] == 'force'
                content_tag(:p, row)
            else
                if SubversionCreator.enabled?
                    hidden_field_tag('project[scm]', 'Subversion')
                elsif GitCreator.enabled?
                    hidden_field_tag('project[scm]', 'Git')
                elsif MercurialCreator.enabled?
                    hidden_field_tag('project[scm]', 'Mercurial')
                elsif BazaarCreator.enabled?
                    hidden_field_tag('project[scm]', 'Bazaar')
                end
            end
        end
    end

    def controller_project_aliases_rename_after(context = {})
        Rails.logger.info " >>> controller_project_aliases_rename_after" # FIXME
        if context[:project].repository && context[:project].repository.created_with_scm

            type = context[:project].repository.type
            type.gsub!(%r{^Repository::}, '')

            Rails.logger.info " >>> #{type}" # FIXME
            begin
                interface = Object.const_get("#{type}Creator")

                name = interface.repository_name(context[:project].repository.root_url)
                Rails.logger.info " >>> #{name} <=> #{context[:old_identifier]}" # FIXME
                if name && interface.repository_name_equal?(name, context[:old_identifier])
                    old_path = interface.path(name)
                    Rails.logger.info " >>> #{old_path}" # FIXME
                    if File.directory?(old_path)
                        new_path = interface.default_path(context[:new_identifier])
                        Rails.logger.info " >>> #{old_path} => #{new_path}" # FIXME
                        File.rename(old_path, new_path)

                        url = interface.access_url(new_path)
                        root_url = interface.access_root_url(new_path)
                        context[:project].repository.update_attributes(:root_url => root_url, :url => url)
                    end
                end
            rescue NameError
                Rails.logger.info " >>> NameError" # FIXME
            end
        end
    end

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
