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
class LogGeneric < ActionController::Base
  include ApplicationHelper
   class StatLogger < Logger
    def format_message(severity, timestamp, progname, msg)
      "#{Time.now()}$#{msg}\n" 
    end
  end
  @@logFile = StatLogger.new(LOG_FILE_LOCATION + LOG_NAME_FILE, 1);
  def self.add(className, items)
    begin
      log = eval("#{className}.new")
      items.each do |key, value|
        eval("log.#{key} = value")
      end
      log.save!
      return true
    rescue => e
      logger.error("[LogGeneric] [add] Error: #{e.message}");
      return false
    end
  end
  
  def self.addToFile(className, items)
    logger.debug("[LogGeneric][addToFile] classname : #{className} items : #{items.inspect}");
    begin
      @@logFile.info(className + "$" + items.inspect() + "\n");
    rescue
      logger.error("[LogGeneric] [addToFile] failed to save data into file");
    end
  end
  
  def self.fileToDatabase()
    FileUtils.mv("logGeneric.txt", "logSave.txt");
  end
end
