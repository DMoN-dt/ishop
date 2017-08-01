class Customer < AccessListModel
	has_one    :balance, :foreign_key => :id, :primary_key => :balance_id
	
	scope :order_by_usage, -> {order('use_count DESC, created_at DESC')}
	
	
	@@shstr_norm  = [...]
	@@shstr_shuff = [...]
	
	@partner = nil
	
	
	def self.compare_with_info (customer_id, hinfo)

		return true
	end
	
	
	def fill_info (hinfo)
		
	end
	
	
	def pub_name
		if(self.customer_type == CUSTOMER_TYPE_LEGAL)
			
		else
			
		end
		
	end
	
	
	def self.sorted_customers_list (user_id, customers_ids, current_customer_id)
		if(user_id.nil?)
			user_customers = Customer.where(id: customers_ids, is_deleted: false).order_by_usage.find_all
		else
			user_customers = Customer.where(id: customers_ids, user_id: user_id, is_deleted: false).order_by_usage.find_all
		end
		
		if(user_customers.present? && user_customers.first.present?)

		
		end
		return nil
	end
	
	
	def self.validate_required_params_before_create (pparams, emails_to_scram = nil)
		
		
		return {'status' => 'error', 'status_text' => err_json_text, 'bad_fields' => err_bad_fields, 'bad_reasons' => err_bad_fields_why }
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
	
	
	def self.contacts_mails_list (object)
		contacts_list = {}
		customer_contacts = object.customer_contacts
		if(customer_contacts.present?)
			skip = 0
			for i in 1..3
				
				
				break if(skip >= 2)
			end
		end
		return contacts_list
	end
	
	
	# кто подписан на уведомления о покупках
	def users_list_subscribed_to_purchase
		return {self.user_id => nil, 'customer' => Customer.contacts_mails_list(self)}
	end
	
	
	# кто подписан на уведомления об изменении информации о покупателе
	def users_list_subscribed_to_changes
		return {self.user_id => nil, 'customer' => Customer.contacts_mails_list(self)}
	end
	
	
	# кто может подтвердить разрешение на изменение информации о покупателе
	def users_list_can_confirm_changes
		return {self.user_id => nil, 'customer' => Customer.contacts_mails_list(self)}
	end
	
	
	
	## ======================================== ##
	##     ACL - Access List Rights Model       ##
	## ======================================== ##
	
	RIGHTS = {
		# Права покупателя:
		
	}
	
	def rights_list
		RIGHTS
	end
	
	#Verify the access after Main Rights verification
	def object_has_access? (rights, pAccessList = @rAcl)
		ret_access = pAccessList.user_is?([:admin, :super_admin, :moderator_users])
		if(!ret_access)
			ret_access = pAccessList.is_any_right?([:owner])
			
			if(!ret_access && self.user_id.present? && (self.user_id != 0))
				
			end
			
			if(!ret_access && self.partner_id.present? && (self.partner_id != 0))
				@partner = Partner.where(id: self.partner_id).first if(@partner.nil?)
				if(@partner.present?)
					
					
				end
			end
		end
		return ret_access
	end
	
	
	### =================================== PROTECTED ==========================================
	### ========================================================================================
	protected
	
	
	### ==================================== PRIVATE ===========================================
	### ========================================================================================
	private
end
