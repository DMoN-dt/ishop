class ProductPricing_General
	
	def self.calc_price_for_sale (upd_params, force_calc, seller, seller_id, is_all_suppliers, suppliers, calc_instock, is_nulls_only, is_products_not_updated_only = true)
		params = verify_seller_and_suppliers(seller, seller_id, is_all_suppliers, suppliers)
		return false if(params.nil?)
		
		seller_id_s = params[:seller_id].to_s
		
		pricing_mode_lite = ((MARKETPLACE_SHOP && (GenSetting.pricing_mode == 0)) or (!MARKETPLACE_SHOP && (params[:seller].pricing_mode == 0)))
		is_products_not_updated_only_sql = (is_products_not_updated_only ? ' AND (sp.prices_upd_changed IS NULL) AND (sp.prices_upd_changing IS NOT NULL)' : '')
		is_products_not_updated_only_sql += ' AND (sp.prices_upd_math_id IS NOT NULL)' if(is_products_not_updated_only && !pricing_mode_lite)

		# Calculate Suppliers Prices (Lite ver.)
		if(params[:is_all_suppliers] or params[:suppliers_ids].present?)
			slr_pricing = (MARKETPLACE_SHOP ? GenSetting.pricing_multiplier_for_supplier_price.to_s : ' COALESCE(slr.pricing_supp_multiplier, 1)')
			supp_id_sql = (params[:is_all_suppliers]) ? '' : ' AND (ssp.seller_supplier_id = ANY(array' + params[:suppliers_ids].to_s + '))'
			check_calc_date_sql = (force_calc) ? '' : ' AND ((ssp.price_calc_at IS NULL) OR ( ssp.last_count_price_changes IS NULL) OR (ssp.price_calc_at < ssp.last_count_price_changes))'
			is_nulls_only_sql = (is_nulls_only ? ' AND (ssp.price_calc_1 IS NULL)' : '')
			
			
			sql = "UPDATE seller_suppliers_products AS ssp SET price_calc_1 = ((CASE WHEN (ssp.price_conv_cn IS NULL) OR 
 (ssp.price_conv IS NULL) THEN ssp.price ELSE ssp.price_conv END) * ssw.pricing_multiplier * sup.pricing_multiplier * " + slr_pricing + ") "
			sql += ", price_calc_at = NOW() " if(pricing_mode_lite)
			sql += " FROM seller_suppliers_products AS ssp2 \
 INNER JOIN seller_products 
 INNER JOIN seller_suppliers 
 INNER JOIN seller_suppliers_warehouses 
 INNER JOIN seller_products_groups 
 LEFT OUTER JOIN sellers AS slr ON (slr.id = ssp2.seller_id) \
 WHERE (ssp.seller_id = " + seller_id_s + ") " + supp_id_sql + is_nulls_only_sql + check_calc_date_sql + is_products_not_updated_only_sql + " AND (ssp2.id = ssp.id) AND sp.bactive AND sup.allow_import AND ((slr.id IS NULL) OR NOT(slr.blocked AND slr.deleted))"
			upd_params[:updated_seller_suppliers_prices] = ActiveRecord::Base.connection.update(sql)
			
			if(pricing_mode_lite)
				
				
			end
			
		end
		
		# Calculate In-stock Prices (Lite ver.)
		if(calc_instock)
			slr_pricing = (MARKETPLACE_SHOP ? GenSetting.pricing_multiplier_for_instock_price.to_s : ' COALESCE(slr.pricing_instock_multiplier, 1)')
			check_calc_date_sql = (force_calc) ? '' : ' AND ((spis.price_calc_at IS NULL) OR ( spis.last_count_price_changes IS NULL) OR (spis.price_calc_at < spis.last_count_price_changes))'
			is_nulls_only_sql = (is_nulls_only ? ' AND (spis.price_calc_1 IS NULL)' : '')
			
			sql = "UPDATE seller_products_in_stock AS spis SET price_calc_1 = ((CASE WHEN (spis.price_conv_cn IS NULL) OR 
 (spis.price_conv IS NULL) THEN spis.price ELSE spis.price_conv END) * swh.pricing_multiplier * " + slr_pricing + ") "
			sql += ", price_calc_at = NOW() " if(pricing_mode_lite)
			sql += " FROM seller_products_in_stock AS spis2 \
 INNER JOIN 
 INNER JOIN 
 INNER JOIN 
 LEFT OUTER JOIN sellers AS slr ON (slr.id = spis2.seller_id) \
 WHERE (spis.seller_id = " + seller_id_s + ") " + is_nulls_only_sql + check_calc_date_sql + is_products_not_updated_only_sql + " AND (spis2.id = spis.id) AND sp.bactive AND ((slr.id IS NULL) OR NOT(slr.blocked AND slr.deleted))"
			upd_params[:updated_seller_instock_prices] = ActiveRecord::Base.connection.update(sql)
			
			if(pricing_mode_lite)
				
			end
		end

		return true
	end
	
	
	def self.calc_products_prices (upd_params, seller, seller_id, is_all_suppliers, suppliers, is_nulls_only, force_recalc_wrh = false)
		params = verify_seller_and_suppliers(seller, seller_id, is_all_suppliers, suppliers)
		return false if(params.nil?)
		
		seller_id_s = params[:seller_id].to_s
		is_nulls_only_sql = (is_nulls_only ? ' AND (sp.prices_upd_changed IS NULL) AND ((sp.prices_upd_base_price IS NULL) AND (sp.prices_upd_base_price_cn IS NULL))' : '')
		
		# Erase update params, set Pricing Rules and Start time
		ActiveRecord::Base.connection.update( sql_products_prices_erase_and_set_rules(seller_id_s, is_nulls_only_sql) )
		
		# Set Fixed Prices if exists
		ActiveRecord::Base.connection.update( sql_products_prices_set_fixed_prices(seller_id_s, is_nulls_only_sql) )
		
		# Check whether a math calculation need (i.e. No Fixed Price exist)
		if(SellerProduct.select('id').joins(
		 'INNER JOIN seller_products_groups AS spg ON ((spg.id = seller_products.seller_group_id) AND (spg.seller_id = seller_products.seller_id) AND spg.bactive)'
		 ).where(seller_id: params[:seller_id], bactive: true, prices_upd_changed: nil).where.not(prices_upd_changing: nil).first.present?)
			
			# Calculate Sale Prices from Suppliers and Seller's In-Stock
			calc_price_for_sale(upd_params, force_recalc_wrh, nil, params[:seller_id], params[:is_all_suppliers], suppliers, true, is_nulls_only, true)
			
			# Set MAX price (Lite ver. of Pricing)
			products_prices_set_base_max(upd_params, seller_id_s, true)
			
			upd_params[:unable_calc_base_prices] = SellerProduct.joins('INNER JOIN seller_products_groups AS spg ON ((spg.id = seller_products.seller_group_id) AND (spg.seller_id = seller_products.seller_id) AND spg.bactive)').where(seller_id: params[:seller_id], prices_upd_changed: nil, prices_upd_base_price: nil).where.not(prices_upd_changing: nil).count
			
			seller_def_currency = Seller.default_currency(params[:seller], params[:seller_id]).to_s
			
			# Calculate Prices from Base Price
			sql = "UPDATE seller_products AS sp SET prices_upd_changed = clock_timestamp(), lot_prices = (
 SELECT jsonb_object_agg(sppc.id, json_build_object('val', round_with_rules(sp.prices_upd_base_price * sppc.k_multiplier, spr.*))) || jsonb_build_object('cn', defcn.cn_id) 
 FROM seller_pricing_prices AS sppc WHERE (sppc.seller_id = 0) AND sppc.bactive) 
 FROM seller_products AS sp2 
 INNER JOIN 
 INNER JOIN 
 INNER JOIN 
 INNER JOIN 
 WHERE (sp.seller_id = " + seller_id_s + ") AND sp.bactive AND (sp2.id = sp.id) AND (sp.prices_upd_changing IS NOT NULL) 
 AND (sp.prices_upd_changed IS NULL) AND (sp.prices_upd_base_price IS NOT NULL) AND ((slr.id IS NULL) OR NOT(slr.blocked AND slr.deleted))"
			upd_params[:updated_math_seller_prod_prices] = ActiveRecord::Base.connection.update(sql)
		end
	end
	
	
	def self.products_prices_set_base_max (upd_params, seller_id_s, is_nulls_only)
		sql_suppliers_instock_from_joins = " "
		
		is_nulls_only_sql = (is_nulls_only ? ' AND ((sp.prices_upd_base_price IS NULL) OR (sp.prices_upd_base_price_cn IS NULL))' : '')
		
		sql = "UPDATE seller_products AS sp SET prices_upd_base_price = ( 
 SELECT GREATEST(MAX(ssp.price_calc_2), MAX(spis.price_calc_2)) AS price " + sql_suppliers_instock_from_joins + "), 
 prices_upd_base_price_cn = (SELECT COALESCE(ssp.price_currency, spis.price_currency) AS cnc " + sql_suppliers_instock_from_joins + " LIMIT 1) 
 WHERE (sp.seller_id = " + seller_id_s + ") AND sp.bactive AND (sp.prices_upd_changing IS NOT NULL) AND (sp.prices_upd_changed IS NULL) " + is_nulls_only_sql
		ret = ActiveRecord::Base.connection.update(sql)
		
		if(upd_params[:updated_seller_prod_base_prices].nil?)
			upd_params[:updated_seller_prod_base_prices] = ret
		else
			upd_params[:updated_seller_prod_base_prices] += ret
		end
	end

	
	def self.erase_warehouses_pricing (upd_params, seller, seller_id, is_all_suppliers, suppliers, erase_instock)
		
	end
	
	
	def self.verify_seller_and_suppliers (seller, seller_id, is_all_suppliers, suppliers)
		
	end
	
	
	def self.defaults_insert_prices (seller_id)
		SellerPricingPrice.create({

		})
	end
	
	
	def self.sql_different_currencies_exist
		return "SELECT 
 WHERE (sp2.id = sp.id) GROUP BY sp2.id"
	end
	
	
	def self.sql_pricing_rules_for_price_update (column_name, sql_product_id, sql_rules_filter, sql_price_filter, no_more_filters = true)

		sql = " " + sql_price_filter
		sql += " ORDER BY spr.order_index DESC, spr.created_at DESC LIMIT 1)" if(no_more_filters)
		return sql
	end
	
	
	def self.sql_products_prices_erase_and_set_rules (seller_id_s, is_nulls_only_sql)
		return "UPDATE seller_products AS sp SET prices_upd_changing = NOW(),  " + is_nulls_only_sql
	end
	
	
	def self.sql_products_prices_set_fixed_prices (seller_id_s, is_nulls_only_sql, with_math_sql = '')
		return "UPDATE seller_products AS sp SET lot_prices = spfp.prices,  " + is_nulls_only_sql
	end
	
	def self.defaults_ensure_db_fields_exists (seller_id)
		defaults_insert_prices(seller_id) if(SellerPricingPrice.where(seller_id: seller_id).first.blank?)
	end
end
