class Emailer < ActionMailer::Base
  include ApplicationHelper
  
  def mail(recipient, subject, message, from, cc, sent_at = Time.now)
    @subject = subject
    @recipients = recipient
    @from = from
    @sent_on = sent_at
    @cc = cc
    @body["message"] = message
    @headers = {}
    @footer = translate("FOOTER", nil, nil, "mail")
  end
  
  def self.generateMail(to, subject, message, from = LIBRARYFIND_EMAIL_USER)
    begin
      logger.debug("[Emailer][generateMail] message : #{message}")
      logger.debug("[Emailer][generateMail] to : #{to.inspect} ")
      begin
        main_recipient = ""
        cc = []
        regex = Regexp.new('[\w\-_]+[\w\.\-_]*@[\w\-_]') #+\.[a-zA-Z\-_]{2,4}')
        to.each do |recipient|
          match = regex.match(recipient)
          if !match
            logger.error("Error in mail adress #{recipient} !!")
          else
            if main_recipient == ""
              main_recipient = recipient
            else
              cc << recipient 
            end
          end
        end
        
        logger.debug("[Emailer][generateMail] Sending mail : #{message} to users : #{main_recipient} and #{cc.inspect} ")
        
        Emailer.deliver_mail(main_recipient, subject, message, from, cc)
        
        logger.debug("[Emailer][generateMail] Deliver mail")
        return true
      rescue Timeout::Error => time
        logger.error("[Emailer][generateMail] Error sending mail #{time.message} !!")
      end
    end
  end
  
  
end
