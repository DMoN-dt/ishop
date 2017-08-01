class SellerSuppliersProduct < ApplicationRecord
	#has_one      :seller_supplier, :foreign_key => [:seller_id, :seller_supplier_id], :primary_key => [:seller_id, :seller_supplier_id]
	#has_one      :seller_suppliers_products_info, :foreign_key => [:seller_id, :seller_supplier_id, :seller_supplier_prod_id], :primary_key => [:seller_id, :seller_supplier_id, :seller_supplier_prod_id]
	#has_many     :seller_suppliers_warehouses, :foreign_key => [:seller_id, :seller_supplier_id, :seller_supplier_wrh_id], :primary_key => [:seller_id, :seller_supplier_id, :seller_supplier_wrh_id]

	
	def self.update_in_warehouse (upd_params, seller_id, seller_supplier_id, seller_supplier_prod_id, seller_supplier_wrh_id, wrh_info, available_total, price, price_unit = nil, price_currency = nil)
		need_save = false
		saved_ok = false
		changes = {avail_delta: 0, avail_prev: 0, price_delta: 0, price_prev: 0}
		
		wprod = SellerSuppliersProduct.where(seller_id: seller_id, seller_supplier_id: seller_supplier_id, seller_supplier_prod_id: seller_supplier_prod_id, seller_supplier_wrh_id: seller_supplier_wrh_id).first
		if(wprod.blank?)
			# Skip products with zero or negative price and no availability info
			if(wrh_info.present?)
				
			
			elsif((seller_supplier_wrh_id == 0) && (available_total.present? or (!price.nil? && (price > 0))))
				
			end
				
			if(need_save)
				
			end
			found_exist = false
		else
			found_exist = true
		end	
		
		if(wprod.present?)
			
			end

			if(wrh_info.present?)
				
				
				if(wrh_info['avail_n'].present?)
					

				elsif(avail_text_changed)
					
				end

				if(!wrh_info['price_unit'].nil? && !wprod[:price_unit].nil? && (wprod[:price_unit] != 0) && (wrh_info['price_unit'] != wprod[:price_unit]))
					
				end

				if(wrh_info['price_curn'].nil?)
					
				end
				
				
			
			# No information now
			else
				
			end
			
			if(changed)
				wprod[:last_count_price_changes] = Time.now
				need_save = true
			end
			

			### Save existing or Create New
			if(need_save)
				
			elsif(found_exist)
				
			end
			
			
			### Statistics
			if(upd_params[seller_supplier_wrh_id].blank?)
				
			end
			
			if(found_exist)
				
			else
				upd_params[seller_supplier_wrh_id][:new_cnt] += 1
			end
			
			upd_params[seller_supplier_wrh_id][:imported_cnt] += 1
			
			if(saved_ok)
				upd_params[seller_supplier_wrh_id][:saved_cnt] += 1
				upd_params[seller_supplier_wrh_id][:existing_updated_cnt] += 1 if(found_exist)
			end
			
			if(found_exist or saved_ok)
				
			end
		end
	end
	
	
	def self.update_seller_links (upd_params, seller_id, seller_supplier_id)
		return if(seller_id.nil?)
		
		seller_id_s = seller_id.to_s
		seller_supplier_id_s = seller_supplier_id.to_s if(!seller_supplier_id.nil?)
		
		# Update links between Suppliers Warehouses and Seller Products through Suppliers Products Info

		upd_params[:updated_supp_warehouses_seller_links] = ActiveRecord::Base.connection.update(sql)
		
		if((upd_params[:some_supp_warehouses_wo_seller_link] or upd_params[:some_supp_warehouses_diff_seller_link]) && (upd_params[:updated_supp_warehouses_seller_links] != 0))
			cnt = 0
			upd_params.each do |wrh_id, wrh_info|
				if(wrh_id.is_a?(Integer) && !wrh_info.nil?)
					cnt += wrh_info[:no_link_prod_id_cnt] if(!wrh_info[:no_link_prod_id_cnt].nil?)
					cnt += wrh_info[:diff_link_prod_id_cnt] if(!wrh_info[:diff_link_prod_id_cnt].nil?)
				end
			end
			
			if(cnt <= upd_params[:updated_supp_warehouses_seller_links])
				upd_params[:updated_supp_warehouses_no_diff_links] = true
			end
		end
	end
	
end
