class Order < AccessListModel

	
	def send_operator__new_order
		OrderMailer.operator_new_order(self).deliver_later
	end
	
	
	def send_information__order_placed
		OrderMailer.order_placed(self).deliver_later
	end
	
	def send_information__order_agreed
		OrderMailer.order_agreed(self).deliver_later
	end
	
	def send_information__order_accepted
		OrderMailer.order_accepted(self).deliver_later
	end
	
	def send_information__order_payment
		OrderMailer.accept_payment(self).deliver_later
	end
	
	
	def subscribed_to_purchase
		users_list = {}
		if(!self.customer_id.nil?) && (self.customer_id != 0)
			customer = Customer.where(id: customer_id).first
			users_list.merge!(customer.users_list_subscribed_to_purchase) if(customer.present?)
		end
		
		users_list.merge!({0 => nil, 'customer' => Customer.contacts_mails_list(self)}) if(self.customer_contacts.present?)
		users_list.merge!({self.user_id => nil}) if(self.user_id != 0)
		return users_list
	end
	
	
	def is_express_mode?
		return (self.express_order && self.express_order_prcnt.present? && (self.express_order_prcnt != 0))
	end
	
	def is_express_mode_price?
		return (is_express_mode? && self.express_order_price.present?)
	end
	
	
	def pay_allowed?
		return (self.agreed_at.present? && self.fully_paid_at.blank? && (self.total_cost > 0) && self.cancelled_at.blank? && !self.deleted && self.finished_at.blank?)
	end
	
	
	def waiting_prepay?
		return (self.wait_prepay && self.prepaid_at.blank? && (self.wait_prepay_summ > 0))
	end
	
	
	def waiting_pay?
		return (waiting_prepay? or (self.wait_postpay && (self.total_cost > self.paid_summ)))
	end

	
	# Список доступных способов для оплаты конкретного заказа
	def available_payment_methods_list (online_only_count = true, now_pay_summ = nil)
		if(now_pay_summ.nil?)
			now_pay_summ = summ_to_pay_now
			now_pay_summ = 0 if(now_pay_summ.nil?)
		end
		
		return PaymentMethod.allowed_types(self.customer_id, self.contract_id, now_pay_summ, self.paid_summ, !online_only_count, online_only_count)
	end
	
	
	def summ_to_pay_now
		
	end
	
	
	def set_prepay_summ # Установка суммы предоплаты и периода резервирования товара
		
	end
	
	
	def summ_currency_id
		
	end
	
	
	def get_brands_names_all (refresh = false)
		
	end
	
	
	def get_item_brand_name(order_item)
		
	end
	
	
	def item_lot_units (order_item)
		
	end
	

	def is_auto_agree_for_prepay? # Разрешено ли Автоматическое принятие заказа при его создании покупателем
		
	end
	

	def agree # Принятие заказа от покупателя. Можно не принять, например, если нет товара. Предоплата покупателем - только после принятия заказа.
		return if(self.agreed_at.present?)
		
		
	end
	
	
	def accept (sys_int = false) # Принятие в работу
		
	end
	
	
	def can_cancel_auto? (allow_agreed)
		
	end
	
	
	def cancel_if_not_agreed_not_paid (sys_int = false, allow_agreed = false, with_save = true) # Отмена не оплаченного и не отправленного заказа
		
	end
	
	
	def item_mark_to_remove (item_id, save = true, sys_int = false)
		
	end
	
	
	def item_remove (item_id, force_remove = false, save = true, sys_int = false)
		
	end
	
	
	def cancellation_answer_until
		t = Time.now + GenSetting.default_cancellation_answer_period
		return Time.at((t.to_i / 1800.0).round(0) * 1800)
	end
	
	
	def product_state (order_item, need_quantity, products_assemblies)
		
	end
	
	
	def exclude_items_allowed? # Is allowed to remove some items from order ?
		allow = false
		if(self.accepted_at.blank?)
			allow = true
		else
			if(self.cancelled_at.blank? && self.finished_at.blank? && !self.deleted && self.delivered_at.blank? && self.buyer_received_at.blank?)
				if(self.bought_from_supplier_at.blank? && self.shipped_from_supplier_at.blank? && self.received_from_supplier_at.blank? && self.packaged_for_delivery_at.blank? && self.shipped_at.blank?)
					allow = true
				end
			end
		end
		return allow
	end
	
	
	def exclude_this_item_allowed? (order_item, prods_assemblies)
		return OrdersProductsAssembly.exclude_from_order_allowed?(order_item, prods_assemblies)
	end
	
	
	def add_doc (group_name, id)
		
	end
	
	
	def accept_payment (payment)
		if(add_doc(DOCS_LIST_DOCNAME_PAYMENT, payment[:id]))
			
		end
	end
	
	
	def try_to_finish_postpay
		if(self.wait_postpay && !self.wait_prepay && self.prepaid_at.present? && self.agreed_at.present?)
			
		end
	end
	
	
	def try_to_finish_prepay
		if(self.wait_prepay && self.agreed_at.present?)
			
		end
	end
	
	
	def default_reserve_period_on_agree
		if(MARKETPLACE_SHOP)
			return GenSetting.default_reserve_period_on_agree
		else
			return Marketplace.Order_default_reserve_period_on_agree(self)
		end
	end
	
	
	def reserve_products (until_time = nil, for_period = nil)
		
	end

	
	def self.express_order_price (products_price, percents) # Ограничение максимальной наценки за экспресс-покупку
		
	end
	
	
	def calc_express_order_price (products_price = nil, percents = nil)
		
	end
	
	
	def express_cost_add_to_products_price?
		return GenSetting.express_cost_add_to_products_price? if(self.prod_prices_incl_express.nil?)
		return self.prod_prices_incl_express
	end

	
	## ITEM PRICE AND ORDER TOTAL COST
	
	def calc_item_price_markup (o_item)
		
	end
	
	
	def calc_item_discounted_price (o_item)
		
		
		return (p_base + p_markup - p_discount)
	end
	
	
	def rid_of_little_money (iprice_one, iprice_cnt, cnt, full_rid = false, only_price_cnt = true)
		
	end
	
	
	def calc_item_price (o_item, recalc_total_price = false, expr_add_to_price = nil, delivery_add_to_price = nil)
		items_cnt = nil
		
		if(o_item['pr_tbase'].blank?)
			
		end
		
		if(recalc_total_price)
			o_item_cnt = o_item['cnt'].to_f if(o_item_cnt.nil?)
			
			if((o_item_cnt == 0) && (o_item['pr_tbase'].nil? or (o_item['pr_tbase'] == 0)) && !o_item['pr_ibase'].nil? && (o_item['pr_ibase'].to_f != 0))
				pr_item = o_item['pr_ibase'].to_f
			else
				price_total_quantity = calc_item_discounted_price(o_item)
				
				
				
				price_total_quantity = price_total_quantity.round(4)
				pr_item = ((o_item_cnt != 0) ? (price_total_quantity / o_item_cnt) : price_total_quantity).round(2)
			end

			pr_total = (pr_item * o_item_cnt).round(2)
			
			rid = rid_of_little_money(pr_item, pr_total, o_item_cnt, true)
			if(rid.nil?)
				
			else
				
			end

			@b_products_changes_real = true
			return o_item['pr_total']
		end
		
		return ((o_item['pr_total'].nil?) ? 0 : o_item['pr_total'].to_f)
	end

	
	def redistribute_more_costs_to_products (costs_arr = nil, products_arr = nil, prods_summ_price_with_discounts = nil)
		
	end
	
	
	def recalculate_items_prices (arrays_new_costs = nil)
		redistribute_more_costs_to_products(arrays_new_costs)
		self.total_cost = self.products_cost_total + self.delivery_cost_above_prods
	end
	
	
	def apply_discounts (products_price_summ_base = nil, recalc_total_prices = true, products_arr = nil)
		
	end
	
	
	def save_logged (logs_user = nil, procedure_name = nil, update_only = nil, is_sys_internal_op = true, is_cron_op = false)
		if(self.changed?)
			new_data = {}
			if(self.changes.include?(:products))
				if(@b_products_changes_real)
					self.products.each_pair do |o_item_id, o_item|
						if(o_item[:lot_cost_type].present?)
							o_item.delete_if{|k,v| [:id, :lot_cost_type, :lot_measure_type, :lot_unit_type, :lot_unit_count].include?(k)}
						end
					end
				else
					self.clear_attribute_changes([:products])
				end
			end
			
			ts_events = [:dt_ishop, :events]
			changes = self.changes
			changes.keep_if{|k,v| update_only.include?(k.to_sym)} if(!update_only.nil?)
			
			logs_user_id = ((logs_user.nil?) ? 0 : logs_user.id)
			log_txt = ''

			

			event_id = UsersManipulationsLog.event_log(procedure_name, log_txt, 'order', self.id, logs_user_id, is_sys_internal_op, is_cron_op)
			if(!event_id.nil?)
				self.events = [] if(self.events.nil?)
				self.events << event_id
			end
			
			if(update_only.nil?)
				is_saved = self.save
			elsif(changes.present?)
				db_upd = {}
				changes.each_pair do |ck, cv|
					db_upd[ck] = self[ck]
				end
					
				is_saved = self.update(db_upd)
			else
				is_saved = false
			end
			
			return {log: log_txt, saved: is_saved}
		end
		return nil
	end

	
	def direct_url_params
		return URI.encode_www_form('id' => self.pub_visible_safe_id(true), 'uid' => self.hashstr)
	end
	
	
	
	# Публичный ID
	def pub_visible_safe_id (with_hash = true, for_pay_svc = false, with_shop_id = true, with_office_id = true)
		return Document.pub_visible_safe_id(DOC_TYPE_ORDER, self.id, self.created_at.utc, with_hash, false, for_pay_svc, nil, nil, with_shop_id)
	end
	
	def self.from_pub_visible_encoded_id (pub_safe_id, pay_service_encoded = true, stop_on_bad_hash = true)
		return Document.from_pub_visible_safe_id(pub_safe_id, pay_service_encoded, stop_on_bad_hash)
	end
	
	
	# ENCODED ID WITH CRC-HASH FOR SAFELY PUBLIC USAGE IN FORMS AND REQUESTS
	def self.prepare_make_safe_id
		
	end
	
	
	def self.pub_safe_uid(safeid_params, pid, gen_params_if_nil = false)
		
	end
	
	
	def self.from_safe_uid (pub_safe_id)
		
		end
	end

	
	def self.find_order_by_hash_id (order_hash_uid, order_id = nil)
		
	end
	
	
	def self.find_order_by_hashstr (hash_str, order_id = nil)
		
	end
	
	
	def self.find_by_id_if_waiting_for_pay (order_id)
		return Order.where("(id = ?) and (agreed_at IS NOT NULL) and (fully_paid_at IS NULL) and ((wait_prepay and (prepaid_at IS NULL)) OR wait_postpay) and (deleted IS FALSE) and (cancelled_at IS NULL) and (finished_at IS NULL)", order_id).first
	end
	
	
	def self.list_orders (filter_type, page, per_page, current_user, list_user_id, list_customers = nil)
		user_customer_filter = ''
		
		if(filter_type.blank?)
			no_filter_type = true
			filter_type = 'wait_pay'
		else
			no_filter_type = false
		end
		
		if(!current_user.is_admin? && !current_user.is?(:moderator_orders)) # they have a full access
			if(current_user.is?(:moderator_orders_new))
				filter_type = 'new'
				no_filter_type = false
			elsif(current_user.is?(:moderator_orders_prepaid_accepted))
				filter_type = 'paid' if((filter_type != 'paid') && (filter_type != 'wait_delivery')) #paid_unfinished
				no_filter_type = false
			elsif(current_user.is?(:moderator_orders_delivered))
				filter_type = 'delivered'
				no_filter_type = false
			# seller's rights are absent, because they look at sellers_orders only!
			# next - users only
			else
				user_customer_filter = '(user_id = ' + current_user.id.to_s + ')'
				if(list_customers.present?)
					list_customers.each do |customer_id|
						user_customer_filter += ' OR (customer_id = ' + customer_id.to_s + ')'
					end
					user_customer_filter = '(' + user_customer_filter + ')'
				end
				user_customer_filter = ' AND ' + user_customer_filter
			end
		end
		
		case (filter_type)
			when 'wait_pay' # wait money
				
			when 'paid' # paid
				
			when 'wait_delivery' # wait_delivery
				
			when 'delivered' # delivered
				
			
			else # new orders
				find = Order.where("(is_placed IS TRUE) AND ((agreed_at IS NULL) or (delivery_charges_ready IS FALSE) or (accepted_at IS NULL)) and (deleted IS FALSE) and (cancelled_at IS NULL) and (money_back = 0)" + user_customer_filter).order('created_at desc')
				title = "Новые заказы"
		end

		orders = find.paginate(:page => page, :per_page => per_page)
		if(orders.blank? or (orders.size == 0))
			if(page != 1)
				orders = find.paginate(:page => 1, :per_page => per_page)
			elsif(no_filter_type) # no orders is waiting money then show new orders
				ret = list_orders('new', page, per_page, current_user, list_user_id, list_customers)
				title = ret[:title]
				filter_type = ret[:type]
				orders = ret[:orders]
			end
			
			orders = nil if(orders.blank? or (orders.first.blank?))
		end
		return {orders: orders, title: title, type: filter_type}
	end
	
	
	
	## ================== ##
	##     DELIVERY       ##
	## ================== ##
	
	def self.delivery_price_type_default
		
		return GenSetting.delivery_price_type_default
	end
	
	
	def delivery_price_type_changeable?
		
		return GenSetting.delivery_price_type_changeable?
	end
	

	def delivery_price_customer_allowed_choose_type? # Add it to Products Prices or Not
		
	end
	
	
	def waiting_delivery_charges? (try_auto_calc_now = false)
		if(self.delivery_charges_ready)
			false
		else
			if(try_auto_calc_now)
				get_delivery_charges(true)
				return (!self.delivery_charges_ready)
			else
				true
			end
		end
	end
	
	
	def delivery_charges_add_to_products_prices?
		if(delivery_price_type_changeable?)
			ret = self.prod_prices_incl_delivery
		else
			ret = (Order.delivery_price_type_default == DELIVERY_COST_ADD_TO_PROD_PRICES)
		end
		return ret
	end
	
	
	def delivery_charges_full
		if(self.total_incl_delivery_to_customer)
			return (self.delivery_charges_from_seller.to_f + self.delivery_charges_to_customer.to_f)
		else
			return self.delivery_charges_from_seller.to_f
		end
	end
	
	
	def delivery_charges_included_to_products
		full_charges = delivery_charges_full
		return ((full_charges >= self.delivery_cost_above_prods) ? (full_charges - self.delivery_cost_above_prods) : full_charges)
	end

	
	def set_delivery_charges (price_from_seller, use_from_seller, price_to_customer, use_to_customer)
		
	end

	
	def set_delivery_charges_and_recalc_costs (price_from_seller, use_from_seller, price_to_customer, use_to_customer, set_total_include_delivery_to_customer = false) # Установка стоимости доставки и дорасчёт полной стоимости заказа
		
		
		recalculate_items_prices(arr)
	end
	
	
	def calc_delivery_from_seller_to_carrier (set_value = true)
		if(MARKETPLACE_SHOP or MARKETPLACE_RETAIL)
			
		else
			new_val = Marketplace.Order_delivery_charges_from_sellers_to_delivery_partners(self)
		end
		
		self.delivery_charges_from_seller = new_val if(set_value)
		return new_val
	end
	
	
	def calc_delivery_to_customer (set_value = true)
		if(MARKETPLACE_SHOP or MARKETPLACE_RETAIL)
			
		else
			new_val = Marketplace.Order_delivery_charges_to_customers(self)
		end
		
		self.delivery_charges_to_customer = new_val if(set_value)
		return new_val
	end
	
	
	def try_auto_calc_delivery_charges
		
	end
	
	
	def get_delivery_charges (try_auto_calc_now = false)
		
		
		if(self.total_incl_delivery_to_customer) # Total Cost includes delivery charges from delivery company to customer ?
			if(self.delivery_charges_ready)
				
			else
				if(try_auto_calc_now)
					
				end
				
				
			end
		
		else # Стоимость доставки поставщиком до покупателя оплачивается покупателем индивидуально, в счёт заказа не включается
			if(self.delivery_charges_ready)
				
			else
				if(!self.delivery_charges_from_seller.nil?)
					
					
				elsif(try_auto_calc_now)
					
				end
				
				
			end
		end
	end

	## DELIVERY - POST OFFICE
	def self.post_office_pay_on_delivery_allowed?
		
	end
	
	def self.post_office_pay_on_delivery_use_by_default?
		
	end
	
	def self.post_office_pay_on_delivery_allow_customer_changes?
		
	end

	
	
	## ======================================== ##
	##     ACL - Access List Rights Model       ##
	## ======================================== ##
	
	RIGHTS = {
		# Права заказа:
		
	}
	
	def rights_list
		RIGHTS
	end
	
	#Verify the access after Main Rights verification
	def object_has_access? (rights, pAccessList = @rAcl)
		ret_access = pAccessList.user_is?([:admin, :super_admin])
		if(!ret_access)
			
		end
		return ret_access
	end
	
	
	def has_access_create_new? (user, user_id)
		return true if(user.nil? && (user_id == 0) && (self.user_id.nil? or (self.user_id == 0))) # Guest could continue creation of the previously started order
		if(user.present? && user.is_allowed_to_profile?)
			return true if(user.is_admin_or_orderscreator?) or (user.id == self.user_id)
		end
		return false
	end
	
	
	### =================================== PROTECTED ==========================================
	### ========================================================================================
	protected
	
	
	### ==================================== PRIVATE ===========================================
	### ========================================================================================
	private
end
