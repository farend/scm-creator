require_dependency 'repositories_helper'

module RepositoriesHelperPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            alias_method_chain :subversion_field_tags, :add
            alias_method_chain :git_field_tags, :add
        end
    end

    module ClassMethods
    end

    module InstanceMethods

        def subversion_field_tags_with_add(form, repository)
            svntags = subversion_field_tags_without_add(form, repository)
            if !@project.repository && SvnConfig['path'].present?
                RAILS_DEFAULT_LOGGER.info "[SUBVERSION_FIELD_TAGS_WITH_ADD] #{SvnConfig['svnadmin']}" # FIXME
                add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                svntags['<br />'] = ' ' + add + '<br />'
                svntags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless params && params[:repository] # FIXME: when switching it is not present
                    path = SvnConfig['path'].dup
                    path.gsub!(/\\/, "/") if Redmine::Platform.mswin?
                    svntags << javascript_tag("$('repository_url').value = 'file://#{escape_javascript(path)}/#{@project.identifier}';")
                end
            end
            return svntags
        end

        def git_field_tags_with_add(form, repository)
            gittags = git_field_tags_without_add(form, repository)
            if !@project.repository && SvnConfig['gitpath'].present?
                add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                gittags['</p>'] = ' ' + add + '</p>'
                gittags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless params && params[:repository]
                    path = SvnConfig['gitpath'].dup
                    path.gsub!(/\\/, "/") if Redmine::Platform.mswin?
                    gittags << javascript_tag("$('repository_url').value = 'file://#{escape_javascript(path)}/#{@project.identifier}';") # FIXME: file://?
                end
            end
            return gittags
        end

    end

end
