class AccessListModel < ApplicationRecord
	self.abstract_class = true
	
	## ======================================== ##
	##     ACL - Access List Rights Model       ##
	## ======================================== ##
	
	RIGHTS = {}
	
	def rights_list
		RIGHTS
	end
	
	# Return Integer Bit-Mask from Rights array
	def calc_rights_mask (rights)
		oRights = self.rights_list
		return (((rights & oRights.keys).map {|rk| 2**oRights[rk]}.inject(0, :+)) + AccessList.calc_rights_mask(rights))
	end
	
	# Create internal ACL for record
	def create_acl (user)
		@rAcl = AccessList.new(!user.nil?, user)
		@rAcl.update_from_Object!(self)
	end
	
	
	def ensure_acl_exist (user)
		create_acl(user) if(@rAcl.blank?)
	end
	
	
	# Create internal ACL for record
	def acl_get
		return @rAcl
	end
	
	
	# Return ACL for AccessList
	def access_list
		
	end
	
	
	# Verify the access of a General Rights only
	def has_access? (rights, pAccessList = @rAcl)
		
		return allow_access
	end
	
	
	def acl_set_and_merge (acl)
		if(!acl.nil?) && (acl.is_a?(AccessList))
			@rAcl = acl
			@rAcl.update_from_Object!(self)
		end
	end
	
	
	### =================================== PROTECTED ==========================================
	### ========================================================================================
	protected
	
	
	### ==================================== PRIVATE ===========================================
	### ========================================================================================
	private

end
