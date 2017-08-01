INN_crc12_n2 = [7,2,4,10,3,5,9,4,6,8]
INN_crc12_n1 = [3,7,2,4,10,3,5,9,4,6,8]
INN_crc10_n  = [2,4,10,3,5,9,4,6,8]

class Codes_Checks
	def self.org_type_detect_byname (org_name)
		org_type = nil
		name_length = org_name.length
		str_length = 4
		if(name_length > str_length)
			str = UnicodeUtils.upcase(org_name[0,str_length])
			ORGANIZATION_TYPES.each do |oid, odata|
				
				
			end

			if((org_type.nil?) && (name_length > 20))
				str_length = ((name_length > 40) ? 40 : name_length)
				str = UnicodeUtils.downcase(org_name[0,str_length])
				ORGANIZATION_TYPES.each do |oid, odata|
					
					
				end
			end
		end
		
		return org_type
	end
	
	def self.check_ogrn_crc (org_type, ogrn)
		return false if(ogrn.nil?)
		if(org_type == ORGANIZATION_TYPE_IND_PREDP)
			return false if(ogrn.length != 15)
			
		else
			return false if(ogrn.length != 13)
			
		end
	end
	
	def self.check_inn_crc (org_type, inn)
		return false if(inn.nil?)
		if(org_type == ORGANIZATION_TYPE_IND_PREDP)
			return false if(inn.length != 12)
			
		else
			return (false) if (inn.length != 10)
			
		end
		return false
	end
	
	def self.check_form_ogrn(org_type, ogrn, field_name = 'org_ogrn')
		err_bad_fields=[]
		err_bad_fields_why=[]
		err_json_text=nil
		
		if ogrn.blank?
			err_json_text = 'Не указан ОГРН юридического лица.'
			err_bad_fields << field_name
			err_bad_fields_why << 'e'
		
		elsif !ogrn.numeric?
			err_json_text = 'ОГРН должен состоять из цифр.'
			err_bad_fields << field_name
			err_bad_fields_why << 'b'
		
		elsif org_type.present?
			ogrn=ogrn.strip
			_len=ogrn.length
			if(org_type == ORGANIZATION_TYPE_IND_PREDP)

			else

			end
		end
		
		return {'err_bad_fields' => err_bad_fields, 'err_bad_fields_why' => err_bad_fields_why, 'err_json_text' => err_json_text}
	end
	
	
	def self.check_form_inn(org_type, inn, field_name = 'org_ogrn')
		err_bad_fields=[]
		err_bad_fields_why=[]
		err_json_text=nil
		
		if inn.blank?
			
		elsif inn.numeric? == false
			
		elsif org_type.blank? == false
			inn=inn.strip
			_len=inn.length
			if (org_type == ORGANIZATION_TYPE_IND_PREDP)
				
			elsif (org_type != ORGANIZATION_TYPE_IND_PREDP)
				
			end
		end
		
		return {'err_bad_fields' => err_bad_fields, 'err_bad_fields_why' => err_bad_fields_why, 'err_json_text' => err_json_text}
	end
	
	
	def self.check_form_kpp(org_type, kpp, field_name = 'org_kpp')
		err_bad_fields=[]
		err_bad_fields_why=[]
		err_json_text=nil
		
		if((org_type != ORGANIZATION_TYPE_IND_PREDP) && (org_type != ORGANIZATION_TYPE_FIZ_LICO))
			
		end
		
		return {'err_bad_fields' => err_bad_fields, 'err_bad_fields_why' => err_bad_fields_why, 'err_json_text' => err_json_text}
	end
	
	
	def self.check_bik_korr_shet(bik, korr_sh)
		err_bad_fields=[]
		err_bad_fields_why=[]
		err_json_text=nil
		
		
		
		return {'err_bad_fields' => err_bad_fields, 'err_bad_fields_why' => err_bad_fields_why, 'err_json_text' => err_json_text}
	end
end
