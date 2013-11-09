class MigrateProjectUsers < ActiveRecord::Migration
  def change
    Project.reset_column_information
    User.reset_column_information
    ProjectsUsers.reset_column_information

    reversible do |dir|
        dir.up do
            ProjectsUsers.delete_all

            owned_projects = Project.where("owner = ?", true)
            owned_projects.each do |project|
                ProjectsUsers.create!(
                    :project_id => project.id,
                    :user_id => project.user_id,
                    :role => 0)
            end

            unowned_projects = Project.where("owner = ?", false)
            unowned_projects.each do |project|
                original_project = Project.where("code = ? and owner = ?", 
                    project.code, true).first

                ProjectsUsers.create!(
                    :project_id => original_project.id,
                    :user_id => project.user_id,
                    :role => 1)
                #project.destroy
            end
        end
    end
  end
end
