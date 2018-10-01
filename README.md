# scm-creator

Fork of http://projects.andriylesyuk.com/projects/scm-creator.  
The following explanation is adapted from a [Origin of fork](http://projects.andriylesyuk.com/projects/scm-creator).

Simple [Subversion](http://subversion.apache.org/), [Git](https://git-scm.com/), [Mercurial](https://www.mercurial-scm.org/),[Bazaar](http://bazaar.canonical.com/en/) and [Github](https://github.com/) repository creation plugin for [Redmine](http://www.redmine.org/). With this plugin repository creation and registration becomes very easy and needs just one click (or even no click).

This repository is different from the original repository forked
in the following point.
* Change for use with Redmine 3.4
* Bug fixese

This plugin requires __Redmine version 3.4.0__ or higher.

## Description

The plugin adds “Create new repository” button to the repository addition form (Project → Settings → Repository → Subversion/Git/Mercurial/Bazaar/Github).  
With just one click on this button a user can create local repository and register it in Redmine.  
The plugin also allows to create repository automatically on project registration.  

Github SCM is another SCM type, that comes with SCM Creator (not available in pure Redmine).

## Usage

The plugin adds “Create new repository” button to the [Subversion](http://subversion.apache.org/),[Git](https://git-scm.com/), [Mercurial](https://www.mercurial-scm.org/), [Bazaar](http://bazaar.canonical.com/en/) and [Github](https://github.com/) repository creation form (“Repository” tab in project settings):

<kbd>![scm-creator-settings](https://user-images.githubusercontent.com/14245262/30414230-755135f6-995d-11e7-8756-2eea465facd1.png)</kbd>

The plugin will automatically fill in the repository URL field with the root directory<sup>[1](#myfootnote1)</sup> and project identifier.  
To create new local<sup>[2](#myfootnote2)</sup> repository you just need to click the “Create new repository” button.It is also possible to [configure the plugin](http://projects.andriylesyuk.com/projects/scm-creator/wiki/Configuration) to create repositories automatically for new projects.  

*!* If you are using [Redmine based authentication](http://www.redmine.org/projects/redmine/wiki/Repositories_access_control_with_apache_mod_dav_svn_and_mod_perl) for repositories access (what is recommended) the repository name<sup>[3](#myfootnote3)</sup> must be identical to the project identifier.

The plugin will create the repository for you and automatically register it in Redmine(no need to additionally click on the “Create” button below the form).

## Install

Assuming you already have installed Subversion, Git, Mercurial and/or Bazaar and the Apache DAV module. Please refer to your operating system manual on how to do this if not.

### 1. Creating root directory

First you need to choose where repositories are going to be stored and to create this directory. For example, for SVN I chose */var/lib/svn*.

````
# mkdir /var/lib/svn
````

This directory should be writtable by the user Redmine is ran from (this can be *www-data*, *apache* or *nobody* - depending on the OS<sup>[4](#myfootnote4)</sup>).  
Change the owner and the group:

````
# chown www-data:www-data /var/lib/svn
````

If you are not sure about the owner try running the following command:

````
# ps aux | grep ruby
www-data 32262  4.3 12.1 262304 127864 ?       S    14:39  15:55 ruby
/usr/share/redmine/public/dispatch.fcgi
````

Also make sure the directory can be written by the user:

````
# ls -l /var/lib | grep svn
drwxr-xr-x 18 www-data www-data 4096 May 17 12:44 svn
````

To change permissions do:

````
# chmod 0755 /var/lib/svn
````

Do the same for Git, Mercurial and/or Bazaar.

### 2. Configuring the plugin

The plugin reads its configuration from *#{RAILS_ROOT}/config/scm.yml*.
Copy sample *scm.yml* file from the plugin directory to *#{RAILS_ROOT}/config/* and modify it.

The configuration of the plugin is described in details on the corresponding page.
Check [this page](http://projects.andriylesyuk.com/projects/scm-creator/wiki/Configuration) for common configuration scenarios.

### 3. Automatic creation

You can configure the plugin to create a repository automatically when a project is registered.
For this change the *auto_create* option to *true* or *force* (for meanings of these values check [this page](http://projects.andriylesyuk.com/projects/scm-creator/wiki/Configuration)).  
When the automatic creation is enabled the project registration form will have an additional field:

<kbd>![scm-creator-project](https://user-images.githubusercontent.com/14245262/30414139-12974806-995d-11e7-8fab-0fa3621926d7.png)</kbd>

### 4. Installing plugin

To install the plugin do:

+ Install plugin:

````
cd /path/to/redmine/plugins  
git clone https://github.com/farend/scm-creator.git redmine_scm
cd /path/to/redmine
bundle install --without development test
rake redmine:plugins:migrate RAILS_ENV=production
````

+ Make sure the directory name of the plugin is 'redmine_scm'.  
:warning:The plugin does not work if the directory name is not 'redmine_scm'.  
If the directory name is not 'redmine_scm', please fix it.

+ Restart Redmine

### 5. Configuring Apache/DAV

It is recommended to configure your SVN/Git/Mercurial server to use usernames, passwords and permissions from the Redmine database.

Refer the following links on what to do next:

+ For Subversion:
	+ [Repositories access control with apache, mod_dav_svn and mod_perl](http://www.redmine.org/projects/redmine/wiki/Repositories_access_control_with_apache_mod_dav_svn_and_mod_perl)
+ For Git (it is slightly more complicated):
	+ [Repositories access control with apache, mod_dav_svn and mod_perl](http://www.redmine.org/projects/redmine/wiki/Repositories_access_control_with_apache_mod_dav_svn_and_mod_perl)
	+ [HowTo configure Redmine for advanced git integration](http://www.redmine.org/projects/redmine/wiki/HowTo_configure_Redmine_for_advanced_git_integration)
	+ [Redmine.pm: add support for Git's smart HTTP protocol](http://www.redmine.org/issues/4905)
+ For Mercurial (did not test it):
	+ [HowTo configure Redmine for advanced Mercurial integration](http://www.redmine.org/projects/redmine/wiki/HowTo_configure_Redmine_for_advanced_Mercurial_integration)

*Note:* For Redmine based SVN/Git/Mercurial authentication to work the repository name and the project identifier must be identical.

## LICENSE

Copylight (C) 2017 FAR END Technologies Corporation
Originally under GPL v2 in Andriy Lesyuk, http://subversion.andriylesyuk.com/scm-creator/


----

<sup id="myfootnote1">1</sup> specified in [scm.yml](http://projects.andriylesyuk.com/projects/scm-creator/wiki/Configuration)  
<sup id="myfootnote2">2</sup> in terms of Redmine server  
<sup id="myfootnote3">3</sup> last directory in repository URL  
<sup id="myfootnote4">4</sup> this page describes installation under Unix-like OSes only
