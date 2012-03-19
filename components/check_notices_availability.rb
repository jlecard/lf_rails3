RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
ENV['ENV_HARVESTING'] = "true"
if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'

class CheckNoticesAvailability
  include ApplicationHelper
  
  EMAIL_FROM = "alerte.bpi@bpi.fr"
  
  def initialize()
    super
    if(@logger.nil?)
      @logger = ActiveRecord::Base.logger
    end
  end
  
  def checkAndSendAlerts()
 
    @logger.debug("[CheckNoticesAvailability][checkAndSendAlerts]")
    
    # Collections to fetch
    collections = getCollectionsToCheck()
    ph = PortfolioHarvester.new
    collections.each do |col|
      # Get notices by collection from notices_checks
      notices = NoticesCheck.getNoticesByCollection(col.doc_collection_id)
      
      @logger.debug("[CheckNoticesAvailability][checkAndSendAlerts] notices = #{notices.inspect} ")
      
      docs_to_check = []
      notices.each do |doc|
        docs_to_check << doc.doc_identifier
      end
      # Filter collection_docs to get only notices available
      docs_available = ph.checkCollectionRecordsAvailability(col.doc_collection_id, docs_to_check)
      
      @logger.debug("[CheckNoticesAvailability][checkAndSendAlerts] docs_available = #{docs_available.inspect} ")
      
      # For each notice available, send mail to users subscribed
      docs_available.each do |doc|
        # Get users subscribed for this doc
        doc_id = "#{doc}#{ID_SEPARATOR}#{col.doc_collection_id}"
        uuids = Subscription.getUsersByNotice(doc_id)
        @logger.debug("------------------- : #{uuids.size}")
        if(!uuids.nil? and uuids.size > 0)
          @logger.debug("[CheckNoticesAvailability][checkAndSendAlerts] Users to be notified for doc_id #{doc_id} : #{uuids.inspect} ")
          to = []
          uuids.each do |uuid|
            to << uuid unless !uuid.match(/@/)
          end
          
          doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(doc_id);
          cote = ""
          volumes = Volume.find(:all, :conditions=>{:dc_identifier=>doc_identifier, :collection_id=>doc_collection_id})
          if !volumes.nil?
            volumes.each do |volume|
              cote += ", #{volume.call_num}"
            end
          end
          cote = cote.gsub(/^, /, "")
          metadatas = Metadata.find(:first, :conditions=>{:dc_identifier=>doc_identifier, :collection_id=>doc_collection_id})
          if !metadatas.nil?
            title = metadatas.dc_title
            author = metadatas.dc_creator
            date = metadatas.dc_date
          end
          
          subject = translate("SUBJECT_ALERT", nil, nil, "mail")
          
          message = translate("BODY_ALERT_BEGIN", nil, nil, "mail")
          if (!title.blank?)
            message =  message + translate("TITLE_FIELD", [title], nil, "mail")
          end
          if (!author.blank?)
            message =  message + translate("AUTHOR_FIELD", [author], nil, "mail")
          end
          if (!date.blank?)
            message =  message + translate("DATE_FIELD", [date], nil, "mail")
          end
          if (!cote.blank?)
            message =  message + translate("COTE_FIELD", [cote], nil, "mail")
          end
          message = message + translate("FOOTER", nil, nil, "mail")
          begin
            Emailer.generateMail(to, subject, message, from = EMAIL_FROM)
          rescue Net::SMTPFatalError => e
            @logger.error("Notification not sent to recipient #{to}: #{e.message}")
          rescue Exception => e
            @logger.error("Error sending notification to #{to}: #{e.message}")
          end
          # Update state for subscriptions
          users = uuids.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
          Subscription.update_all(" state = #{SUBSCRIPTION_NOTIFIED} , change_state_date = '#{DateTime.now}' , send_mail_date = '#{DateTime.now}' " , " uuid in #{users} and object_uid = '#{doc_id}' ")
        end
      end      
    end
    # Update check_date for all active subscriptions
    Subscription.update_all(" check_date = '#{DateTime.now}' " , " state = #{SUBSCRIPTION_ACTIVE} ")
    
  end
  
  def getCollectionsToCheck()
    collections = NoticesCheck.find_by_sql("SELECT DISTINCT(doc_collection_id) from notices_checks ")
    @logger.debug("[CheckNoticesAvailability][getCollectionsToCheck] Collections to check : #{collections.size} ")
    return collections
  end
  
  
end

cn = CheckNoticesAvailability.new

cn.checkAndSendAlerts()
