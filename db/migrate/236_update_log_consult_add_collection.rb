class UpdateLogConsultAddCollection < ActiveRecord::Migration
  def self.up
    add_column :log_consults, :collection_id, :integer
  end

  def self.down
		remove_column :log_consults, :collection_id
  end
end
