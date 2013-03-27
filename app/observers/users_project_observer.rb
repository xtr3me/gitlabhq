class UsersProjectObserver < BaseObserver
  def after_commit(users_project)
    return if users_project.destroyed?
    Notify.delay.project_access_granted_email(users_project.id) if Settings.gitlab.send_grant_emails
  end

  def after_create(users_project)
    Event.create(
      project_id: users_project.project.id,
      action: Event::JOINED,
      author_id: users_project.user.id
    ) unless Settings.gitlab.disable_grant_events

    notification.new_team_member(users_project)
  end

  def after_update(users_project)
    notification.update_team_member(users_project)
  end

  def after_destroy(users_project)
    Event.create(
      project_id: users_project.project.id,
      action: Event::LEFT,
      author_id: users_project.user.id
    ) unless Settings.gitlab.disable_grant_events
  end
end
