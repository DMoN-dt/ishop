include Recaptcha::Verify

class User::SessionsController < Devise::SessionsController
	prepend_before_action :check_captcha, only: [:create]

	private
	
	def check_captcha
		unless verify_recaptcha secret_key: GOOGLE_RECAPTCHA_API_KEY_SECRET
			redirect_to new_user_session_path
			return
		end 
	end
end
