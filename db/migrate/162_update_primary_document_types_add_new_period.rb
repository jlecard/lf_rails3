class UpdatePrimaryDocumentTypesAddNewPeriod < ActiveRecord::Migration
  def self.up
    add_column :primary_document_types, :new_period, :integer
    pdt = PrimaryDocumentType.new
    pdt.name = 'None'
    pdt.new_period = 0
    pdt.save
  end

  def self.down
    remove_column :primary_document_types, :new_period
  end
end