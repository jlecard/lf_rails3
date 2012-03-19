class UpdateCachedRecordsAddTotalHits < ActiveRecord::Migration
  def self.up
    add_column :cached_records, :total_hits, :integer, :default => 0
  end

  def self.down
    remove_column :cached_records, :total_hits
  end
end