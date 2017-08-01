class SellerSuppliersProductsInfo < ApplicationRecord
	#has_one    :seller_supplier, :foreign_key => [:seller_id, :seller_supplier_id], :primary_key => [:seller_id, :seller_supplier_id]
	#has_many   :seller_suppliers_products, :foreign_key => [:seller_id, :seller_supplier_id, :seller_supplier_prod_id], :primary_key => [:seller_id, :seller_supplier_id, :seller_supplier_prod_id]
	
	def self.update_info (upd_params, seller_id, seller_supplier_id, seller_supplier_prod_id, seller_prod_id, name, prod_code, seller_prod_brand_id, prod_info)
		need_save = false
		saved_ok = false
		
		prodi = SellerSuppliersProductsInfo.where(seller_id: seller_id, seller_supplier_id: seller_supplier_id, seller_supplier_prod_id: seller_supplier_prod_id).first
		if(prodi.blank?)
			if(name.present?) # Skip products without name
				
			end
			found_exist = false
		else
			found_exist = true
		end
		
		if(prodi.present?)
			
			
		end
	end
	
	
	def self.update_seller_links (upd_params, seller_id, seller_supplier_id, find_broken_links = false, create_seller_prods = false, not_create_disappeared = true)
		return if(seller_id.nil?)
		
		seller_id_s = seller_id.to_s
		seller_supplier_id_s = seller_supplier_id.to_s if(!seller_supplier_id.nil?)

		if(find_broken_links)
			# Attention! This lossed products could be need a deletion, not re-inserting
			sql = "UPDATE seller_suppliers_products_infos AS sspi SET seller_prod_id = NULL, no_seller_prod = TRUE  FROM seller_products AS sp WHERE (sspi.seller_id = " + seller_id_s + ")"
			sql += ' AND (sspi.seller_supplier_id = ' + seller_supplier_id_s + ')' if(!seller_supplier_id.nil?)
			sql += ' AND (sspi.seller_prod_id IS NOT NULL) AND (sspi.seller_prod_id != 0) AND (NOT EXISTS (SELECT id FROM seller_products AS sp WHERE sp.id = sspi.seller_prod_id))'
			
			upd_params[:nulled_notexist_seller_links] = ActiveRecord::Base.connection.update(sql)
		end
		
		# Try to Find seller's corresponding products for absent links
		
		upd_params[:updated_null_seller_links] = ActiveRecord::Base.connection.update(upd_null_sql)
		upd_params[:need_update_seller_links] = false if(upd_params[:updated_null_seller_links] != 0)
		
		# Create new Seller's Products
		if(create_seller_prods)
			
			upd_params[:created_new_seller_products] = ActiveRecord::Base.connection.update(sql)
			
			# Update supplier's links to new products
			upd_params[:new_seller_prods_null_updated] = ActiveRecord::Base.connection.update(upd_null_sql)
		end
		
		
	end
end
