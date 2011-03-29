require 'redmine'
require 'dispatcher'

require_dependency 'svn'

RAILS_DEFAULT_LOGGER.info 'Starting Subversion Plugin for Redmine'

Dispatcher.to_prepare :redmine_svn_plugin do
    unless RepositoriesHelper.included_modules.include?(RepositoriesHelperPatch)
        RepositoriesHelper.send(:include, RepositoriesHelperPatch)
    end
    unless RepositoriesController.included_modules.include?(RepositoriesControllerPatch)
        RepositoriesController.send(:include, RepositoriesControllerPatch)
    end
end

Redmine::Plugin.register :redmine_svn_plugin do
    name 'SVN Repository Creator'
    author 'Andriy Lesyuk'
    author_url 'http://www.facebook.com/andriy.lesyuk'
    description 'Allows creating Subversion repositories using Redmine.'
    url 'http://labs.softjourn.com/projects/redmine-svn'
    version '0.0.2'
end
