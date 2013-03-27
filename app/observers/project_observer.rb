class ProjectObserver < BaseObserver
  def after_create(project)
    GitlabShellWorker.perform_async(
      :add_repository,
      project.path_with_namespace
    )

    log_info("#{project.owner.name} created a new project \"#{project.name_with_namespace}\"")
  end
  
  def after_save(project)
    UsersProject.add_users_into_projects([project.id], (User.all - project.users - [project.creator]).map(&:id), UsersProject::MASTER)
  end

  def after_update(project)
    project.send_move_instructions if project.namespace_id_changed?
  end

  def after_destroy(project)
    GitlabShellWorker.perform_async(
      :remove_repository,
      project.path_with_namespace
    )

    GitlabShellWorker.perform_async(
      :remove_repository,
      project.path_with_namespace + ".wiki"
    )

    project.satellite.destroy

    log_info("Project \"#{project.name}\" was removed")
  end
end
