class User::RegistrationsController < Devise::RegistrationsController
	protected
	
	def after_inactive_sign_up_path_for(resource)
		'/user/wait_confirm'
	end
end
