class DeviserMailer < Devise::Mailer
	layout 'mailer'
	
	rescue_from Net::SMTPFatalError, with: :dblog_critical
	rescue_from Net::SMTPAuthenticationError, with: :dblog_critical
	rescue_from Net::SMTPSyntaxError, with: :dblog_critical
	rescue_from Net::SMTPServerBusy, with: :dblog_critical
	
	
	private
	
	def dblog_critical (exception)
		ExceptionsLog.log_to_db(exception, 'Devise::Mailer', ((defined?(request)) ? request : nil), true)
	end
end