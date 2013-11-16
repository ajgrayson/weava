class AddLastSyncDateToZendeskProject < ActiveRecord::Migration
  def change
    add_column :zendesk_projects, :last_sync_date, :datetime
  end
end
