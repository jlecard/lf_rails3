class CreateLogMailExport < ActiveRecord::Migration
  def self.up
    create_table :log_mail_exports do |t|
      t.string :host
      t.string :idDoc
      t.string :document_type
      t.string :object_type
      t.timestamps
    end
  end

  def self.down
    drop_table :log_mail_exports
  end
end