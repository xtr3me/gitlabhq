class AddSshUsernameToUser < ActiveRecord::Migration
  def change
    add_column :users, :ssh_username, :string
  end
end
