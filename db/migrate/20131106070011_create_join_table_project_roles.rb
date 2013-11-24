class CreateJoinTableProjectRoles < ActiveRecord::Migration

  def change
    create_join_table :projects, :users do |t|
      t.index [:project_id, :user_id]
      t.integer :role
    end

  end

end
