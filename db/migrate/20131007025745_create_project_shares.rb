class CreateProjectShares < ActiveRecord::Migration
  def change
    create_table :project_shares do |t|
      t.integer :project_id
      t.integer :owner_id
      t.integer :user_id
      t.string :code

      t.timestamps
    end
  end
end
