class UpdatePortfolioDatasChangeIssues < ActiveRecord::Migration
  
  def self.up
	  change_column :portfolio_datas, :issues, :text
  end
  
  def self.down
	     
  end
  
end