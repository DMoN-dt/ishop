class OrderPolicy < ApplicationPolicy
	
	def begin?
		user.is_allowed_to_profile?
	end
	
	def new?
		user.is_allowed_to_profile?
	end
	
	def express?
		user.is_allowed_to_profile?
	end
	
	def index?
		user.is_allowed_to_profile?
	end
	
	def show?
		if(user.is_allowed_to_profile?)
			record.create_acl(user)
			return (record.has_access?([:gen_some_access]))
		end
		return false
	end
	
	def delete?
		if(user.is_allowed_to_profile?)
			record.create_acl(user)
			return (record.has_access?([:delete]))
		end
		return false
	end
	
	def cancel?
		if(user.is_allowed_to_profile?)
			record.create_acl(user)
			return (record.has_access?([:cancel]))
		end
		return false
	end
	
	def change_delete_item?
		if(user.is_allowed_to_profile?)
			record.create_acl(user)
			return (record.has_access?([:edit, :cancel]))
		end
		return false
	end
	
	def change_delivery_charges?
		if(user.is_allowed_to_profile?)
			record.create_acl(user)
			return (record.has_access?([:edit]))
		end
		return false
	end
	
	def change_agree?
		if(user.is_allowed_to_profile?)
			record.create_acl(user)
			return (record.has_access?([:agree_accept]))
		end
		return false
	end
	
	def change_accept?
		if(user.is_allowed_to_profile?)
			record.create_acl(user)
			return (record.has_access?([:agree_accept]))
		end
		return false
	end
	
	

end