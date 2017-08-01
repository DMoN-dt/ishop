class UserMailer < ApplicationMailer

	def welcome_email(user)
		if(user.email_not_temporary?)
			@user = user
			@user_name = user.get_name_for_email
			mail(to: @user.email, subject: I18n.t(:user_subj_welcome, scope: @@ts_bmail, tsite: GenSetting.PerSite_Text(:mail_subj_sitename, [:mails]))) {|format| format.html}
		end
	end
	
	
	def change_email_notify(user)
		if(user.email_not_temporary?)
			@user = user
			@user_name = user.get_name_for_email
			@unconfirmed_email = user.get_email_hidden_symbols(user.unconfirmed_email)
			mail(to: @user.email, subject: I18n.t(:user_subj_mail_change, scope: @@ts_bmail, tsite: GenSetting.PerSite_Text(:mail_subj_sitename, [:mails]))) {|format| format.html}
		end
	end


end
