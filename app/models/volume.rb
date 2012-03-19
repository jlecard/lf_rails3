class Volume < ActiveRecord::Base
  belongs_to :metadata
  belongs_to :collection
   
end