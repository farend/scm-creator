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
                svntags.sub!('<br />', ' ' + add + '<br />')
                svntags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = SubversionCreator.access_root_url(SubversionCreator.default_path(@project.identifier), repository)
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
                    svntags.sub!('(file:///, http://, https://, svn://, svn+[tunnelscheme]://)', url)
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
                    hgtags.sub!('<br />', ' ' + add + '<br />')
                else
                    hgtags.sub!('</p>', ' ' + add + '</p>')
                end
                hgtags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = MercurialCreator.access_root_url(MercurialCreator.default_path(@project.identifier), repository)
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
                        hgtags.sub!(l(:text_mercurial_repository_note), url)
                    elsif hgtags.include?(l(:text_mercurial_repo_example))
                        hgtags.sub!(l(:text_mercurial_repo_example), url)
                    else
                        hgtags.sub!('</p>', '<br />' + url + '</p>')
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
                bzrtags.sub!('</p>', ' ' + add + '</p>')
                bzrtags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = BazaarCreator.access_root_url(BazaarCreator.default_path(@project.identifier), repository)
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
                    bzrtags.sub!('</p>', '<br />' + url + '</p>')
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
                    gittags.sub!('<br />', ' ' + add + '<br />')
                else
                    gittags.sub!('</p>', ' ' + add + '</p>')
                end
                gittags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = GitCreator.access_root_url(GitCreator.default_path(@project.identifier), repository)
                    if GitCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
                        offset = @project.repositories.select{ |r| r.created_with_scm }.size.to_s
                        if path.sub!(%r{\.git\z}, '.' + offset + '.git').nil?
                            path << '.' + offset
                        end
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
                        gittags.sub!(l(:text_git_repository_note), url)
                    elsif gittags.include?(l(:text_git_repo_example))
                        gittags.sub!(l(:text_git_repo_example), url)
                    else
                        gittags.sub!('</p>', '<br />' + url + '</p>')
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
                        urltag << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
                    else # Rails 3.1 and above
                        urltag << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                    end
                end
                note = l(:text_github_repository_note_new)
            elsif repository.new_record?
                note = '(https://github.com/)'
            end

            githubtags  = content_tag('p', urltag + '<br />'.html_safe + note)
            githubtags << content_tag('p', form.text_field(:login, :size => 30)) +
                          content_tag('p', form.password_field(:password, :size => 30,
                                                                          :name => 'ignore',
                                                                          :value => ((repository.new_record? || repository.password.blank?) ? '' : ('x'*15)),
                                                                          :onfocus => "this.value=''; this.name='repository[password]';",
                                                                          :onchange => "this.name='repository[password]';") +
                                           '<br />'.html_safe + l(:text_github_credentials_note))
            if !Setting.autofetch_changesets? && GithubCreator.can_register_hook?
                githubtags << content_tag('p', form.check_box(:extra_register_hook, :disabled => repository.extra_hook_registered) + ' ' +
                                               l(:text_github_register_hook_note))
            end

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
