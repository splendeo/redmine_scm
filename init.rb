require 'redmine'
require 'dispatcher'

require_dependency 'scm_config'
require_dependency 'scm_hook'

RAILS_DEFAULT_LOGGER.info 'Starting SCM Creator Plugin for Redmine'

Dispatcher.to_prepare :redmine_scm_plugin do
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
  author 'Andriy Lesyuk, Francisco de Juan'
  description 'Allows creating Subversion/Git repositories using Redmine.'
  url 'https://github.com/splendeo/redmine_scm'
  version '0.1.2'
end
