# $Id: user.rb 856 2007-03-15 21:15:46Z herlockt $

# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

require 'digest/sha1'


class User < ActiveRecord::Base
  
  validates_presence_of :name,
                        :password,
                        :password_confirmation,
                        :email
                        
                        
  validates_uniqueness_of :name
  
  validates_length_of   :password,
                        :minimum => 5,
                        :message => "Password should be at least five characters long"
                        
  attr_accessor :password_confirmation
  validates_confirmation_of :password

  
  def self.authenticate(name, password)
    user = self.find_by_name(name)
    if user
      expected_password = encrypted_password(password, user.salt)
      if user.hashed_password != expected_password
        user = nil
      end
    end
    user
  end

  def password
    @password
  end
  
  def password=(pwd)
    @password = pwd
    create_new_salt
    self.hashed_password = User.encrypted_password(self.password, self.salt)
  end
  
  
  private
  
  def self.encrypted_password(password, salt)
    # FIXME: parameterize this string
    string_to_hash = password + "beavers" + salt
    Digest::SHA1.hexdigest(string_to_hash)
  end 
   
  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end
   
    
end
