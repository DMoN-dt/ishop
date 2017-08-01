class AccessList
	
	RIGHTS = {
		# Права общие:
		:gen_some_access => 0, # Сам доступ к объекту (видно что такое, тип, номер, ещё что-то общее)
		:view_creation_data => , # Просмотр информации о создании/размещении объекта (когда, кем)
		:view_history_data => , # Просмотр истории объекта, комментариев и событий

		:subscribed_to_changes => , # Отслеживание изменений объекта (получать сообщения)
		:this_allow_over_prev_denies => , # Приоритет данных разрешений над предыдущими запретами
	}
	
	
	def rmask_has?(rmask, test)
		rights(rmask).include?(test.to_sym)
	end
	
	def rights (rmask)
		RIGHTS.reject {|rk,rv| ((rmask.to_i || 0) & 2**rv).zero?}
	end
	
	def is_any_right? (rights)
		test_mask = AccessList.calc_roles_mask(rights)
		return (self.has_access?(test_mask, true))
	end

	def self.calc_rights_mask (rights)
		return (rights & RIGHTS.keys).map {|rk| 2**RIGHTS[rk]}.inject(0, :+)
	end
	
	
	def self.create_url_sid (id, id_uniq, acc_types, user_id_scram, access_mask)
		
		return URI.encode_www_form('sid' => sid_str)
	end
	
	
	def self.read_url_sid (sid_str)
		
	
	end
	
	
	#####################################
	## INSTANCE FUNCTIONS AND VARIABLES #
	#####################################
	
	@@def_acl = {
		int: true,
		anyone: {with_password: true, deny: 0xFFFFFFFF, allow: 0, allow_pay: false},
		users:  {with_password: true, deny: 0xFFFFFFFF, allow: 0, allow_pay: false},
		auser:  {with_password: true, deny: 0xFFFFFFFF, allow: 0, allow_pay: false, id: 0},
		users_list: {}
	}
	
	
	@@empty_acl = {
		int: true,
		anyone: {deny: 0, allow: 0},
		users:  {deny: 0, allow: 0},
		auser:  {deny: 0, allow: 0, id: 0},
		users_list: {}
	}

	
	def set_default_acl
		@obj_acl = nil
		@url_acl = nil
		@acl = @@def_acl
		
		@acl_arr = []
	end
	
	
	def initialize (is_signed_user = false, user = nil)
		set_user(is_signed_user, user)
		set_default_acl
	end
	
	
	def set_user (is_signed_user, current_user)
		if(is_signed_user)
			
		else
			@def_user = nil
			@def_user_id = 0
		end
	end
	

	def from_URL! (access_params)
		if(access_params.present?)
			@url_acl = access_params
			return true
		end
		return false
	end
	
	
	def from_Object (object)
		if(object.present?)
			
		else
			obj_acl = nil
		end
		return obj_acl
	end
	
	
	def from_Object! (object, position_last = true)
		obj_acl = from_Object(object)
		if(obj_acl.present?)
			
		end
		return false
	end
	
	
	def update_from_Object! (object, position_last = true)
		self.from_Object!(object)
		self.update_acl!
	end
	
	
	def remove_URL! (position_last = true)
		if(!@url_acl.nil?)
			@url_acl = nil
			self.update_acl!
		end
	end
	
	
	def update_acl_section_rights (pAcl_section, pNewAcl_section, bInt)
		
		
		pAcl_section[:allow] |= allow_mask

		if(rmask_has?(allow_mask, :this_allow_over_prev_denies))
			pAcl_section[:deny]  &= ~allow_mask
		end
		pAcl_section[:deny] |= deny_mask
	end
	
	
	def update_acl_section (acl, new_acl, section_name)
		
		
	end
	
	
	def update_with_acl (acl = nil, new_acl)
		acl = @@empty_acl if(acl.nil?)
		if(new_acl.present?)
			[:anyone, :users, :auser, :users_list].each do |section_name|
				update_acl_section(acl, new_acl, section_name)
			end
		end
	end
	

	def update_acl!
		acl = @@empty_acl
		@acl_arr.each do |acl_item|
			update_with_acl(acl, acl_item)
		end
		update_with_acl(acl, @url_acl)
		@acl = acl
	end
	
	
	def acl_over_default_acl (acl)
		result_acl = @@def_acl
		
		result_acl.each_pair do |section, section_acl|
			if(!acl[section].nil?)
				if(!section_acl.nil? && section_acl.is_a?(Hash))
					
					
				end
			end
		end
		
		return result_acl
	end
	
	
	def has_access_right? (test_right, acl = @acl, user_id = @def_user_id)
		if(!acl[:anyone].nil?)
			
		end
		if(user_id != 0)
			
		end
		
		return false
	end
	
	
	def has_access? (rmask, first_match = false, acl = @acl, user_id = @def_user_id)
		# совмещать в одну маску только общие права
		# остальные - опрашивать по цепочке с проверкой имени модели и опрашивающей, опрашивать через модель
		some_access = AccessList.calc_rights_mask([:gen_some_access])
		
		if(!first_match)
			rmask |= some_access
			deny_test = rmask
		else
			deny_test = rmask | some_access
		end
		
		allow_need = rmask
		
		if(!acl[:anyone].nil?)
			
		end
		
		if(user_id != 0)
			
		end

		return false
	end
	
	
	def access_with_password?
		false
	end
	
	
	def user_is? (roles)
		return false if(@def_user.nil?)
		return @def_user.is_any_role?(roles)
	end
	
	
	def user
		return @def_user
	end

	
	private
	
end