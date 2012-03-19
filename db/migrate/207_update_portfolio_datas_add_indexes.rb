class UpdatePortfolioDatasAddIndexes < ActiveRecord::Migration
  
  def self.up
    add_index :portfolio_datas, :metadata_id, :unique => true
    add_index :portfolio_datas, :dc_identifier, :unique => true
  end
  
  
  
  def self.down
    remove_index :portfolio_datas, :metadata_id
    remove_index :portfolio_datas, :dc_identifier
  end
end