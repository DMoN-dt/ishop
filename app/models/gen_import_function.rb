class GenImportFunction < ApplicationRecord
	has_many   :seller_suppliers, :foreign_key => :import_func_id, :primary_key => :id
	
	
	def hash_import_func_name (seller_id)
		
	end
	
	
	def is_valid_func_name_link? (seller_id, test_hash)
		hash = hash_import_func_name(seller_id)
		return (!hash.nil? && !test_hash.nil? && (hash == test_hash.to_i(16)))
	end
end
