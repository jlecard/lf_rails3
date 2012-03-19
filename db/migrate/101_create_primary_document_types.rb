class CreatePrimaryDocumentTypes < ActiveRecord::Migration
  def self.up
    create_table :primary_document_types do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :primary_document_types
  end
end
