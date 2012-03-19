class CreateLogPrintUsages < ActiveRecord::Migration
  def self.up
    create_table :log_print_usages do |t|
      t.string :idDoc
      t.timestamps
    end
  end

  def self.down
    drop_table :log_print_usages
  end
end
