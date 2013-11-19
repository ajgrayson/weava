class CreateDeskProjects < ActiveRecord::Migration
  def change
    create_table :desk_projects do |t|
      t.integer :project_id
      t.string :access_token
      t.string :access_token_secret
      t.boolean :setup_complete

      t.timestamps
    end
  end
end
