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
class CommunityController < ActionController::Base
  
  # docs is Array(doc)
  # doc is "idDoc;idColl[;idSearch]"
  def copyNotices(docs)
    if !docs.nil? and !docs.empty?
      docs.each do |doc|
        copyNotice(doc)
      end
    end
  end
  
  def copyNotice(doc)    
    doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(doc)
    col = Collection.getCollectionById(doc_collection_id)
    if(!col.actions_allowed)
      return false
    end
    logger.debug("[CommunityController] copyNotice: doc=#{doc}")
    if !Notice.existsById?(doc)
      logger.debug("[CommunityController] copyNotice: doc=#{doc} get record ")
      record = $objDispatch.GetId(doc)
      if !record.nil?
        logger.debug("[CommunityController] copyNotice: doc=#{doc} add notice ")
        Notice.addOnlyNoExist(record)
        return true
      else
        logger.warn("[CommunityController] copyNotice: record #{doc} not found !!")
        return false
      end
    else
      logger.warn("[CommunityController] copyNotice: record #{doc} already exist !!")
      return true
    end
  end
  
end
