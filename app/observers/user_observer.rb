class UserObserver < ActiveRecord::Observer
  def after_create(user)
    log_info("User \"#{user.name}\" (#{user.email}) was created")

    Notify.delay.new_user_email(user.id, user.password)
  end

  def after_destroy user
    log_info("User \"#{user.name}\" (#{user.email})  was removed")
  end

  def after_save user
    if user.username_changed?
      if user.namespace
        user.namespace.update_attributes(path: user.username)
      else
        user.create_namespace!(path: user.username, name: user.username)
      end
    end
    
    #UsersProject.user_bulk_import(user, Project.all.map(&:id), UsersProject::MASTER)
    UsersProject.add_users_into_projects(Project.all.map(&:id), [user.id], UsersProject::MASTER)
  end

  protected

  def log_info message
    Gitlab::AppLogger.info message
  end
end
