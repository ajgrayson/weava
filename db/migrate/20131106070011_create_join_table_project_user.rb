class CreateJoinTableProjectUser < ActiveRecord::Migration
  class Project < ActiveRecord::Base
  end

  class User < ActiveRecord::Base
  end

  class ProjectsUsers < ActiveRecord::Base
  end

  def change
    create_join_table :projects, :users do |t|
      t.index [:project_id, :user_id]
      # t.index [:user_id, :project_id]
    end

    Project.reset_column_information
    User.reset_column_information
    ProjectsUsers.reset_column_information

    reversible do |dir|
        dir.up do
            # Create join for all existing projects
            # and users
            User.all.each do |user|
                projects = Project.where("user_id = ?", user.id)
                projects.each do |project|
                    join = ProjectsUsers.new(
                        :project_id => project.id,
                        :user_id => user.id
                    )
                    join.save
                end
            end
        end
    end

  end

end
