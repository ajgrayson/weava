class RemoveUnusedProjects < ActiveRecord::Migration
  def change
    reversible do |dir|
        dir.up do
            unowned_projects = Project.where("owner = ?", false)
            unowned_projects.each do |project|
                project.destroy
            end
        end
    end
  end
end
