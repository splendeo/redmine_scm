require_dependency 'repositories_controller'

module ScmRepositoriesControllerPatch
  
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      before_filter :delete_scm, :only => :destroy
    end
    base.send(:alias_method_chain, :edit, :add)
  end

  module InstanceMethods

    def delete_scm
      if @repository.created_with_scm && ScmConfig['deny_delete']
        RAILS_DEFAULT_LOGGER.info "Deletion denied: #{@repository.url}"
        render_403
      end
    end

    # Original function
    #def edit
    #  @repository = @project.repository
    #  if !@repository
    #    @repository = Repository.factory(params[:repository_scm])
    #    @repository.project = @project if @repository
    #  end
    #  if request.post? && @repository
    #    @repository.attributes = params[:repository]
    #    @repository.save
    #  end
    #  render(:update) do |page|
    #    page.replace_html("tab-content-repository", :partial => 'projects/settings/repository')
    #    if @repository && !@project.repository
    #      @project.reload
    #      page.replace_html("main-menu", render_main_menu(@project))
    #    end
    #  end
    #end

    def edit_with_add
      @repository = @project.repository
      if !@repository
        @repository = Repository.factory(params[:repository_scm])
        @repository.project = @project if @repository
      end
      
      if request.post? && @repository && params[:repository_scm] == 'Subversion'&& params[:operation].present? && params[:operation] == 'add'
        if params[:repository]
          svnconf = ScmConfig['svn']
          path = svnconf['path'].dup
          path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
          matches = Regexp.new("^file://#{Regexp.escape(path)}/([^/]+)/?$").match(params[:repository]['url'])
          if matches
            repath = Redmine::Platform.mswin? ? "#{svnconf['path']}\\#{matches[1]}" : "#{svnconf['path']}/#{matches[1]}"
            if File.directory?(repath)
              @repository.errors.add(:url, :already_exists)
            else
              RAILS_DEFAULT_LOGGER.info "Creating SVN reporitory: #{repath}"
              args = [ svnconf['svnadmin'], 'create', repath ]
              if svnconf['options']
                if svnconf['options'].is_a?(Array)
                  args += svnconf['options']
                else
                  args << svnconf['options']
                end
              end
              if system(*args)
                @repository.created_with_scm = true
                
                #Execute chown and chmod
                if svnconf['chown'].present?
                  uid = svnconf['chown']['user']
                  gid = svnconf['chown']['group']
                  system("sudo chown #{uid}:#{gid} #{repath} -R")
                  system("sudo chmod g+w #{repath} -R")
                end
              else
                RAILS_DEFAULT_LOGGER.error "Repository creation failed"
              end
            end
            if matches[1] != @project.identifier
              flash[:warning] = l(:text_cannot_be_used_redmine_auth)
            end
          else
            @repository.errors.add(:url, :should_be_of_format_local, :format => "file://#{path}/<#{l(:label_repository_format)}>/")
          end
        end

        @repository.attributes = params[:repository]
        if @repository.errors.empty?
          @repository.root_url = @repository.url
          @repository.save
        end
      end
      
      edit_without_add
    end

  end

end
