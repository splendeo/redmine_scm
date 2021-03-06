require_dependency 'project'

module ScmProjectPatch

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable

      safe_attributes 'scm' unless Redmine::VERSION::MAJOR == 1 && Redmine::VERSION::MINOR == 0 # Redmine 1.0.x

      validates_presence_of :scm, :if => Proc.new { ScmConfig['auto_create'] == 'force' }

      validate :repository_exists

      after_create :create_scm

      def scm=(type)
        @scm = type
      end

      def scm
        @scm
      end
    end
  end

  module ClassMethods
  end

  module InstanceMethods

    def create_scm
      if @scm.present? && ScmConfig['auto_create']
        @repository = Repository.factory(@scm)
        if @repository
          @repository.project = self

          if @scm == 'Subversion'
            svnconf = ScmConfig['svn']
            path = Redmine::Platform.mswin? ? "#{svnconf['path']}\\#{self.identifier}" : "#{svnconf['path']}/#{self.identifier}"
            if File.directory?(path)
              RAILS_DEFAULT_LOGGER.warn "Automatically using reporitory: #{path}"
            else
              RAILS_DEFAULT_LOGGER.info "Automatically creating SVN reporitory: #{path}"
              args = [ svnconf['svnadmin'], 'create', path ]
              if svnconf['options']
                if svnconf['options'].is_a?(Array)
                  args += svnconf['options']
                else
                  args << svnconf['options']
                end
              end
              if system(*args)
                @repository.created_with_scm = true
              else
                RAILS_DEFAULT_LOGGER.error "Repository creation failed"
              end
            end
            path.gsub!(%r{\\}, "/") if Redmine::Platform.mswin?
            @repository.url = "file://#{path}"
          end

          @repository.root_url = @repository.url
          @repository.save
        end
      end
    end

    def repository_exists
      if @scm.present? && self.identifier.present? && ScmConfig['auto_create'] && @scm == 'Subversion'
        svnconf = ScmConfig['svn']
        path = Redmine::Platform.mswin? ? "#{svnconf['path']}\\#{self.identifier}" : "#{svnconf['path']}/#{self.identifier}"
        if File.directory?(path)
          errors.add_to_base(:repository_exists_for_identifier)
        end
      end
    end
  end
end
