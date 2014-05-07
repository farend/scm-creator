require_dependency 'repositories_helper'

module ScmRepositoriesHelperPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method_chain :repository_field_tags, :add
            alias_method_chain :subversion_field_tags, :add
            alias_method_chain :mercurial_field_tags,  :add
            alias_method_chain :git_field_tags,        :add
            alias_method_chain :bazaar_field_tags,     :add
        end
    end

    module InstanceMethods

        def repository_field_tags_with_add(form, repository)
            reptags = repository_field_tags_without_add(form, repository)

            button_disabled = repository.class.respond_to?(:scm_available) ? !repository.class.scm_available : false

            if ScmConfig['only_creator']
                interface = SCMCreator.interface(repository)

                if interface && (interface < SCMCreator) && interface.enabled? && repository.new_record?
                    button_disabled = true
                end
            end

            if defined? observe_field # Rails 3.0 and below
                if request.xhr?
                    reptags << javascript_tag("$('repository_save')." + (button_disabled ? 'disable' : 'enable') + "();")
                else
                    reptags << javascript_tag("Event.observe(window, 'load', function() { $('repository_save')." + (button_disabled ? 'disable' : 'enable') + "(); });")
                end
            else # Rails 3.1 and above
                if request.xhr?
                    reptags << javascript_tag("$('#repository_save')." + (button_disabled ? "attr('disabled','disabled')" : "removeAttr('enable')") + ";")
                else
                    reptags << javascript_tag("$(document).ready(function() { $('#repository_save')." + (button_disabled ? "attr('disabled','disabled')" : "removeAttr('enable')") + "; });")
                end
            end

            reptags.html_safe
        end

        def subversion_field_tags_with_add(form, repository)
            svntags = subversion_field_tags_without_add(form, repository)
            svntags.gsub!('&lt;br /&gt;', '<br />')

            if repository.new_record? && SubversionCreator.enabled? && !limit_exceeded
                if defined? observe_field # Rails 3.0 and below
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                else # Rails 3.1 and above
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
                end
                svntags.gsub!('<br />', ' ' + add + '<br />')
                svntags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = SubversionCreator.access_root_url(SubversionCreator.default_path(@project.identifier))
                    if SubversionCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
                        path << '.' + @project.repositories.select{ |r| r.created_with_scm }.size.to_s
                    end
                    if defined? observe_field # Rails 3.0 and below
                        svntags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
                    else # Rails 3.1 and above
                        svntags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                    end
                end

            elsif !repository.new_record? && repository.created_with_scm && SubversionCreator.enabled?
                url = SubversionCreator.external_url(repository)
                if url
                    svntags.gsub!('(file:///, http://, https://, svn://, svn+[tunnelscheme]://)', url)
                end
            end

            svntags
        end

        def mercurial_field_tags_with_add(form, repository)
            hgtags = mercurial_field_tags_without_add(form, repository)

            if repository.new_record? && MercurialCreator.enabled? && !limit_exceeded
                if defined? observe_field # Rails 3.0 and below
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                else # Rails 3.1 and above
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
                end
                if hgtags.include?('<br />')
                    hgtags.gsub!('<br />', ' ' + add + '<br />')
                else
                    hgtags.gsub!('</p>', ' ' + add + '</p>')
                end
                hgtags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = MercurialCreator.access_root_url(MercurialCreator.default_path(@project.identifier))
                    if MercurialCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
                        path << '.' + @project.repositories.select{ |r| r.created_with_scm }.size.to_s
                    end
                    if defined? observe_field # Rails 3.0 and below
                        hgtags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
                    else # Rails 3.1 and above
                        hgtags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                    end
                end

            elsif !repository.new_record? && repository.created_with_scm && MercurialCreator.enabled?
                url = MercurialCreator.external_url(repository)
                if url
                    if hgtags.include?(l(:text_mercurial_repository_note))
                        hgtags.gsub!(l(:text_mercurial_repository_note), url)
                    elsif hgtags.include?(l(:text_mercurial_repo_example))
                        hgtags.gsub!(l(:text_mercurial_repo_example), url)
                    else
                        hgtags.gsub!('</p>', '<br />' + url + '</p>')
                    end
                end
            end

            hgtags
        end

        def bazaar_field_tags_with_add(form, repository)
            bzrtags = bazaar_field_tags_without_add(form, repository)

            if repository.new_record? && BazaarCreator.enabled? && !limit_exceeded
                if defined? observe_field # Rails 3.0 and below
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                else # Rails 3.1 and above
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
                end
                bzrtags.gsub!('</p>', ' ' + add + '</p>')
                bzrtags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = BazaarCreator.access_root_url(BazaarCreator.default_path(@project.identifier))
                    if BazaarCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
                        path << '.' + @project.repositories.select{ |r| r.created_with_scm }.size.to_s
                    end
                    if defined? observe_field # Rails 3.0 and below
                        bzrtags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
                    else # Rails 3.1 and above
                        bzrtags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                    end
                    if BazaarCreator.options['log_encoding']
                        if defined? observe_field # Rails 3.0 and below
                            bzrtags << javascript_tag("$('repository_log_encoding').value = '#{escape_javascript(BazaarCreator.options['log_encoding'])}';")
                        else # Rails 3.1 and above
                            bzrtags << javascript_tag("$('#repository_log_encoding').val('#{escape_javascript(BazaarCreator.options['log_encoding'])}');")
                        end
                    end
                end

            elsif !repository.new_record? && repository.created_with_scm && BazaarCreator.enabled?
                url = BazaarCreator.external_url(repository)
                if url
                    bzrtags.gsub!('</p>', '<br />' + url + '</p>')
                end
            end

            bzrtags
        end

        def git_field_tags_with_add(form, repository)
            gittags = git_field_tags_without_add(form, repository)

            if repository.new_record? && GitCreator.enabled? && !limit_exceeded
                if defined? observe_field # Rails 3.0 and below
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                else # Rails 3.1 and above
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
                end
                if gittags.include?('<br />')
                    gittags.gsub!('<br />', ' ' + add + '<br />')
                else
                    gittags.gsub!('</p>', ' ' + add + '</p>')
                end
                gittags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = GitCreator.access_root_url(GitCreator.default_path(@project.identifier))
                    if GitCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
                        path << '.' + @project.repositories.select{ |r| r.created_with_scm }.size.to_s
                    end
                    if defined? observe_field # Rails 3.0 and below
                        gittags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
                    else # Rails 3.1 and above
                        gittags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                    end
                end

            elsif !repository.new_record? && repository.created_with_scm && GitCreator.enabled?
                url = GitCreator.external_url(repository)
                if url
                    if gittags.include?(l(:text_git_repository_note))
                        gittags.gsub!(l(:text_git_repository_note), url)
                    elsif gittags.include?(l(:text_git_repo_example))
                        gittags.gsub!(l(:text_git_repo_example), url)
                    else
                        gittags.gsub!('</p>', '<br />' + url + '</p>')
                    end
                end
            end

            gittags
        end

        def github_field_tags(form, repository)
            urltag = form.text_field(:url, :size => 60,
                                           :required => true,
                                           :disabled => !repository.safe_attribute?('url'))

            if repository.new_record? && GithubCreator.enabled? && !limit_exceeded
                if defined? observe_field # Rails 3.0 and below
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                else # Rails 3.1 and above
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
                end
                urltag << add
                urltag << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = @project.identifier
                    if defined? observe_field # Rails 3.0 and below
                        gittags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
                    else # Rails 3.1 and above
                        gittags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                    end
                end
                note = l(:text_github_repository_note_new)
            else
                note = '(https://github.com/, git@github.com:)'
            end

            githubtags  = content_tag('p', urltag + '<br />'.html_safe + note)
            githubtags << content_tag('p', form.text_field(:login, :size => 30)) + # FIXME only for https://
                          content_tag('p', form.password_field(:password, :size => 30,
                                                                          :name => 'ignore',
                                                                          :value => ((repository.new_record? || repository.password.blank?) ? '' : ('x'*15)),
                                                                          :onfocus => "this.value=''; this.name='repository[password]';",
                                                                          :onchange => "this.name='repository[password]';"))
            githubtags << content_tag('p', form.check_box(:extra_register_hook))
            # TODO You need to be an administrator of the repository + if autofetching is disabled + readonly if registered

            githubtags
        end

    private

        def limit_exceeded
            @project.respond_to?(:repositories) &&
            ScmConfig['max_repos'] && ScmConfig['max_repos'].to_i > 0 &&
            @project.repositories.select{ |r| r.created_with_scm }.size >= ScmConfig['max_repos'].to_i
        end

    end

end
