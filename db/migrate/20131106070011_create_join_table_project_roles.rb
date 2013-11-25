class CreateJoinTableProjectRoles < ActiveRecord::Migration

  def change
    create_table :project_roles, id: false do |t|
      t.integer :project_id
      t.integer :user_id
      t.integer :role
      t.index [:project_id, :user_id]
    end

  end

end
