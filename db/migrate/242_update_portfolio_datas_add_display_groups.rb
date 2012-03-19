class UpdatePortfolioDatasAddDisplayGroups < ActiveRecord::Migration
  
  def self.up
    add_column :portfolio_datas, :display_groups, :string
  end
  
  def self.down
    remove_column :portfolio_datas, :display_groups
  end
  
end