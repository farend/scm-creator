require_dependency 'repositories_helper'

module ScmRepositoriesHelperPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            alias_method_chain :subversion_field_tags, :add
            alias_method_chain :mercurial_field_tags,  :add
            alias_method_chain :git_field_tags,        :add
        end
    end

    module ClassMethods
    end

    module InstanceMethods

        def subversion_field_tags_with_add(form, repository)
            svntags = subversion_field_tags_without_add(form, repository)
            svnconf = ScmConfig['svn']

            if !@project.repository && svnconf && svnconf['path'].present?
                add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                svntags['<br />'] = ' ' + add + '<br />'
                svntags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = SubversionCreator.command_line_path(SubversionCreator.default_path(@project.identifier))
                    svntags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
                end

            elsif @project.repository && @project.repository.created_with_scm &&
                svnconf && svnconf['path'].present? && svnconf['url'].present?
                name = SubversionCreator.repository_name(@project.repository.url)
                if name
                    svntags['(file:///, http://, https://, svn://, svn+[tunnelscheme]://)'] = SubversionCreator.url(name)
                end
            end

            return svntags
        end

        def mercurial_field_tags_with_add(form, repository)
            hgtags = mercurial_field_tags_without_add(form, repository)
            hgconf = ScmConfig['mercurial']

            if !@project.repository && hgconf && hgconf['path'].present?
                add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                if hgtags.include?('<br />')
                    hgtags['<br />'] = ' ' + add + '<br />'
                else
                    hgtags['</p>'] = ' ' + add + '</p>'
                end
                hgtags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = MercurialCreator.command_line_path(MercurialCreator.default_path(@project.identifier))
                    hgtags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
                end

            elsif @project.repository && @project.repository.created_with_scm &&
                hgconf && hgconf['path'].present? && hgconf['url'].present?
                name = MercurialCreator.repository_name(@project.repository.url)
                if name
                    hgtags['</p>'] = '<br />' + MercurialCreator.url(name) + '</p>' # FIXME: replace in 1.2.x
                end
            end

            return hgtags
        end

        def git_field_tags_with_add(form, repository)
            gittags = git_field_tags_without_add(form, repository)
            gitconf = ScmConfig['git']

            if !@project.repository && gitconf && gitconf['path'].present?
                add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                if gittags.include?('<br />')
                    gittags['<br />'] = ' ' + add + '<br />'
                else
                    gittags['</p>'] = ' ' + add + '</p>'
                end
                gittags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = GitCreator.command_line_path(GitCreator.default_path(@project.identifier))
                    gittags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
                end

            elsif @project.repository && @project.repository.created_with_scm &&
                gitconf && gitconf['path'].present? && gitconf['url'].present?
                name = GitCreator.repository_name(@project.repository.url)
                if name
                    gittags['</p>'] = '<br />' + GitCreator.url(name) + '</p>' # FIXME: replace in 1.2.x
                end
            end

            return gittags
        end

    end

end
