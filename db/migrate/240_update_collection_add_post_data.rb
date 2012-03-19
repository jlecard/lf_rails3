class UpdateCollectionAddPostData < ActiveRecord::Migration
  def self.up
    add_column(:collections, :post_data, :string)
  end
  
  def self.down
    remove_column(:collections, :post_data)
  end
end
