require 'redmine'

begin
    require 'dispatcher'

    def dispatch(plugin, &block)
        Dispatcher.to_prepare(plugin, &block)
    end

rescue LoadError # Rails 3

    def dispatch(plugin, &block)
        Rails.configuration.to_prepare(&block)
    end

end

require_dependency 'creator/scm_creator'
require_dependency 'creator/subversion_creator'
require_dependency 'creator/mercurial_creator'
require_dependency 'creator/git_creator'
require_dependency 'creator/bazaar_creator'

require_dependency 'scm_config'
require_dependency 'scm_hook'

Rails.logger.info 'Starting SCM Creator Plugin for Redmine'

ActiveRecord::Base.observers << :repository_observer

dispatch :redmine_scm_plugin do
    unless Project.included_modules.include?(ScmProjectPatch)
        Project.send(:include, ScmProjectPatch)
    end
    unless RepositoriesHelper.included_modules.include?(ScmRepositoriesHelperPatch)
        RepositoriesHelper.send(:include, ScmRepositoriesHelperPatch)
    end
    unless RepositoriesController.included_modules.include?(ScmRepositoriesControllerPatch)
        RepositoriesController.send(:include, ScmRepositoriesControllerPatch)
    end
end

Redmine::Plugin.register :redmine_scm_plugin do
    name 'SCM Creator'
    author 'Andriy Lesyuk'
    author_url 'http://www.andriylesyuk.com/'
    description 'Allows creating Subversion, Git, Mercurial and Bazaar repositories using Redmine.'
    url 'http://projects.andriylesyuk.com/projects/redmine-svn'
    version '0.3.1'
end
