class RenameProjectUsersTableToProjectRole < ActiveRecord::Migration
  def change
    rename_table :projects_users, :project_roles
  end
end
