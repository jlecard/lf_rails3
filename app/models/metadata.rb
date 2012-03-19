class Metadata < ActiveRecord::Base
  belongs_to :control
  belongs_to :collection
  has_many :volumes
  has_one :portfolio_data, :dependent => :destroy
end