class ScmHook  < Redmine::Hook::ViewListener

    def view_projects_form(context = {})
        if context[:project].new_record? && ScmConfig['auto_create']
            if (ScmConfig['svn'] && ScmConfig['git']) || (ScmConfig['auto_create'] != 'force')
                row = ''
                row << label_tag('project[scm]', l(:field_scm) + (ScmConfig['auto_create'] == 'force' ? ' ' + content_tag(:span, '*', :class => 'required') : ''))
                row << select_tag('project[scm]', project_scm_options_for_select(context[:request].params[:project] ? context[:request].params[:project][:scm] : nil))
                row << '<br />' + content_tag(:em, l(:text_cannot_be_changed_later)) if ScmConfig['auto_create'] == 'force'
                content_tag(:p, row)
            else
                hidden_field_tag('project[scm]', ScmConfig['svn'] ? 'Subversion' : 'Git')
            end
        end
    end

private

    def project_scm_options_for_select(selected = nil)
        options = []
        options << [ '' ] if ScmConfig['auto_create'] != 'force'
        options << [ 'Subversion' ] if ScmConfig['svn']
        options << [ 'Git' ] if ScmConfig['git']
        options_for_select(options, selected)
    end

end
