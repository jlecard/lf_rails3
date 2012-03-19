class CreateLinkingWord < ActiveRecord::Migration
  def self.up
    create_table :linking_word do |t|
      t.integer :id_historical_search
      t.string :word
      t.string :link_type, :default => nil
      t.string :query_type
    end
  end

  def self.down
    drop_table :linking_word
  end
end
