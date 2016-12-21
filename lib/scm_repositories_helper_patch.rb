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
            
            alias_method_chain :scm_path_info_tag, :external if method_defined?(:scm_path_info_tag)
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

            if request.xhr?
                reptags << javascript_tag("$('input[type=submit][name=commit]')." + (button_disabled ? "attr('disabled','disabled')" : "removeAttr('enable')") + ";")
            else
                reptags << javascript_tag("$(document).ready(function() { $('input[type=submit][name=commit]')." + (button_disabled ? "attr('disabled','disabled')" : "removeAttr('enable')") + "; });")
            end

            reptags.html_safe
        end

        def subversion_field_tags_with_add(form, repository)
            svntags = subversion_field_tags_without_add(form, repository)

            if repository.new_record? && SubversionCreator.enabled? && !limit_exceeded
                svntags << submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');",
                                                                        :id => :scm_creator_button, :style => 'display: none;')
                svntags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = SubversionCreator.access_root_url(SubversionCreator.default_path(@project.identifier), repository)
                    if SubversionCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
                        path << '.' + @project.repositories.select{ |r| r.created_with_scm }.size.to_s
                    end
                    svntags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                end
                svntags << javascript_tag("$('#repository_url').after($('#scm_creator_button')).after(' ') && $('#scm_creator_button').show();")

            elsif !respond_to?(:scm_path_info_tag) && !repository.new_record? && repository.created_with_scm && SubversionCreator.enabled?
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
                hgtags << submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');",
                                                                       :id => :scm_creator_button, :style => 'display: none;')
                hgtags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = MercurialCreator.access_root_url(MercurialCreator.default_path(@project.identifier), repository)
                    if MercurialCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
                        path << '.' + @project.repositories.select{ |r| r.created_with_scm }.size.to_s
                    end
                    hgtags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                end
                hgtags << javascript_tag("$('#repository_url').after($('#scm_creator_button')).after(' ') && $('#scm_creator_button').show();")

            elsif !respond_to?(:scm_path_info_tag) && !repository.new_record? && repository.created_with_scm && MercurialCreator.enabled?
                url = MercurialCreator.external_url(repository)
                if url
                    if hgtags.include?(l(:text_mercurial_repository_note))
                        hgtags.sub!(l(:text_mercurial_repository_note), url)
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
                bzrtags << submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');",
                                                                        :id => :scm_creator_button, :style => 'display: none;')
                bzrtags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = BazaarCreator.access_root_url(BazaarCreator.default_path(@project.identifier), repository)
                    if BazaarCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
                        path << '.' + @project.repositories.select{ |r| r.created_with_scm }.size.to_s
                    end
                    bzrtags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                    if BazaarCreator.options['log_encoding']
                        bzrtags << javascript_tag("$('#repository_log_encoding').val('#{escape_javascript(BazaarCreator.options['log_encoding'])}');")
                    end
                end
                bzrtags << javascript_tag("$('#repository_url').after($('#scm_creator_button')).after(' ') && $('#scm_creator_button').show();")

            elsif !respond_to?(:scm_path_info_tag) && !repository.new_record? && repository.created_with_scm && BazaarCreator.enabled?
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
                gittags << submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');",
                                                                        :id => :scm_creator_button, :style => 'display: none;')
                gittags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = GitCreator.access_root_url(GitCreator.default_path(@project.identifier), repository)
                    if GitCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
                        offset = @project.repositories.select{ |r| r.created_with_scm }.size.to_s
                        if path.sub!(%r{\.git\z}, '.' + offset + '.git').nil?
                            path << '.' + offset
                        end
                    end
                    gittags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                end
                gittags << javascript_tag("$('#repository_url').after($('#scm_creator_button')).after(' ') && $('#scm_creator_button').show();")

            elsif !respond_to?(:scm_path_info_tag) && !repository.new_record? && repository.created_with_scm && GitCreator.enabled?
                url = GitCreator.external_url(repository)
                if url
                    if gittags.include?(l(:text_git_repository_note))
                        gittags.sub!(l(:text_git_repository_note), url)
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
                urltag << ' '.html_safe
                urltag << submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');",
                                                                       :id => :scm_creator_button)
                urltag << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless request.post?
                    path = @project.identifier
                    urltag << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
                end
                note = content_tag('em', l(:text_github_repository_note_new), :class => 'info')
            elsif repository.new_record?
                note = content_tag('em', '(https://github.com/....git)', :class => 'info')
            end

            githubtags  = content_tag('p', urltag + note)
            githubtags << content_tag('p', form.text_field(:login, :size => 30)) +
                          content_tag('p', form.password_field(:password, :size => 30,
                                                                          :name => 'ignore',
                                                                          :value => ((repository.new_record? || repository.password.blank?) ? '' : ('x'*15)),
                                                                          :onfocus => "this.value=''; this.name='repository[password]';",
                                                                          :onchange => "this.name='repository[password]';") +
                                           content_tag('em', l(:text_github_credentials_note), :class => 'info'))
            if !Setting.autofetch_changesets? && GithubCreator.can_register_hook?
                githubtags << content_tag('p', form.check_box(:extra_register_hook, :disabled => repository.extra_hook_registered) + ' ' +
                                               l(:text_github_register_hook_note))
            end

            githubtags
        end

        def scm_path_info_tag_with_external(repository)
            if !repository.new_record? && repository.created_with_scm
                interface = SCMCreator.interface(repository)
                if interface && (url = interface.external_url(repository))
                    return content_tag('em', url, :class => 'info')
                end
            end
            scm_path_info_tag_without_external(repository)
        end

    private

        def limit_exceeded
            @project.respond_to?(:repositories) &&
            ScmConfig['max_repos'] && ScmConfig['max_repos'].to_i > 0 &&
            @project.repositories.select{ |r| r.created_with_scm }.size >= ScmConfig['max_repos'].to_i
        end

    end

end
