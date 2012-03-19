class UpdatePortfolioDatasAddLastIssue < ActiveRecord::Migration
  
  def self.up
	  add_column :portfolio_datas, :issues, :string
  end
  
  def self.down
	  remove_column :portfolio_datas, :issues
  end
  
end