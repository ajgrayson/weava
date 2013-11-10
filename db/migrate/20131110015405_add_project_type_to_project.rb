class AddProjectTypeToProject < ActiveRecord::Migration
  def change
    add_column :projects, :project_type, :string

    reversible do |dir|
        dir.up do
            Project.all.each do |project|
                project.update!(:project_type => 'default')
            end
        end

        dir.down do |dir|
           Project.all.each do |project|
                project.update!(:project_type => nil)
            end
        end
    end

  end
end
