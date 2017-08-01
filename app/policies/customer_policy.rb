class CustomerPolicy < ApplicationPolicy
	
	def index?
		user.is_allowed_to_profile?
	end
	
	def new?
		user.is_allowed_to_profile?
	end
	
	def create?
		user.is_allowed_to_profile?
	end
	
	def show?
		user_allowed_to_customer?(user, record, [:gen_some_access])
	end
	
	def edit?
		user_allowed_to_customer?(user, record, [:edit])
	end
	
	def update?
		user_allowed_to_customer?(user, record, [:edit])
	end
	
	def destroy?
		user_allowed_to_customer?(user, record, [:delete])
	end
	
	
	private
	
	def user_allowed_to_customer? (user, record, access_arr)
		if(user.is_allowed_to_profile?)
			record.create_acl(user)
			return record.has_access?(access_arr)
		end
		return false
	end
	
end