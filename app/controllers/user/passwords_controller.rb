include Recaptcha::Verify

class User::PasswordsController < Devise::PasswordsController
	prepend_before_action :check_captcha, only: [:create]
	
	private
	
	def check_captcha
		unless verify_recaptcha secret_key: GOOGLE_RECAPTCHA_API_KEY_SECRET
			self.resource = resource_class.new
			respond_with_navigational(resource) { render :new }
		end
	end
end