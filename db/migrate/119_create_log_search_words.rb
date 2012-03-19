class CreateLogSearchWords < ActiveRecord::Migration
  def self.up
    create_table :log_search_words do |t|
      t.string :word
      t.string :request
      t.integer :nb_consult
      t.timestamps
    end
  end

  def self.down
    drop_table :log_search_words
  end
end
