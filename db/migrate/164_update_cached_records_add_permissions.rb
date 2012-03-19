class UpdateCachedRecordsAddPermissions < ActiveRecord::Migration
  def self.up
    add_column :cached_records, :id_perm,       :string
    add_column :cached_records, :id_role,       :string
    add_column :cached_records, :id_lieu,       :string
  end

  def self.down
    remove_column :cached_records, :id_perm
    remove_column :cached_records, :id_role
    remove_column :cached_records, :id_lieu
  end
end