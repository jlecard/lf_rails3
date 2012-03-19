# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Solution & Innovation
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
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com
#
# http://libraryfind.org
class LogMailUsage < ActiveRecord::Base
   
   def logMailed(qty = 20)
     begin
        log = LogMailUsage.find(:all, :limit => qty)
        if log.length == 0
          return nil
        else
          dates = Hash.new
          tmp = Hash.new
          months = {"1"=>"January","2"=>"February","3"=>"March","4"=>"April","5"=>"May",
                    "6"=>"June","7"=>"July","8"=>"August","9"=>"September",
                    "10"=>"October","11"=>"November","12"=>"December"}
          
          log.each do |item|
            
            formatDate = Time.parse(item.updated_at.to_s)
            mois = months[formatDate.month.to_s]
    
            if dates[formatDate.year.to_s] == nil
  #           L'annee n'existe pas
              dates[formatDate.year.to_s] = Hash.new
            end
            
            if dates[formatDate.year.to_s][mois] != nil
  #           Le mois dans l'année existe déjà  
              tmp[mois] = (dates[formatDate.year.to_s][mois]).to_i + 1
            else
  #           Le mois dans l'année n'existe pas
              tmp[mois] = 1
            end
            
            dates[formatDate.year.to_s].merge!(tmp)
            tmp.clear
                    
          end
          tmp = nil
        end
        return dates.sort
      rescue
        return nil
      end
    end

end
