class ApplicationMailer < ActionMailer::Base
	default from: "....", return_path: '.......'
	layout 'mailer'
	
	@@ts_bmail  = [:dt_breeze, :mails]
	@@ts_mail = [:dt_ishop, :mails]
	
	
	def add_contact_to_recipients (recipients_list, recipients_list_id, u_email, u_info)
		bExist = false
		recipients_list.each_value do |rc_info|
			
		end
		
		if(!bExist)
			recipients_list[recipients_list_id] = {email: u_email, name: u_info[:name], email_confirmed: u_info[:email_confirmed]}
			if(!u_info[:contact_type].nil?)
				
			end
			
			if(recipients_list[recipients_list_id][:email_confirmed] != true)
				
			end
			recipients_list_id += 1
		end
		
		return recipients_list_id
	end
	
	
	def get_recipients_list(users_list, allow_not_confirmed_contacts = false)
		recipients_list = {}
		need_query_db = []
		
		# Собрать user_id без наличия инфы о User
		users_list.each_pair do |user_id, user|
			
		end

		nn = 0
		if(need_query_db.present?)
			
		end
		
		check_emails = {}
		users_list.each_pair do |user_id, user|
			if(!user_id.is_a?(String) or user_id.numeric?)
				
			else
				if(user_id == 'customer') or (user_id == 'partner')
					user.each_pair do |u_email, u_info|
						
					end
					
				elsif((user_id == 'users') && user.present?)
					user.each do |u_info|
						
					end
				end
			end
		end

		if(check_emails.present?)
			emails = ContactEmail.confirmations(allow_not_confirmed_contacts, check_emails, true)
			if(allow_not_confirmed_contacts or !emails.nil?)
				check_emails.each_pair do |u_email, u_info|
					nn = add_contact_to_recipients(recipients_list, nn, u_email, u_info)
				end
			end
		end

		return recipients_list
	end

end