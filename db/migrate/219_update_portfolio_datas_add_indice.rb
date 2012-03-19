class UpdatePortfolioDatasAddIndice < ActiveRecord::Migration
  
  def self.up
    add_column :portfolio_datas, :indice, :string
  end
  
  def self.down
    remove_column :portfolio_datas, :indice
  end
  
end