class PaymentPolicy < ApplicationPolicy
	def pay?
		user.is_allowed_to_profile?
	end
end