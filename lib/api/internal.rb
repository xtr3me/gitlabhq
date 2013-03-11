module Gitlab
  # Internal access API
  class Internal < Grape::API
    namespace 'internal' do
      #
      # Check if ssh key has access to project code
      #
      # Params:
      #   key_id - SSH Key id
      #   project - project path with namespace
      #   action - git action (git-upload-pack or git-receive-pack)
      #   ref - branch name
      #
      get "/allowed" do
        key = Key.find(params[:key_id]) rescue nil
        project = Project.find_with_namespace(params[:project])
        git_cmd = params[:action]

	if key.nil?
	  user = User.where(ssh_username: params[:key_id].gsub(/ssh\-/, "")).first
	end

        if !key.nil? && key.is_deploy_key
          project == key.project && git_cmd == 'git-upload-pack'
        else
          user = key.user if user.nil?

          return false if user.blocked?

          action = case git_cmd
                   when 'git-upload-pack'
                     then :download_code
                   when 'git-receive-pack'
                     then
                     if project.protected_branch?(params[:ref])
                       :push_code_to_protected_branches
                     else
                       :push_code
                     end
                   end

          user.can?(action, project)
        end
      end

      #
      # Discover user by ssh key
      #
      get "/discover" do
        key = Key.find(params[:key_id]) rescue nil
	if key.nil?
	  user = User.where(ssh_username: params[:key_id].gsub(/ssh\-/, "")).first
	  present user, with: Entities::User
	else
	  present key.user, with: Entities::User
	end
      end

      get "/check" do
        {
          api_version: Gitlab::API.version,
          gitlab_version: Gitlab::VERSION,
          gitlab_rev: Gitlab::REVISION,
        }
      end
    end
  end
end

