class AddConflictToProject < ActiveRecord::Migration
  def change
    add_column :projects, :conflict, :boolean
  end
end
