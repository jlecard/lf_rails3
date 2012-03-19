class UpdateNotices < ActiveRecord::Migration
  def self.up
    add_column(:notices, :document_type_id, :integer)
  end
  
  def self.down
    remove_column(:notices, :document_type_id)
  end
end
