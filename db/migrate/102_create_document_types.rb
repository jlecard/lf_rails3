class CreateDocumentTypes < ActiveRecord::Migration
  def self.up
    create_table :document_types do |t|
      t.string :name
      t.string :document_type
      t.timestamps
    end
  end

  def self.down
    drop_table :document_types
  end
end
