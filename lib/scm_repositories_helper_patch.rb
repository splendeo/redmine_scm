require_dependency 'repositories_helper'

module ScmRepositoriesHelperPatch

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
      svnconf = ScmConfig['svn']

      if !@project.repository && svnconf && svnconf['path'].present?
        add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
        svntags['<br />'] = ' ' + add + '<br />'
        svntags << hidden_field_tag(:operation, '', :id => 'repository_operation')
        unless request.post?
          path = svnconf['path'].dup
          path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
          svntags << javascript_tag("$('repository_url').value = 'file://#{escape_javascript(path)}/#{@project.identifier}';")
        end

      elsif @project.repository && @project.repository.created_with_scm &&
        svnconf && svnconf['path'].present? && svnconf['url'].present?
        path = svnconf['path'].dup
        path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
        matches = Regexp.new("^file://#{Regexp.escape(path)}/([^/]+)/?$").match(@project.repository.url)
        if matches
          url = ''
          if svnconf['url'] =~ %r{^(?:file|https?|svn(?:\+[a-z]+)?)://}
            url = "#{svnconf['url']}/#{matches[1]}"
          else
            url = "#{Setting.protocol}://#{Setting.host_name}/#{svnconf['url']}/#{matches[1]}"
          end
          svntags['(file:///, http://, https://, svn://, svn+[tunnelscheme]://)'] = url
        end
      end

      return svntags
    end
  end

end
