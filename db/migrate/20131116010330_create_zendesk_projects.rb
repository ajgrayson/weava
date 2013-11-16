class CreateZendeskProjects < ActiveRecord::Migration
  def change
    create_table :zendesk_projects do |t|
      t.integer :project_id
      t.string :token

      t.timestamps
    end
  end
end
