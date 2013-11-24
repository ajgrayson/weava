class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.integer :user_id
      t.boolean :owner
      t.string :code
      t.boolean :conflict
      t.string :project_type
      t.timestamps
    end
  end
end
