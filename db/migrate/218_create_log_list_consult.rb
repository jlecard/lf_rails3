class CreateLogListConsult < ActiveRecord::Migration
  def self.up
    create_table :log_list_consults do |t|
      t.integer :id_list
      t.string :title
      t.integer :nb_consult
      t.string :host
      t.timestamps
    end
  end

  def self.down
    drop_table :log_list_consults
  end
end