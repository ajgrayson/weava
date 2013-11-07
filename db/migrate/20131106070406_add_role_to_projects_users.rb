class AddRoleToProjectsUsers < ActiveRecord::Migration

  class ProjectsUsers < ActiveRecord::Base
  end

  def change
    add_column :projects_users, :role, :int

    ProjectsUsers.reset_column_information

    reversible do |dir|
        dir.up do
           ProjectsUsers.update_all("role = 0")
        end
    end

  end
end
