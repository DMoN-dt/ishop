class UserPolicy < ApplicationPolicy
	
	def new?
		user.is_admin_or_usersmoder? && user.is_allowed_to_profile?
	end
	
	def create?
		user.is_admin_or_usersmoder? && user.is_allowed_to_profile?
	end

	
	def index?
		show?
	end
	
	def show?
		((user.id == record.id) or user.is_admin_or_usersmoder?) && user.is_allowed_to_profile?
	end

	def destroy?
		((user.id == record.id) or user.is_admin_or_usersmoder?) && user.is_allowed_to_profile?
	end
	
	def profile_edit?
		((user.id == record.id) or user.is_admin_or_usersmoder?) && user.is_allowed_to_profile?
	end
	
	def profile_fill?
		((user.id == record.id) or user.is_admin_or_usersmoder?) && user.is_allowed_to_profile?
	end
	
	def payments?
		((user.id == record.id) or user.is_admin_or_usersmoder?) && user.is_allowed_to_profile?
	end
	
end