class CreateLogPrint < ActiveRecord::Migration
  def self.up
    create_table :log_prints do |t|
      t.string :host
      t.string :idDoc
      t.string :document_type
      t.string :object_type
      t.timestamps
    end
  end

  def self.down
    drop_table :log_prints
  end
end
