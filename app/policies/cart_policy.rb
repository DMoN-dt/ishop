class CartPolicy < ApplicationPolicy
	
	def show?
		user.is_allowed_to_profile?
	end
	
	def change_item?
		user.is_allowed_to_profile?
	end
	
	def delete_item?
		user.is_allowed_to_profile?
	end
	
	def is_in_cart?
		user.is_allowed_to_profile?
	end
	
end