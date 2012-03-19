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
module DocumentHelper
  def moreInfo(isbn)
    webService = ElectreWebservice.new(ActiveRecord::Base.logger);
    
    @moreImage = "";
    if (webService.image?(isbn))
      @moreImage = '<img src="/electre_webservice/show_image/' + isbn + '" />'
    end
    @moreQuatrieme = webService.back_cover(isbn)
    @moreTdm = webService.table_of_contents(isbn)
    if (@moreTdm != nil && @moreTdm != '')
      @moreTdm = @moreTdm.inspect
      @moreTdm = @moreTdm.gsub(/\\n/, '')
       (1..10).each do |i|
        if ((@moreTdm.index(/level=\\"#{i}\\"/)) != nil)
          @moreTdm = @moreTdm.gsub(/level=\\"#{i}\\"/, 'class="levelUp'+i.to_s+'"')
        end
      end
    end
  end
end
