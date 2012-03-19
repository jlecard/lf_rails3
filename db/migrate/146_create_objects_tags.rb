class CreateObjectsTags < ActiveRecord::Migration
  def self.up
    create_table :objects_tags do |t|
      t.column :tag_date,            :DateTime
      t.column :uuid,                :string,     :null => false
      t.column :tag_id,              :integer,     :null => false
      t.column :state,               :integer    
      t.column :state_manager,       :string
      t.column :state_date,          :DateTime,   :null => false
      t.column :last_modified_date,  :DateTime,   :null => false
      t.column :object,              :integer     
      t.column :object_id,           :string
      
    end
    
    
  end
  
  def self.down
    
    drop_table :objects_tags
    
  end
end
