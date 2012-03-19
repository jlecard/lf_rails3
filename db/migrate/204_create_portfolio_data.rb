class CreatePortfolioData < ActiveRecord::Migration
  def self.up
    create_table :portfolio_datas do |t|
      t.column :dc_identifier, :string
      t.column :isbn, :string
      t.column :issn, :string
      t.column :call_num, :string
      t.column :last_issue, :string
      t.column :audience, :string
      t.column :genre, :string
      t.column :publisher_country, :string
      t.column :copyright, :string
      t.column :display_group, :string
      t.column :broadcast_group, :string
      t.column :license_info, :string
      t.column :commercial_number, :string
      t.column :binding, :string
      t.column :theme, :string
      t.column :metadata_id, :int
      t.column :is_available, :boolean
    end
    add_index :portfolio_datas, [:dc_identifier, :metadata_id], :unique=>true
    add_index :portfolio_datas, :call_num
  end
  
  
  
  def self.down
    remove_index :portfolio_datas, [:dc_identifier, :metadata_id]
    drop_table :portfolio_datas
  end
end