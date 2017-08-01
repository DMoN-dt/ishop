class CabinetPolicy < ApplicationPolicy
	
	def index?
		user.is_allowed_to_profile?
	end
	
	def orders?
		user.is_allowed_to_profile?
	end
	
	def discounts?
		user.is_allowed_to_profile?
	end
	
	def e_commerce?
		user.is_user_allowed_to_own_ecommerce?
	end
	
	def replace_products_images?
		user.is_user_allowed_to_own_ecommerce?
	end
	
	
	if(defined?(MARKETPLACE_MODE_ONLINE_SHOP) && (MARKETPLACE_MODE_ONLINE_SHOP != true))
	
		def customers?
			user.is_allowed_to_profile?
		end
		
		def sellers?
			user.is_allowed_to_profile?
		end
	end

end