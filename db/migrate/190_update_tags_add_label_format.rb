class UpdateTagsAddLabelFormat < ActiveRecord::Migration
  def self.up
    add_column :tags, :label_format, :string
    
    begin
      tags = Tag.find(:all)
      tags.each do |tag|
        tag.label_format = UtilFormat.remove_accents(tag.label).downcase
        tag.save!
      end
    rescue => e
      puts "error : #{e.message}"
    end
    
  end
  
  def self.down
    remove_column :tags, :label_format
  end
end