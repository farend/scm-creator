require_dependency 'repositories_helper'

module RepositoriesHelperPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            alias_method_chain :subversion_field_tags, :add
        end
    end

    module ClassMethods
    end

    module InstanceMethods

        def subversion_field_tags_with_add(form, repository)
            svntags = subversion_field_tags_without_add(form, repository)
            if !@project.repository && Svn['path'].present?
                add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
                svntags['<br />'] = ' ' + add + '<br />'
                svntags << hidden_field_tag(:operation, '', :id => 'repository_operation')
                unless params && params[:repository]
                    path = Svn['path'].dup
                    path.gsub!(/\\/, "/") if Redmine::Platform.mswin?
                    svntags << javascript_tag("$('repository_url').value = 'file://#{path}/';") # FIXME: escape
                end
            end
            return svntags
        end

    end

end
