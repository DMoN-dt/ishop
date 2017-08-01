class Document < AccessListModel
	self.abstract_class = true
	
	
	
	def self.pub_visible_safe_id_crc (id_str)
		
	end
	
	
	# Публичный ID документа - без хэша (на экран) или с хэшем (для общения с сервисами)
	def self.pub_visible_safe_id (doc_type = DOC_TYPE_SOME_DOC, doc_id = nil, doc_created_at_utc = nil, with_hash = true, is_partner_doc = false, for_pay_svc = false, hash_salt = nil, hash_seed = nil, with_shop_id = true)
		
		
	end
	
	
	def self.from_pub_visible_safe_id (pub_safe_id, pay_service_encoded = true, stop_on_bad_hash = true, hash_salt = nil, hash_seed = nil)
		
	end
	
	
	def self.name_wo_quotes (client_name, maxlength = 0)
		if(client_name.present?)
			if((client_name[0] == '"') && (client_name[-1] == '"')) or ((client_name[0] == '«') && (client_name[-1] == '»'))
				cli_name_len = client_name.length
				client_name = client_name[1,cli_name_len-2]
			end
			
			if(maxlength != 0) && (client_name.length > maxlength)
				client_name = (client_name[0,maxlength] + '...')
			end
		end
		return client_name
	end
	
	
	def self.name_wo_org_type (client_name, maxlength = 0, org_type)
		
	end
	
	
	def self.name_and_type_lite (name_maxlength = 0, fiz_lico_with_type = true, name_full, org_type)
		
	end
	
	
	def self.make_signature_fio (full_fio)
		
	end
	
	
	def self.make_lite_fio (full_fio)
		
	end
	
	
	def access_list
		return (defined?(self.acl) ? self.acl : nil)
	end
	
	
	def pub_visible_safe_id (doc_type = nil, doc_id = nil, doc_created_at_utc = nil, with_hash = true, is_partner_doc = false, for_pay_svc = false, hash_salt = nil, hash_seed = nil)
		
	end
	
end
