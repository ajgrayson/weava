class AddAcceptedToProjectShares < ActiveRecord::Migration
  def change
    add_column :project_shares, :accepted, :boolean
  end
end
