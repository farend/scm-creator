require 'redmine'

begin
    require 'octokit'
rescue LoadError
end

require_dependency 'creator/scm_creator'
require_dependency 'creator/subversion_creator'
require_dependency 'creator/mercurial_creator'
require_dependency 'creator/git_creator'
require_dependency 'creator/bazaar_creator'
require_dependency 'creator/github_creator'

require_dependency 'scm_config'
require_dependency 'scm_hook'

Rails.logger.info 'Starting SCM Creator Plugin for Redmine'

Redmine::Scm::Base.add('Github')

Rails.configuration.to_prepare do
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

Redmine::Plugin.register :redmine_scm do
    name        'SCM Creator'
    author      'Andriy Lesyuk'
    author_url  'http://www.andriylesyuk.com/'
    description 'Allows creating Subversion, Git, Mercurial, Bazaar and Github repositories within Redmine.'
    url         'http://projects.andriylesyuk.com/projects/scm-creator'
    version     '0.5.1'
end
