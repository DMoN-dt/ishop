class CustomerDestination < AccessListModel
	
	def get_parent_customer
		
	end
	
	
	def erase_instead_of_delete
		if(self.addr.present?)
			
		end
		self.is_deleted = true
	end
	
	
	# ENCODED PAY-SERVICE ID WITH CRC HASH
	def static_pub_safe_uid (safeid_params = nil, uri_encode = false)
		
	end
	
	
	def self.prepare_make_safe_id
		
	end
	
	
	def self.pub_safe_uid(safeid_params, pid, gen_params_if_nil = false, uri_encode = false)
		
	end
	
	
	def self.from_safe_uid (pub_safe_id)
		
	end
end
