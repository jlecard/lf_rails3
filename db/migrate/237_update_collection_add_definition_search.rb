class UpdateCollectionAddDefinitionSearch < ActiveRecord::Migration
  def self.up
    add_column(:collections, :definition_search, :string, :default => "creator=1003;author=1003;subject=21;issn=8;isbn=7;callnum=16;publisher=1018;title=4;keyword=1016")
  end
  
  def self.down
    remove_column(:collections, :definition_search)
  end
end