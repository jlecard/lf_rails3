class UpdatePortfolioDatasAddBulletinage < ActiveRecord::Migration
  
  def self.up
	  add_column :portfolio_datas, :issue_title, :string
	  add_column :portfolio_datas, :conservation, :string
  end
  
  def self.down
	  remove_column :portfolio_datas, :issue_title
	  remove_column :portfolio_datas, :conservation
  end
  
end