class CreateZendeskProjects < ActiveRecord::Migration
  def change
    create_table :zendesk_projects do |t|
      t.integer :project_id
      t.string :token
      t.datetime :last_sync_date
      t.timestamps
    end
  end
end
