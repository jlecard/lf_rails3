class Control < ActiveRecord::Base
  has_many :metadata
  belongs_to :collection
end