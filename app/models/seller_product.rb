class SellerProduct < AccessListModel
	has_one    :seller, :foreign_key => :id, :primary_key => :seller_id
	has_one    :seller_brand, :foreign_key => :id, :primary_key => :seller_brand_id
	has_one    :seller_products_group, :foreign_key => :id, :primary_key => :seller_group_id
	has_one    :gen_search_product, :foreign_key => :id, :primary_key => :seller_prod_id
	
	has_many   :seller_products_fixed_prices, :foreign_key => :seller_prod_id, :primary_key => :id
	has_many   :seller_products_in_stock, :foreign_key => :seller_prod_id, :primary_key => :id
	has_many   :seller_suppliers_products, :foreign_key => :seller_prod_id, :primary_key => :id
	has_many   :seller_suppliers_products_infos, :foreign_key => :seller_prod_id, :primary_key => :id

	
	scope :for_order, -> {select("seller_products.id, seller_products.name, seller_products.seller_own_prod_id, seller_products.prod_artikul, 
	seller_products.prod_code, seller_products.seller_brand_id, seller_products.prod_info, seller_products.lot_dealers, seller_products.tax_system, seller_products.tax_rate, 
	seller_products.lot_prices, seller_products.lot_cost_type, seller_products.lot_measure_type, seller_products.lot_unit_type, seller_products.lot_unit_count, 
	seller_products.available_count, seller_products.photo_ids, seller_brands.global_brand_id AS global_brand_id").from('seller_products')
	.joins('LEFT OUTER JOIN seller_brands ON(seller_brands.id = seller_products.seller_brand_id)')
	.joins(:seller_products_group).eager_load(:seller)}
	
	scope :for_price, -> {select("seller_products.id, seller_products.lot_dealers, seller_products.tax_system, seller_products.tax_rate, 
	seller_products.lot_prices, seller_products.lot_cost_type, seller_products.lot_measure_type, seller_products.lot_unit_type, seller_products.lot_unit_count, 
	seller_products.available_count").from('seller_products').joins('LEFT OUTER JOIN seller_brands ON(seller_brands.id = seller_products.seller_brand_id)')
	.joins(:seller_products_group).eager_load(:seller)}
	
	
	
	
	@parent_nodes = nil
	@seller = nil
	@is_archived = nil
	@archived_lot_price = nil
	@archived_avail_level = nil
	@archived_tax_system_id = nil
	@archived_tax_id = nil
	
	### Много self.функций, потому что вызовы идут ещё и для объектов json, хранящихся в Cart и Order.

	
	# Публичный ID - это ID для запросов GET. Пока равен самому ID.
	def pub_id
		return self.id
	end
	
	def self.pub_id (pobj)
		return pobj[:id]
	end
	
	
	# Найти ID по Публичному ID
	def self.from_pub_id (pub_id)
		# Определить что это именно публичный ID.
		# Пока просто возвращаем ID
		return ((pub_id.is_a?(Integer) or (pub_id.is_a?(String) && pub_id.numeric?)) ? pub_id.to_i : 0)
	end
	
	
	# Внутренний код продавца - это Артикул товара из базы (1С) продавца
	def self.seller_int_code (pobj)
		return pobj['prod_artikul'] if(pobj['prod_artikul'].present?)
		return pobj[:id]
	end
	
	
	# URL для детального просмотра о товаре
	def self.link_url (prod, order_archive = false, order_safe_uid = 'o')
		if(order_archive)
			return '/product/archive/order/' + order_safe_uid + '/' + pub_id(prod).to_s
		else
			return '/product/' + pub_id(prod).to_s
		end
	end
	
	
	def self.is_available? (prod)
		return ((!prod['available_count'].nil?) && (prod['available_count'] > 0))
	end
	
	
	def self.short_description (prod)
		return prod['desc_thumb'] if(prod['desc_thumb'].present?)
		return prod['description'][0,500] if(prod['description'].present?)
		nil
	end
	
	
	def self.image_thumbnail (product, products_images)
		prod_img = nil
		ret = {}
		if(products_images.present?)
			if(!product[:photo].nil?)
				prod_img_ids = product[:photo]
			elsif(!product[:photo_ids].nil?)
				prod_img_ids = product[:photo_ids]
			else
				prod_img_ids = nil
			end
			
			if(prod_img_ids.present?)
				prod_imgs = products_images.select{|pimg| prod_img_ids.include?(pimg[:id])}
				if(prod_imgs.present?)
					prod_img = prod_imgs.find{|pimg| pimg[:for_thumb]}
					prod_img = prod_imgs.first if(prod_img.blank?)
				end
			end

			if(prod_img.present?)
				ret[:path_thumb] = prod_img.image.url(:thumb)
				ret[:path_zoom] = prod_img.image.url(:medium)
			end
		
			ret[:style] = prod_img.zoom_style if(!ret[:path_zoom].nil?)
		end
		return ret
	end
	
	
	def get_seller
		return nil if(MARKETPLACE_SHOP or (self.seller_id == 0))
		@seller = (defined?(self.seller) ? self.seller : Seller.where(id: self.seller_id).first) if(@seller.nil?)
		return @seller
	end

	
	def self.parent_nodes_list (products, products2 = nil)
		groups_find = nil
		
		if(!products.nil?)
			if(products.is_a?(SellerProduct))
				groups_find = products.seller_products_group.parent_nodes
				seller_ids = [products.seller_id]
			else
				groups_find = []
				seller_ids = []
				products.each do |prod|
					if(defined?(prod.seller_products_group) && prod.seller_products_group.parent_nodes.present?)
						new_nodes = prod.seller_products_group.parent_nodes - groups_find
						groups_find = (groups_find | new_nodes) if(new_nodes.present?)
					end
					seller_ids << prod.seller_id
				end
			end
		end
		
		if(!products2.nil?)
			if(products2.is_a?(SellerProduct))
				groups_find = products2.seller_products_group.parent_nodes
				seller_ids = [products2.seller_id]
			else
				groups_find = []
				seller_ids = []
				products2.each do |prod|
					if(defined?(prod.seller_products_group) && prod.seller_products_group.parent_nodes.present?)
						new_nodes = prod.seller_products_group.parent_nodes - groups_find
						groups_find = (groups_find | new_nodes) if(new_nodes.present?)
					end
					seller_ids << prod.seller_id
				end
			end
		end
		
		return SellerProductsGroup.where("(id = ANY(ARRAY[?])) OR ((seller_id = ANY(ARRAY[?])) AND (main_group_id = -1) AND (prod_group_id = 0))", groups_find, seller_ids).find_all if(groups_find.present?)
		return nil
	end
	
	
	def parent_nodes_list
		@parent_nodes = SellerProduct.parent_nodes_list(self) if(@parent_nodes.nil?)
		return @parent_nodes
	end
	
	
	# Публикуемая стоимость (проверка разных цен, умножение на скидку и т.п.)
	def self.calc_pub_cost (prod, parent_groups, force_with_tax = nil)
		ret = {}
		customer_prod_price_id = nil
		
		if(prod.present? && prod[:lot_prices].present?)
			prod_prices = prod[:lot_prices].keys.delete_if{|x| !x.numeric?}.map{|x| x.to_i}
			if(prod_prices.length > 0)
				
			end
			
			if(!customer_prod_price_id.nil?)
				lot_price = prod[:lot_prices][customer_prod_price_id.to_s]
				if(lot_price.present? && lot_price['val'].present?)
					
					
				end
			else
				customer_price = nil
				price_currency = nil
			end
			
			ret[:price] = round_price(customer_price, true, nil) if(!customer_price.nil?)
			ret[:currency] = price_currency
			
			return ret
		end
		
		return nil
	end
	
	
	# Стоимость всего лота целиком (если публикуемая цена = за составную часть лота)
	def self.calc_pub_entire_lot_cost (prod, pub_price = nil)
		
	end
	
	
	# Стоимость составной части лота (если публикуемая цена = за весь лот целиком)
	def self.calc_pub_unit_cost (prod, pub_price = nil)
		
	end
	
	
	def self.calc_quantity_cost (price, quantity)
		price_qnt = ((quantity == 1) ? price : (price * quantity))
		price_tot = price_qnt.round(2)
		price_int = price_qnt.round(0)
		price_tot = price_int if(price_tot == price_int)
		return price_tot
	end
	
	
	def self.round_price (price, round_2 = false, remainder = nil)
		price_tot = ((round_2) ? price.round(2) : price)
		price_int = price.round(0)
		if(price_tot == price_int)
			price_tot = price_int
		elsif(!remainder.nil?)
			remainder[0] = ((price_tot - price_int)*100).round(0)
			price_tot = price_int
		end
		return price_tot
	end
	
	
	def quantity_unit (params)
		mtype = ((PRODUCT_MEASURE_TYPE.has_key?(self.lot_measure_type)) ? PRODUCT_MEASURE_TYPE[self.lot_measure_type][:is_integer] : true)
		qnt = ((mtype) ? params[:qntraw].to_i : params[:qntraw].to_f)

		qnt = 0 if(qnt < 0)
		return qnt
	end
	
	
	def self.quantity_unit (prod_id, params)
		if(params[:quantity].nil?)
			prod = SellerProduct.select("id, lot_measure_type").where("id = ?", prod_id).first
			qnt = ((prod.present?) ? prod.quantity_unit(params) : params[:qntraw].to_i)
		else
			qnt = params[:quantity]
		end
		
		qnt = 0 if(qnt < 0)
		return qnt
	end
	
	
	# Определение единицы измерения лота в зависимости от типа стоимости
	# 1) Продаётся набор 12 фломастеров. публикуемая цена 3р/фломастер. => цена продажи 36р/набор.
	# 2) Продаётся набор 10 фломастеров. публикуемая цена 30р/набор. => цена продажи 30р/набор.
	def self.lot_units (prod)
		# lot_cost_type - Тип стоимости лота:
		#   0 = PRODUCT_COST_TYPE_WHOLE_LOT = цена за весь лот (объём) в единицах lot_measure_type.
		#   1 = PRODUCT_COST_TYPE_PER_UNIT  = цена за меру (за составную часть - lot_unit_type), требует умножения с учетом lot_unit_type и lot_unit_count.
		# lot_measure_type - Единица измерения всего представленного лота (упаковка, порция, коробка, шт, кг, г)
		# lot_unit_type -  Единица измерения составной части лота (если есть: шт, кг, г, пакетик, горстка)
		# lot_unit_count -  Количество единиц lot_unit_type в лоте
        if(prod[:lot_cost_type] == PRODUCT_COST_TYPE_WHOLE_LOT)
			
        else # i.e. PRODUCT_COST_TYPE_PER_UNIT
		
		end
		return {lot_measure: lt_measure_name, unit_measure: unit_name, lot_measure_show: ((lt_measure_code != 0) && ((prod[:lot_cost_type] != PRODUCT_COST_TYPE_WHOLE_LOT) or (lt_measure_code != DEFAULT_PRODUCT_MEASURE_INVISIBLE)))}
	end

	
	def self.delimiter_thousands (anumber, separator = ' ')
		return Payment.delimiter_thousands(anumber, separator)
	end
	
	
	# Доступность товара не в количестве, а в виде "много / мало / очень много / очень мало"
	def self.available_level (prod, parent_groups)
		
		
		if(defined?(prod.seller_products_group) && parent_groups.present? && prod.seller_products_group.parent_nodes.present?)
			
		end
		
		if(avail_as_level)
			
			
			lvl_text = I18n.t(text_id, scope: [:dt_ishop, :products])
		else
			lvl_text = nil
		end
		
		return {
			avail_as_level:  avail_as_level,
			lvl_text: lvl_text,
			lvl_little_min:  avail_lvl_little_min,
			lvl_little_max:  avail_lvl_little_max,
			lvl_alot_max:    avail_lvl_alot_max
		}
	end
	
	
	def is_archived=(state)
		@is_archived = state
	end
	
	
	def is_archived?
		@is_archived
	end
	
	
	def archived_var_tax_id=(tid)
		@archived_tax_id = tid
	end
	
	
	def archived_var_tax_id
		@archived_tax_id
	end
	
	
	def archived_var_tax_system_id=(tid)
		@archived_tax_system_id = tid
	end
	
	
	def archived_var_tax_system_id
		@archived_tax_system_id
	end
	
	
	def archived_var_lot_price=(price)
		@archived_lot_price = price
	end
	
	
	def archived_var_lot_price
		@archived_lot_price
	end
	
	
	def archived_var_avail_level=(level)
		@archived_avail_level = level
	end
	
	
	def archived_var_avail_level
		@archived_avail_level
	end
	
	def self.update_available (upd_params, seller_id, upd_in_stock, upd_suppliers)
		return if(seller_id.nil?)
		seller_id_s = seller_id.to_s
		
		if(upd_in_stock)
			if(upd_suppliers) # update both suppliers and in stock
				sql = "UPDATE seller_products AS sp SET lot_in_stock_count = COALESCE(tsum_stock.avail_in_stock,0), avail_suppliers_count = COALESCE(tsum.avail_sum,0), available_count = COALESCE(tsum_stock.avail_in_stock,0) + COALESCE(tsum.avail_sum,0), updated_at = LOCALTIMESTAMP \
 FROM seller_products AS sp2 LEFT OUTER JOIN (SELECT seller_prod_id, SUM(available_count) AS avail_in_stock FROM seller_products_in_stock WHERE (seller_id = " + seller_id_s + ") GROUP BY seller_prod_id) AS tsum_stock ON (tsum_stock.seller_prod_id = sp2.id) \
 LEFT OUTER JOIN (SELECT seller_prod_id, SUM(available_count) AS avail_sum FROM seller_suppliers_products WHERE (seller_id = " + seller_id_s + ") GROUP BY seller_prod_id) AS tsum ON (tsum.seller_prod_id = sp2.id) \
 WHERE (sp.seller_id = " + seller_id_s + ") AND (sp2.id = sp.id) AND ((COALESCE(tsum_stock.avail_in_stock,0) != sp.lot_in_stock_count) OR (COALESCE(tsum.avail_sum,0) != sp.avail_suppliers_count))"
			
				upd_params[:updated_seller_prods_avail_suppliers_and_instock] = ActiveRecord::Base.connection.update(sql)
			
			else # update in stock only
				sql = "UPDATE seller_products AS sp SET lot_in_stock_count = COALESCE(tsum_stock.avail_in_stock,0), available_count = sp.avail_suppliers_count + COALESCE(tsum_stock.avail_in_stock,0), updated_at = LOCALTIMESTAMP \
 FROM seller_products AS sp2 INNER JOIN (SELECT seller_prod_id, SUM(available_count) AS avail_in_stock FROM seller_products_in_stock WHERE (seller_id = " + seller_id_s + ") GROUP BY seller_prod_id) AS tsum_stock ON (tsum_stock.seller_prod_id = sp2.id) \
 WHERE (sp.seller_id = " + seller_id_s + ") AND (sp2.id = sp.id) AND (COALESCE(tsum_stock.avail_in_stock,0) != sp.lot_in_stock_count)"
			
				upd_params[:updated_seller_prods_avail_instock] = ActiveRecord::Base.connection.update(sql)
			end
		
		else # update suppliers only
			sql = "UPDATE seller_products AS sp SET avail_suppliers_count = COALESCE(tsum.avail_sum,0), available_count = sp.lot_in_stock_count + COALESCE(tsum.avail_sum,0), updated_at = LOCALTIMESTAMP \
 FROM seller_products AS sp2 INNER JOIN (SELECT seller_prod_id, SUM(available_count) AS avail_sum FROM seller_suppliers_products WHERE (seller_id = " + seller_id_s + ") GROUP BY seller_prod_id) AS tsum ON (tsum.seller_prod_id = sp2.id) \
 WHERE (sp.seller_id = " + seller_id_s + ") AND (sp2.id = sp.id) AND (COALESCE(tsum.avail_sum,0) != sp.avail_suppliers_count)"
			
			upd_params[:updated_seller_prods_avail_suppliers] = ActiveRecord::Base.connection.update(sql)
		end
	end
	

	
	# ENCODED ID WITH CRC-HASH FOR SAFELY PUBLIC USAGE IN FORMS AND REQUESTS
	def self.prepare_make_safe_id
		
	end
	
	
	def self.pub_safe_uid_lite(safeid_params, pid)
		
	end
	
	
	def self.pub_safe_uid_decode(str_encoded)
		
	end
	
	
	def self.pub_safe_uid_encode(safeid_params, str, def_found)
		
	end
	
	
	def self.from_safe_uid_decode_id (rid, multiplier, summand)
		
	end
	
	
	def self.pub_safe_uid(safeid_params, pid)
		
	end
	
	
	def self.from_safe_uid_get_id (str_dec, n1, params = nil, delimiter = '-')
		
	end

	
	def self.from_safe_uid (pub_safe_id)
		
	end

	
	# SEARCH PAGINATED
	def self.search_paginated (seller_id, seller_group_id, global_group_id, sql, page = 1, per_page = 10, active_only = true, max_count = nil)
		bactive_sql = (active_only ? ' AND (seller_products.bactive)' : '')
		find = SellerProduct.eager_load(:seller_products_group, :seller)
		.where('(seller_products.seller_id = ' + seller_id.to_s + ') ' + bactive_sql + ' AND (seller_products.seller_group_id = ' + seller_group_id.to_s + ')' + ((sql.nil?) ? '' : sql)).order('seller_products.sort_order ASC NULLS LAST, seller_products.name ASC, seller_products.prod_code ASC, seller_products.id ASC')
			
		if(max_count.nil?) or (page > 1) or (max_count > per_page)
			objects = find.paginate(:page => page, :per_page => per_page)
			if(objects.blank? or (objects.size == 0))
				objects = find.paginate(:page => 1, :per_page => per_page)
			end
		else
			find = find.limit(max_count) if(max_count.nil? == false)
			objects = find.find_all
		end
		
		return objects
	end
	
	
	def self.list_paginated (seller_id, seller_group_id, global_group_id, search_params = nil, page = 1, per_page = 10, max_count = nil)
		products = nil
		result = {}
		
		if(seller_group_id.nil?) && (!global_group_id.nil?) && (global_group_id != 0)
			result[:seller_group] = SellerProductsGroup.select('id').where("(seller_id = ?) AND (prod_group_id = ?) AND ((sort_order IS NULL) OR (sort_order >= 0))", seller_id, global_group_id).first
			seller_group_id = result[:seller_group][:id] if(result[:seller_group].present?)
		else
			result[:seller_group] = nil
		end
		
		if(!seller_group_id.nil?) && (seller_group_id != 0)
			btry = false
			bOk = false
			if(search_params.present?)
				if(!search_params[:brand_model_year_num].nil?)
					filter_seller_brand_models = []
					filter_seller_brand_models_years = []
					
					if(search_params[:s_brand_id].nil?)
						search_params[:s_brand_id] = SellerBrand.id_from_global(seller_id, search_params[:g_brand_id])
					end
					
					if(!search_params[:s_brand_id].nil?)
						brand_model_years = SellerBrandModel.select("id").where("(seller_id = ?) and (brand_id = ?) and (global_model_id = ?) and ((((model_year_first IS NULL) OR (model_year_first <= ?)) AND ((model_year_last IS NULL) OR (model_year_last >= ?))) OR ((model_year_only IS TRUE) AND (model_year_first = ?)))", seller_id, search_params[:s_brand_id], search_params[:g_brand_model_id], search_params[:brand_model_year_num], search_params[:brand_model_year_num], search_params[:brand_model_year_num]).order("name asc").find_all
						brand_model_years_cnt = ((brand_model_years.present?) ? brand_model_years.size : 0)
						if(brand_model_years_cnt != 0)
							brand_model_years.each do |bm|
								filter_seller_brand_models << bm[:id].to_s
								SellerBrandModel.select("id").where("(seller_id = ?) and (brand_id = ?) and (main_model_id = ?) and ((((model_year_first IS NULL) OR (model_year_first <= ?)) AND ((model_year_last IS NULL) OR (model_year_last >= ?))) OR ((model_year_only IS TRUE) AND (model_year_first = ?)))", seller_id, search_params[:s_brand_id], bm[:id], search_params[:brand_model_year_num], search_params[:brand_model_year_num], search_params[:brand_model_year_num]).order("name asc").find_each do |bmy|
									filter_seller_brand_models_years << bmy[:id].to_s
								end
							end
						end
					end

					if(filter_seller_brand_models_years.present?)
						btry = true
						sql = ' AND (prod_info -> \'formodel\' ?| array' + filter_seller_brand_models_years.to_s.gsub!('"','\'') + ')'
						products = search_paginated(seller_id, seller_group_id, global_group_id, sql, page, per_page, (search_params[:with_inactive] != true), max_count)
						bOk = products.present?
					end
					result[:brand_model_year_num_ok] = bOk
					
					if(!bOk && filter_seller_brand_models.present?)
						btry = true
						sql = ' AND (prod_info -> \'formodel\' ?| array' + filter_seller_brand_models.to_s.gsub!('"','\'') + ')'
						products = search_paginated(seller_id, seller_group_id, global_group_id, sql, page, per_page, (search_params[:with_inactive] != true), max_count)
						bOk = products.present?
						result[:brand_model_id] = bOk
					end
				end
				
				if(!bOk)
					['brand_model_id', 'brand_id'].each do |sct|
						is_model = (sct != 'brand_id')
						if(search_params[sct].nil?)
							ptr = ('g_'+sct).to_sym
							next if(search_params[ptr].nil?)
							model = (is_model ? SellerBrandModel.select('id').where("(seller_id = ?) AND (global_model_id = ?)", seller_id, search_params[ptr]).first : SellerBrand.select('id').where("(seller_id = ?) AND (global_brand_id = ?)", seller_id, search_params[ptr]).first)
							next if(model.blank?)
							search_params[sct] = model[:id]
							if(is_model)
								search_models = [model[:id]]
								sub_model = SellerBrandModel.select('id').where("(seller_id = ?) AND (main_model_id = ?)", seller_id, model[:id]).find_all
								if(sub_model.present?)
									sub_model.each do |sm|
										search_models << sm[:id]
									end
								end
							end
						else
							next if(search_params[sct] == 0)
							search_models = [search_params[sct]] if(is_model)
						end
						
						btry = true
						if(is_model)
							sql = ' AND (prod_info -> \'formodel\' ?| array' + search_models.collect{|x| x.to_s}.to_s.gsub('"','\'') + ')'
						else
							sql = ' AND (prod_info -> \'forbrand\' ? \'' + search_params[sct].to_s + '\')'
						end

						products = search_paginated(seller_id, seller_group_id, global_group_id, sql, page, per_page, (search_params[:with_inactive] != true), max_count)
						bOk = products.present?

						result[sct.to_sym] = bOk
						break if(bOk)
					end
				end
			end
			
			if(!btry)
				products = search_paginated(seller_id, seller_group_id, global_group_id, nil, page, per_page, (search_params[:with_inactive] != true), max_count)
				result[:total_search] = products.present?
			end

			products = nil if(products.blank?)
		end
		
		result[:products] = products
		return result
	end
	
	
	## ======================================== ##
	##     ACL - Access List Rights Model       ##
	## ======================================== ##
	
	# RIGHTS = {
	#	:some_right => 31, # start from the last of 32 bits
	# }
	
	def rights_list
		RIGHTS
	end
	
	# Verify the access after Main Rights verification
	def object_has_access? (rights, pAccessList = @rAcl)
		ret_access = pAccessList.user_is?([:moderator_products, :admin, :super_admin])
		
		if(!ret_access && !MARKETPLACE_MODE_ONLINE_SHOP && (self.seller_id != 0))
			@seller = Seller.where(id: self.seller_id).first if(@seller.nil?)
			if(@seller.present?)
				user = pAccessList.user
				oAcl = AccessList.new(!user.nil?, user)
				oAcl.update_from_Object!(@seller)
				
				if(rights.include?(:edit))
					ret_access = oAcl.is_any_right?([:objorg_owner, :objorg_seller])
				end
			end
		end
		
		return ret_access
	end

end
