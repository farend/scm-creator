require_dependency 'repositories_helper'

module ScmRepositoriesHelperPatch

    def self.included(base)
        base.extend(ClassMethods)
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

    module ClassMethods
    end

    module InstanceMethods

        def repository_field_tags_with_add(form, repository)
            reptags = repository_field_tags_without_add(form, repository)

            button_disabled = repository.class.respond_to?(:scm_available) ? !repository.class.scm_available : false

            if ScmConfig['only_creator']
                begin
                    interface = Object.const_get("#{repository.class.name.demodulize}Creator")
                rescue NameError
                end

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

            return reptags
        end

        def subversion_field_tags_with_add(form, repository)
            svntags = subversion_field_tags_without_add(form, repository)

            if @project.respond_to?(:repositories) &&
                ScmConfig['max_repos'] && ScmConfig['max_repos'].to_i > 0 && @project.repositories.select{ |r| r.created_with_scm }.size >= ScmConfig['max_repos'].to_i
                return svntags
            end

            if repository.new_record? && SubversionCreator.enabled?
                if defined? observe_field # Rails 3.0 and below
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                else # Rails 3.1 and above
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
                end
                svntags['<br />'] = ' ' + add + '<br />'
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

            elsif !repository.new_record? && repository.created_with_scm &&
                SubversionCreator.enabled? && SubversionCreator.options['url'].present?
                name = SubversionCreator.repository_name(repository.root_url)
                if name
                    svntags['(file:///, http://, https://, svn://, svn+[tunnelscheme]://)'] = SubversionCreator.external_url(name)
                end
            end

            return svntags
        end

        def mercurial_field_tags_with_add(form, repository)
            hgtags = mercurial_field_tags_without_add(form, repository)

            if @project.respond_to?(:repositories) &&
                ScmConfig['max_repos'] && ScmConfig['max_repos'].to_i > 0 && @project.repositories.select{ |r| r.created_with_scm }.size >= ScmConfig['max_repos'].to_i
                return hgtags
            end

            if repository.new_record? && MercurialCreator.enabled?
                if defined? observe_field # Rails 3.0 and below
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                else # Rails 3.1 and above
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
                end
                if hgtags.include?('<br />')
                    hgtags['<br />'] = ' ' + add + '<br />'
                else
                    hgtags['</p>'] = ' ' + add + '</p>'
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

            elsif !repository.new_record? && repository.created_with_scm &&
                MercurialCreator.enabled? && MercurialCreator.options['url'].present?
                name = MercurialCreator.repository_name(repository.root_url)
                if name
                    if hgtags.include?(l(:text_mercurial_repository_note))
                        hgtags[l(:text_mercurial_repository_note)] = MercurialCreator.external_url(name)
                    elsif hgtags.include?(l(:text_mercurial_repo_example))
                        hgtags[l(:text_mercurial_repo_example)] = MercurialCreator.external_url(name)
                    else
                        hgtags['</p>'] = '<br />' + MercurialCreator.external_url(name) + '</p>'
                    end
                end
            end

            return hgtags
        end

        def bazaar_field_tags_with_add(form, repository)
            bzrtags = bazaar_field_tags_without_add(form, repository)

            if @project.respond_to?(:repositories) &&
                ScmConfig['max_repos'] && ScmConfig['max_repos'].to_i > 0 && @project.repositories.select{ |r| r.created_with_scm }.size >= ScmConfig['max_repos'].to_i
                return bzrtags
            end

            if repository.new_record? && BazaarCreator.enabled?
                if defined? observe_field # Rails 3.0 and below
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                else # Rails 3.1 and above
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
                end
                bzrtags['</p>'] = ' ' + add + '</p>'
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

            elsif !repository.new_record? && repository.created_with_scm &&
                BazaarCreator.enabled? && BazaarCreator.options['url'].present?
                name = BazaarCreator.repository_name(repository.root_url)
                if name
                    bzrtags['</p>'] = '<br />' + BazaarCreator.external_url(name) + '</p>'
                end
            end

            return bzrtags
        end

        def git_field_tags_with_add(form, repository)
            gittags = git_field_tags_without_add(form, repository)

            if @project.respond_to?(:repositories) &&
                ScmConfig['max_repos'] && ScmConfig['max_repos'].to_i > 0 && @project.repositories.select{ |r| r.created_with_scm }.size >= ScmConfig['max_repos'].to_i
                return gittags
            end

            if repository.new_record? && GitCreator.enabled?
                if defined? observe_field # Rails 3.0 and below
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                else # Rails 3.1 and above
                    add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
                end
                if gittags.include?('<br />')
                    gittags['<br />'] = ' ' + add + '<br />'
                else
                    gittags['</p>'] = ' ' + add + '</p>'
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

            elsif !repository.new_record? && repository.created_with_scm &&
                GitCreator.enabled? && GitCreator.options['url'].present?
                name = GitCreator.repository_name(repository.root_url)
                if name
                    if gittags.include?(l(:text_git_repository_note))
                        gittags[l(:text_git_repository_note)] = GitCreator.external_url(name)
                    elsif gittags.include?(l(:text_git_repo_example))
                        gittags[l(:text_git_repo_example)] = GitCreator.external_url(name)
                    else
                        gittags['</p>'] = '<br />' + GitCreator.external_url(name) + '</p>'
                    end
                end
            end

            return gittags
        end

    end

end
