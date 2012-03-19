class CreateLogConsults < ActiveRecord::Migration
  def self.up
    create_table :log_consults do |t|
      t.string :idDoc
      t.string :title
      t.integer :nb_consult
    end
  end

  def self.down
    drop_table :log_consults
  end
end
