class DocumentPolicy < ApplicationPolicy
	def show?
		user.is_allowed_to_profile?
	end
end