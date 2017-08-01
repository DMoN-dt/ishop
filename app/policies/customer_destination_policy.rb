class CustomerDestinationPolicy < ApplicationPolicy
	
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
		user_allowed_to_customer?(user, record, [:edit])
	end
	
	
	private
	
	def user_allowed_to_customer? (user, record, access_arr)
		if(user.is_allowed_to_profile?)
			customer = record.get_parent_customer
			if(!customer.nil?)
				customer.create_acl(user)
				return customer.has_access?(access_arr)
			end
		end
		return false
	end
	
end