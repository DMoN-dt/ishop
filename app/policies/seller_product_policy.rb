class SellerProductPolicy < ApplicationPolicy
	
	def show?
		user.is_allowed_to_profile?
	end
	
	def show_archived?
		user.is_allowed_to_profile?
	end
	
	
	def images_add?
		if(user.is_allowed_to_ecommerce?)
			record.create_acl(user)
			if(record.has_access?([:edit]))
				return true
			end
		end
		return false
	end
	
	def images_delete?
		if(user.is_allowed_to_ecommerce?)
			record.create_acl(user)
			if(record.has_access?([:edit]))
				return true
			end
		end
		return false
	end
	
	def import?
		user.is_allowed_to_ecommerce?
	end
	
	def import_price?
		user.is_allowed_to_ecommerce?
	end
	
	def import_price_groups_save?
		user.is_allowed_to_ecommerce?
	end
	
	def import_price_products?
		user.is_allowed_to_ecommerce?
	end
	
	def import_price_products_save?
		user.is_allowed_to_ecommerce?
	end
	
	def update_with_suppliers?
		user.is_allowed_to_ecommerce?
	end
	
	def update_with_suppliers_save?
		user.is_allowed_to_ecommerce?
	end
	
end