class ScmHook  < Redmine::Hook::ViewListener

    def view_projects_form(context = {})
        if context[:project].new_record? && ScmConfig['auto_create']
            count = %w(svn git mercurial).inject(0) do |sum, scm|
                sum += 1 if ScmConfig[scm]
                sum
            end
            if (count > 1) || (ScmConfig['auto_create'] != 'force')
                row = ''
                row << label_tag('project[scm]', l(:field_scm) + (ScmConfig['auto_create'] == 'force' ? ' ' + content_tag(:span, '*', :class => 'required') : ''))
                row << select_tag('project[scm]', project_scm_options_for_select(context[:request].params[:project] ? context[:request].params[:project][:scm] : nil))
                row << '<br />' + content_tag(:em, l(:text_cannot_be_changed_later)) if ScmConfig['auto_create'] == 'force'
                content_tag(:p, row)
            else
                if ScmConfig['svn']
                    hidden_field_tag('project[scm]', 'Subversion')
                elsif ScmConfig['git']
                    hidden_field_tag('project[scm]', 'Git')
                elsif ScmConfig['mercurial']
                    hidden_field_tag('project[scm]', 'Mercurial')
                end
            end
        end
    end

private

    def project_scm_options_for_select(selected = nil)
        options = []
        options << [ '' ]           if ScmConfig['auto_create'] != 'force'
        options << [ 'Subversion' ] if ScmConfig['svn']
        options << [ 'Mercurial' ]  if ScmConfig['mercurial']
        options << [ 'Git' ]        if ScmConfig['git']
        options_for_select(options, selected)
    end

end
