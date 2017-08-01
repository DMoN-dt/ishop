class SellerSupplier < ApplicationRecord
	belongs_to :seller, :foreign_key => :id, :primary_key => :seller_id
	has_one    :gen_import_function, :foreign_key => :id, :primary_key => :import_func_id
	
	#has_many   :seller_suppliers_warehouses, :foreign_key => [:seller_id, :seller_supplier_id], :primary_key => [:seller_id, :seller_supplier_id]
	#has_many   :seller_suppliers_products, :foreign_key => [:seller_id, :seller_supplier_id], :primary_key => [:seller_id, :seller_supplier_id]
	#has_many   :seller_suppliers_products_info, :foreign_key => [:seller_id, :seller_supplier_id], :primary_key => [:seller_id, :seller_supplier_id]

	
	def visible_name (not_scrambled_name = true)
		if(not_scrambled_name)
			return ((self.name.present?) ? self.name : self.short_name.to_s)
		else
			return ((self.scram_name.present?) ? self.scram_name : ((self.name.present?) ? self.name : self.short_name.to_s))
		end
	end
	
	
	def self.visible_name (prod, not_scrambled_name = true)
		
	end
	
	
	def get_import_function (n_suffix)
		store_import_func_name if(@seller_import_fname.nil?)
		if(@seller_import_fname.present? && n_suffix.present?)
			return ('import_supplier_' + @seller_import_fname + '_' + n_suffix.to_s)
		end
		return nil
	end
	
	
	def store_import_func_name
		if(@seller_import_fname.nil?)
			if(self.import_func_id.present?)
				gen_func = GenImportFunction.where(id: self.import_func_id).first
				if(gen_func.present?)
					if(gen_func.is_valid_func_name_link?(self.seller_id, self.import_func_hash))
						@seller_import_fname = gen_func.func_name
					end
				end
			end
			@seller_import_fname = '' if(@seller_import_fname.nil?)
		end
	end
	
	
	def exec_import_function (n_suffix, params_arr)
		fn = get_import_function(n_suffix)
		if(!fn.nil?)
			begin
				
			rescue NameError => e
				err_fname = get_undef_method_name(e)
				err_fname = e.to_s if(err_fname.nil?)
            
				
			end
		else
			return {alert: I18n.t(:import_func_notfound, scope: ts_ecom), setts_err: true}
		end
		return nil
	end
	
	
	# ENCODED ID WITH CRC-HASH FOR SAFELY PUBLIC USAGE IN FORMS AND REQUESTS
	def self.prepare_make_safe_id
		
	end
	
	
	def self.pub_safe_uid(safeid_params, seller_id, supplier_id, uniq_params_below_limit = false, limit = 0, limit_test = 0)
		
	end

	
	def self.from_safe_uid (pub_safe_id)
		
	end
	
	
	def self.from_safe_uid_get_id (str_dec, n1, params = nil, delimiter = '-')
		
		
	end
	
	
	### =================================== PROTECTED ==========================================
	### ========================================================================================
	protected
	
	
	### ==================================== PRIVATE ===========================================
	### ========================================================================================
	private
	
	def get_undef_method_name (e)
		
	end

end
