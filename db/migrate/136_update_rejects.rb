class UpdateRejects < ActiveRecord::Migration
  def self.up
    change_column(:rejects, :data, :text)
  end

  def self.down
    
  end
end