class OrdersController < ApplicationController
	@@verify_order_acl_pages = [:cancel, :change_accept, :change_agree, :change_delivery_charges, :change_delete_item, :delete, :show]
	@@no_authorization_required_pages = [:begin, :express, :new]

	before_action :set_footer_offer_info , :only => [:show, :begin, :express, :new]
	
	before_action :authenticate_and_authorize_user_action_and_object,  :only =>    @@verify_order_acl_pages
	before_action :authenticate_and_authorize_user_action,             :except => (@@verify_order_acl_pages + @@no_authorization_required_pages)
	after_action  :verify_authorized, :except => @@no_authorization_required_pages

	
	def index
		redirect_to orders_cabinet_index_path
	end
	
	
	def show
		set_cabinet_breadcrumbs({:name => I18n.t(:orders, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => SITE_PATH_ADDRESS_ROOT_CANONICAL + orders_cabinet_index_path})
		
		@order_safeid_params = Order.prepare_make_safe_id
		@order_uid = Order.pub_safe_uid(@order_safeid_params, @order[:id])
		
		@prod_code_form = 0 # Тип вывода кода товара: Бренд + КодТовара или Артикул_Магазина(продавца)
		
		@is_admin = current_user.is_admin?
		@is_moderator = (@is_admin or current_user.is?(:moderator_orders))
		
		if(MARKETPLACE_SHOP)
			@is_order_admin = @is_admin
			@is_order_moderator = (@is_order_admin or @is_moderator)
		else
		
		end
		
		@noscram_supplier_name = true
		
		if(@order[:is_placed])
			@moder_new = ((@order[:agreed_at].blank? or !@order[:delivery_charges_ready] or (@order[:wait_prepay] && @order[:prepaid_at].blank?)) && (@is_moderator or current_user.is?(:moderator_orders_new)))
			@moder_accepted = ((@order[:accepted_at].present? or (@order[:wait_prepay] && @order[:prepaid_at].present?)) && (@is_moderator or current_user.is?(:moderator_orders_prepaid_accepted)))
			@moder_delivered = ((@order[:delivered_at].present? or @order[:buyer_received_at].present? or @order[:buyer_full_receive_confirmed] or @order[:cancelled_at].present? or @order[:finished_at].present?) && (@is_moderator or current_user.is?(:moderator_orders_delivered)))
			
			if(!@is_order_moderator)
				@is_order_moderator = (@moder_new or @moder_accepted or @moder_delivered)
			end
			
			if(@is_order_moderator)
				@acl_view_list_items = true
				
				order_prods_ids = []
				@order_items_cnt = 0
				if(@order[:products].present?)
					@order[:products].each_pair do |pid, pprops|
						if(!pprops.nil? && (pprops['removed'].blank? or (pprops['removed'].to_i != 1)))
							order_prods_ids << pid.to_i
							@order_items_cnt += 1
						end
					end
				end
				
				if(order_prods_ids.present?)
					@order_prods = SellerProduct.select('id, bactive, app_scope, order_variants, lot_dealers, lot_in_stock, lot_in_stock_count, available_count, avail_suppliers_count, reserved_count, reserved, complex_items').where(id: order_prods_ids).find_all
					if(@order_prods.first.blank?)
						@order_prods = nil
					else
						if(MARKETPLACE_SHOP or MARKETPLACE_RETAIL)
							@find_in_stock = GenSetting.sale_products_in_stock?
							@find_at_suppliers = GenSetting.sale_products_from_suppliers?
						else
							@find_in_stock = true
							@find_at_suppliers = true
						end
						
						if(@find_at_suppliers)
							prod_ids = @order_prods.collect{|op| op.id}
							sql_select = 'ssp.*, ssw.seller_supplier_id supp_id, ssw.seller_supplier_wrh_id AS wrh_id, ssw.name AS wrh_name, ssw.short_name AS wrh_short_name, supp.name AS supp_name, supp.short_name AS supp_short_name, supp.scram_name AS supp_scram_name, sspi.name AS supp_prod_name, sspi.prod_code AS supp_prod_code, sspi.comments AS supp_prod_comments'
							sql_from   = 'seller_suppliers_products AS ssp'
							sql_joins  = "INNER JOIN seller_suppliers AS supp ON((supp.seller_id = ssp.seller_id) AND (supp.seller_supplier_id = ssp.seller_supplier_id) AND supp.allow_import) \
 INNER JOIN seller_suppliers_warehouses AS ssw ON((ssw.seller_id = ssp.seller_id) AND (ssw.seller_supplier_id = ssp.seller_supplier_id) AND (ssw.seller_supplier_wrh_id = ssp.seller_supplier_wrh_id) AND ssw.bactive) \
 INNER JOIN seller_suppliers_products_infos AS sspi ON((sspi.seller_id = ssp.seller_id) AND (sspi.seller_supplier_id = ssp.seller_supplier_id) AND (sspi.seller_supplier_prod_id = ssp.seller_supplier_prod_id))"
						
							@order_supp_prods = SellerSuppliersProduct.select(sql_select).from(sql_from).joins(sql_joins).where("ssp.seller_prod_id IN (?)", prod_ids).order('ssp.seller_prod_id ASC, ssp.seller_supplier_id ASC, ssw.seller_supplier_wrh_id ASC').find_all
							@order_supp_prods = nil if(@order_supp_prods.first.blank?)
						end
						
						if(@find_in_stock)
							@order_own_prods = SellerProductsInStock.where(seller_prod_id: prod_ids).find_all
							@order_own_prods = nil if(@order_own_prods.first.blank?)
						end
					end
					
					@delivery_cost_info = @order.get_delivery_charges(true)
					@waiting_delivery_cost = @order.waiting_delivery_charges?
				
				else
					@delivery_cost_info = {}
				end
				
				@pay_invoices = PayInvoiceCustomer.where(doc_parent_id: @order.id, doc_parent_type: DOC_TYPE_ORDER, doc_client_id: @order[:customer_id].to_i).find_all
				@pay_invoices = nil if(@pay_invoices.first.blank?)
				
				if(@pay_invoices.nil?)
					@payments = Payment.for_list.where(order_id: @order.id, payer_type: DOC_RELATIONSHIP_CUSTOMER, payer_id: @order[:customer_id].to_i).order('created_at desc').find_all
				else
					@payments = Payment.for_list.where("((order_id = ?) OR (pay_invoice_id IN (?))) AND (payer_type = ?) AND (payer_id = ?)", @order.id, @pay_invoices.collect{|py| py.id}, DOC_RELATIONSHIP_CUSTOMER, @order[:customer_id].to_i).order('created_at desc').find_all
				end
				@payments = nil if(@payments.first.blank?)
			end
			
			if(@order[:cancellations].present?)
				@order_cancel = OrdersCancellation.where(id: @order[:cancellations]).find_all
				if(@order_cancel.first.blank?)
					@order_cancel = nil
				else
					@ocn_pendings = false
					@ocn_entire_pendings = false
					@ocn_entire_cancelled = false
					
					@order_cancel.each do |ocn|
						if(ocn[:decision_cancel].nil? or (ocn[:decision_tobe_approved] && ocn[:approved_by_user_id].nil?))
							@ocn_pendings = true
							@ocn_entire_pendings = true if(ocn[:entire_order])
						elsif(ocn[:decision_cancel] && ocn[:entire_order])
							@ocn_entire_cancelled = true
						end
					end
				end
			end
			
			@show_pay_button = true
			@checkboxes_on_items = false
		end
		
		@delivery_cost_info = {} if(@delivery_cost_info.nil?)
		@render_javascripts = true
		@render_moderation_block = true
		

		@isAjax = (params[:ajax]=='Y')
		if(@isAjax)
			if(params[:info]=='Y')
				@render_moderation_block = false
			end
			@render_javascripts = false
			render layout: false
		end
	end
	
	
	def begin
		pparams = params.permit(:cart_uid, :noguest)
		
		@is_signed_user = false
		@is_admin_or_orderscreator = false
		@presaved_customers = false
		@order_user_safe_id = nil
		@user_cart_items_cnt = 0
		cart_user_id = nil
		@cart_no_guest = ((pparams[:noguest].present? && (pparams[:noguest] == '1')) ? '1' : '0')
		
		if(user_signed_in?)
			
		end
		
		if(!cart_user_id.nil?)
			suid_params = User.prepare_make_safe_id
			@order_user_safe_id = User.pub_safe_uid(suid_params, cart_user_id)
			
			cart_user = ((cart_user_id == current_user.id) ? current_user : User.where(id: cart_user_id).first)
			if(cart_user.present? && cart_user.customers_list.present?)
				@cur_customer_id = cart_user.current_customer_id
				@user_customers = Customer.sorted_customers_list(nil, cart_user.customers_list.keys, @cur_customer_id)
			end
			
			if(@user_customers.present?)
				@presaved_customers = true
				@scram_emails = [cart_user.email, cart_user.unconfirmed_email]

				cur_customer = @user_customers.select{|x| x.id == @cur_customer_id}.first
				@cur_customer_uid = cur_customer.static_pub_safe_uid(@customer_safeid_params) if(cur_customer.present?)
				
				@destinations = CustomerDestination.where(customer_id: @user_customers.collect{|x| x.id}, is_deleted: false).order('is_default DESC, orders_count DESC, created_at DESC').find_all
				@destinations = nil if(@destinations.first.blank?)
			end
			
		else
			pcookie_cart = cookies.encrypted[:cart]
			if(pcookie_cart.present?)
				
			end
		end

		@new_order_hash_uid = Time.now.utc.to_i.to_s + '.' + generate_rnd_chars(5)
		if(@is_signed_user)
			@order_stage = 'delivery_method'
			@form_time_now = Time.now.utc.to_i
			@form_hash = form_hash_generate((@cart_no_guest + ...), false)
		else
			@form_hash = form_hash_generate((@cart_no_guest + ...), true)
		end
	end
	
	
	def express
		pparams = params.permit(:uid, :fstamp, :fhash, :noguest)
		
		@express_order = true
		@order_user_safe_id = nil
		order_user_id = nil
		
		pparams[:uid] = pparams[:uid][0,SAFE_UID_MAX_LENGTH] if(pparams[:uid].present?)
		@new_order_hash_uid = ((pparams[:fstamp].present?) ? pparams[:fstamp].to_s[0,30] : '')
		@cart_no_guest = ((pparams[:noguest].present? && (pparams[:noguest] == '1')) ? '1' : '0')
		
		if(!form_hash_verify(pparams[:fhash], (......), ....))
			render 'error'
			return
		end
		
		if(user_signed_in?)
			authenticate_and_authorize_user_action
			verify_authorized

			
		else
			pcookie_cart = cookies.encrypted[:cart]
			if(pcookie_cart.present?)

			end
			
			make_list_of_available_delivery_methods
			if(!@available_delivery_methods.nil?)
				@total_cost_with_delivery = GenSetting.default_total_cost_include_delivery?
				@delivery_postcod_on = Order.post_office_pay_on_delivery_use_by_default?
				@delivery_no_available = @available_delivery_methods.select{|mk, mv| mv}.blank?
			end
			@delivery_method = GenSetting.default_available_delivery_method
			
			@order_stage = 'delivery_method'
			@form_time_now = Time.now.utc.to_i
			@form_hash = form_hash_generate((@cart_no_guest + ...), ....)
			render 'new'
		end
		
		return
	end
	
	
	def new
		pparams = params.permit(:ajax, :fhash, :ftime, :fstamp, :noguest, :order_express, :order_uid, :order_id, :order_stage, :order_stage_sub,
			:phash, :customer_select, :customer_uid, :customer_dest_uid, :delivery_method_select, :delivery_method, :customer_type_select, :individual_contact, :phone, :individual_anynm, :individual_mail,
			:email, :ind_fio, :ind_passp_num, :ind_passp_date, :ind_passp_issuer, :ind_addr, :ind_postcode, :ind_country, :ind_region, :ind_city, :ind_street, :ind_house,
			:ind_apartment, :legal_name, :legal_ogrn, :legal_inn, :legal_kpp, :legal_addr_ur, :legal_addr_post, :legal_dir_post, :legal_dir_name,
			:legal_person1_name, :legal_person1_phone, :legal_person1_mail, :legal_person2_name, :legal_person2_phone, :legal_person2_mail, :legal_delivery_addr,
			:legal_postcode, :legal_country, :legal_region, :legal_city, :legal_street, :legal_house, :legal_apartment, :dlv_price_type, :pay_type, :order_comment,
			:delivery_w_total_select, :delivery_postcod_select, :delivery_pickpoint_select, :delivery_company_select, :customer_dp_data_select
		)
		
		if(pparams[:order_stage].blank? && request.get?)
			ordr_id = nil
			if(Cart.total_count_from_cookie(cookies) > 0)
				pcookie_order = cookies.encrypted[:order]
				if(pcookie_order.present?)
					cookie_order = JSON.parse(pcookie_order)
					if(cookie_order.is_a?(Hash))
						if(cookie_order['id'].present?)
							
						end
					end
				end
			end
			
			if(@new_order_hash_uid.blank?)
				redirect_to '/cart/show'
				return
			end
			
			exist_order = find_order_by_hash_id(@new_order_hash_uid, ordr_id)
			if(exist_order[:order].present?)
				pparams[:delivery_method] = exist_order[:order][:delivery_type]
				pparams[:order_express] = (exist_order[:order][:express_order] ? "1" : "0")
			end
		else
			if(pparams[:fstamp].blank? or pparams[:fhash].blank?)
				redirect_to '/cart/show'
				return
			end
		end
		
		@isAjax = (pparams[:ajax]=='Y')
		@order_safe_uid = nil
		@order_user_safe_id = nil
		@is_signed_user = false
		@express_order = ((pparams[:order_express].present?) && (pparams[:order_express].to_s == "1"))
		@new_order_hash_uid = ((pparams[:fstamp].present?) ? pparams[:fstamp].to_s[0,30] : '') if(@new_order_hash_uid.blank?)
		@cart_no_guest = ((pparams[:noguest].present? && (pparams[:noguest] == '1')) ? '1' : '0') # не учитывать товары, добавленные под гостем, если есть такая галочка
		
		if(pparams[:delivery_method].present?)
			@delivery_method = pparams[:delivery_method].to_i
		elsif(pparams[:delivery_method_select].present?)
			@delivery_method = pparams[:delivery_method_select].to_i
		else
			@delivery_method = nil
			make_list_of_available_delivery_methods
			@delivery_no_available = @available_delivery_methods.select{|mk, mv| mv}.blank?
		end

		@pparams = {}
		@order = nil
		
		if(user_signed_in?)

		end
		
		if(pparams[:order_stage].present? && request.post?)
			if(pparams[:order_stage] == "delivery_method")
				if((!@delivery_method.nil? && DELIVERY_METHODS.has_key?(@delivery_method)) or @delivery_no_available)
					if(pparams[:customer_uid].present?)
						@customer_uid = pparams[:customer_uid][0,SAFE_UID_MAX_LENGTH]
						@customer_dest_uid = pparams[:customer_dest_uid][0,SAFE_UID_MAX_LENGTH] if(pparams[:customer_dest_uid].present?)
					end
					
					if(!form_hash_verify(pparams[:fhash], (@cart_no_guest + ... + @customer_dest_uid.to_s), ...))
						render 'error'
						return
					end
					
					save_cookie('stage', pparams[:order_stage], @new_order_hash_uid)

					if(@is_signed_user && @customer_uid.present?)
						customer_id = Customer.from_safe_uid(@customer_uid)
						if(!customer_id.nil? && current_user.customers_list.present? && !current_user.customers_list[customer_id.to_s].nil?)
							customer = Customer.where(id: customer_id).first
							if(customer.present?)
								customer.create_acl(current_user)
								if(customer.has_access?([:buy]))

								end
							end
						end
					end
					
					@order_stage = 'customer_contacts'
					@form_time_now = Time.now.utc.to_i
					@form_hash = form_hash_generate((@cart_no_guest + .... + @customer_dest_uid.to_s), ....)
					
					render 'new_contacts'
					return
				end
			
			elsif(pparams[:order_stage] == "customer_contacts")
				if((!@delivery_method.nil? && DELIVERY_METHODS.has_key?(@delivery_method)) or @delivery_no_available)
					@order_user_safe_id = pparams[:order_uid][0,SAFE_UID_MAX_LENGTH] if(pparams[:order_uid].present?)
					@order_safe_uid = nil
					@total_cost_with_delivery = (pparams[:delivery_w_total_select] == '1')
					@delivery_postcod_on = (pparams[:delivery_postcod_select] == '1')
					@delivery_cost_info = {}
					
					if(pparams[:customer_uid].present?)
						@customer_uid = pparams[:customer_uid][0,SAFE_UID_MAX_LENGTH]
						@customer_dest_uid = pparams[:customer_dest_uid][0,SAFE_UID_MAX_LENGTH] if(pparams[:customer_dest_uid].present?)
					end

					if(!form_hash_verify(pparams[:fhash], (@cart_no_guest + ..... + @customer_dest_uid.to_s), .....))
						render 'error'
						return
					end
					
					save_cookie('stage', pparams[:order_stage], @new_order_hash_uid)

					if(pparams[:customer_type_select].present?)
						# Verify contacts
						@result_err = validate_required_params(pparams, @delivery_method)
						if(@result_err['status_text'].present?)
							if(@isAjax)
								render json: @result_err
							else
								@pparams = pparams
								@order_stage = 'customer_contacts'
								@form_time_now = Time.now.utc.to_i
								@form_hash = form_hash_generate((@cart_no_guest + .....), ....)
					
								render 'new_contacts'
							end
							return
						end
						
						# Create Order in DB
						if(.........) # Anti-Bot Protection
							
							# Verify Captcha
							# Later here ....
							
							if(@is_signed_user)

							else
								creator_user_id = 0
								customer_id = 0
							end

							need_update_db = false
							
							exist_order = find_order_by_hash_id(@new_order_hash_uid)
							if(exist_order[:order].present? && !exist_order[:order].is_placed && exist_order[:order].has_access_create_new?(current_user, creator_user_id))

							else
								hash_str = ((exist_order[:hash_str].present?) ? exist_order[:hash_str] : generate_rnd_chars(5))
								new_order = Order.new({
									:user_id => creator_user_id, :visit_hash => @visitor_hash, :customer_id => customer_id, :hashstr => hash_str, :hashid => exist_order[:hash_id],
									:customer_type => pparams[:int_customer_type],
									:delivery_type => @delivery_method.to_i,
									:delivery_postoffice_cod => @delivery_postcod_on,
									:total_incl_delivery_to_customer => @total_cost_with_delivery,
									:express_order => @express_order,
									:express_order_prcnt => ((GenSetting.express_mode_enabled_to_new_orders?) ? GenSetting.express_mode_increase_percent : 0),
									:products => {},
									:prod_prices_incl_delivery => (Order.delivery_price_type_default == DELIVERY_COST_ADD_TO_PROD_PRICES)
								})
								
								not_existing_order = true
								need_update_db = true
							end
							
							if(!new_order.nil?)
								delivery_to_tk = (new_order[:delivery_type] == DELIVERY_METHOD_TO_TRANSPORT_COMPANY)
								delivery_to_post_office = (new_order[:delivery_type] == DELIVERY_METHOD_TO_POST_OFFICE)
								delivery_to_tk_or_post_office = (delivery_to_tk or delivery_to_post_office)
								
								need_delivery_addr = delivery_to_tk_or_post_office
								need_delivery_region_city = (need_delivery_addr or (new_order[:delivery_type] == DELIVERY_METHOD_TO_PICKPOINT))
								
								delivery_person = {}
								delivery_addr = {}
								
								
								if(pparams[:int_customer_type] == CUSTOMER_TYPE_FIZ_LICO)
									if(not_existing_order) or (new_order[:customer_contacts].blank?) or (new_order[:customer_contacts][:name1] != pparams[:individual_anynm]) or (new_order[:customer_contacts][:phone1] != pparams[:individual_contact]) or (new_order[:customer_contacts][:email1] != pparams[:individual_mail])
										new_order.customer_contacts = {
											:name1 => pparams[:individual_anynm],
											:phone1 => pparams[:individual_contact],
											:email1 => pparams[:individual_mail],
											:pay_type => 0
										}
										need_update_db = true
									end
									
									if(need_delivery_addr)
										delivery_addr[:postcode]  = pparams[:ind_postcode] if(delivery_to_post_office)
										delivery_addr[:street]    = pparams[:ind_street]
										delivery_addr[:house]     = pparams[:ind_house]
										delivery_addr[:apartment] = pparams[:ind_apartment]
										delivery_addr[:to_door]   = "1" if(pparams[:ind_addr].present? && (pparams[:ind_addr] == "1"))
									end
									
								else
									org_type = pparams[:int_org_type]
									
									if(not_existing_order) or (new_order[:customer_contacts].blank?) or (new_order[:customer_contacts][:name1] != pparams[:legal_person1_name]) or (new_order[:customer_contacts][:phone1] != pparams[:legal_person1_phone]) or (new_order[:customer_contacts][:email1] != pparams[:legal_person1_mail]) or (new_order[:customer_contacts][:name2] != pparams[:legal_person2_name]) or (new_order[:customer_contacts][:phone2] != pparams[:legal_person2_phone]) or (new_order[:customer_contacts][:email2] != pparams[:legal_person2_mail])
										new_order.customer_contacts = {
											:name1    => pparams[:legal_person1_name],
											:phone1   => pparams[:legal_person1_phone],
											:email1   => pparams[:legal_person1_mail],
											:name2    => pparams[:legal_person2_name],
											:phone2   => pparams[:legal_person2_phone],
											:email2   => pparams[:legal_person2_mail],
											:pay_type => 0
										}
										need_update_db = true
									end
									
									if(need_delivery_region_city)
										delivery_addr[:country]   = pparams[:legal_country] if(GenSetting.trade_between_countries?)
										delivery_addr[:region]    = pparams[:legal_region]
										delivery_addr[:city]      = pparams[:legal_city]
									end
									
									
									
									customer_legal_info = {
										:orgtype   => org_type,
										:name      => pparams[:legal_name],
										:ogrn      => pparams[:legal_ogrn],
										:inn       => pparams[:legal_inn],
										:addr_ur   => pparams[:legal_addr_ur],
										:addr_post => pparams[:legal_addr_post]
									}
									
									if((org_type != ORGANIZATION_TYPE_IND_PREDP) && (org_type != ORGANIZATION_TYPE_FIZ_LICO))
										customer_legal_info[:kpp] = pparams[:legal_kpp]
									end
									
								end
								
								
								if(need_update_db)
									if(new_order.save)
										if(not_existing_order)
											order_id = new_order.id
											save_cookie('oid', order_id, @new_order_hash_uid)
										else
											order_id = new_order[:id]
										end
									else
										order_id = nil
									end
								else
									order_id = new_order[:id]
								end
								
								if(!order_id.nil?)
									@order = new_order
									@safeid_params = Order.prepare_make_safe_id
									@order_safe_uid = Order.pub_safe_uid(@safeid_params, order_id)
								end
							end
						end
						
						if(@is_signed_user)
							@is_admin_or_orderscreator = current_user.is_admin_or_orderscreator?
							creator_user_id = ((@is_admin_or_orderscreator && pparams[:order_uid].present?) ? User.from_safe_uid(pparams[:order_uid][0,SAFE_UID_MAX_LENGTH]) : nil)
							creator_user_id = current_user.id if(creator_user_id.nil?)
							suid_params = User.prepare_make_safe_id
							@order_user_safe_id = User.pub_safe_uid(suid_params, creator_user_id)
						else
							creator_user_id = nil
						end
						
						@user_cart_items = {}
						prod_img_ids = []
						
						# Товары пользователя из тех, что есть в Корзине в базе данных
						if(!creator_user_id.nil?)
							user_cart_params = {user_id: creator_user_id, user_safe_id: @order_user_safe_id}
							if((Cart.open_user_cart(user_cart_params)) && (user_cart_params[:cart][:products].present?))

							end
						end
						
						# Товары гостя из Cookies
						cart_no_guest = (@cart_no_guest == '1')
						if(!cart_no_guest)
							pcookie_cart = cookies.encrypted[:cart]
							if(pcookie_cart.present?)
								cookie_cart = JSON.parse(pcookie_cart)
								if(cookie_cart.is_a?(Hash))
									if((cookie_cart['guest_items'].present?) && (cookie_cart['guest_items'].length > 0))
										guest_cart_prods = SellerProduct.for_order.where(id: cookie_cart['guest_items'].keys).find_all
										if(guest_cart_prods.present?)
											guest_mark = @user_cart_items.present?
											guest_cart_prods.each do |prod|

											end
											
											#if(marketplace_is_full?)
											#end
										end
									end
								end
							end
						end
						
						if(@order.is_express_mode?)
							order_express_mode = true
							expr_add_to_prods_prices = @order.express_cost_add_to_products_price?
						else
							order_express_mode = false
							expr_add_to_prods_prices = false
						end
						
						order_calc_prices_and_discounts(@user_cart_items, false, order_express_mode, expr_add_to_prods_prices)
						
						prod_img_ids.uniq!
						@prod_imgs = ProductsImage.where(id: prod_img_ids, b_allowed: true).find_all

						@safeid_params = SellerProduct.prepare_make_safe_id
						@order_prods = items_ids_hash_string(@safeid_params, @user_cart_items)
						@order_stage = 'prod_price'
						@form_time_now = Time.now.utc.to_i
						@form_hash = form_hash_generate((@cart_no_guest + ....), .....)
						
						render 'total_prod_price'
						return
					end

					@order_stage = 'customer_contacts'
					@form_time_now = Time.now.utc.to_i
					@form_hash = form_hash_generate((@cart_no_guest + ......), .....)
					
					render 'new_contacts'
					return
				end
				
			elsif(pparams[:order_stage] == "prod_price")
				@order_user_safe_id = pparams[:order_uid][0,SAFE_UID_MAX_LENGTH] if(pparams[:order_uid].present?)
				@order_safe_uid = pparams[:order_id][0,SAFE_UID_MAX_LENGTH] if(pparams[:order_id].present?)
				
				if(!form_hash_verify(pparams[:fhash], (@cart_no_guest + ......), .....))
					render 'error'
					return
				end

				
				
				order_id = Order.from_safe_uid(@order_safe_uid)
				if(order_id.nil?)
					render 'error'
					return
				end
				
				exist_order = find_order_by_hash_id(@new_order_hash_uid, order_id)
				if(exist_order[:order].blank?)
					render 'error'
					return
				end

				if(!exist_order[:order][:is_placed])
					str_dec = SellerProduct.pub_safe_uid_decode(pparams[:phash][0,n0])
					order_prods_params = {}
					SellerProduct.from_safe_uid_get_id(str_dec, nil, order_prods_params, ',')
					if(!order_prods_params.blank?)
						order_prods = str_dec.split(',')
						order_prods.pop
					else
						order_prods = nil
					end
					
					@order_items = {}
					@order_placed_ok = false
					if(order_prods.present?)
						order_prods.each do |prodcode|
							
						end
						
						if(@order_items.present?)
							@order = exist_order[:order]
							@delivery_method = @order[:delivery_type]
							@express_order = true if(@order.is_express_mode?) # overwrite the flag if order is express in DB

							if(@order.delivery_price_customer_allowed_choose_type?)
								if(pparams[:dlv_price_type].blank?)
									@dlv_price_type = Order.delivery_price_type_default
								elsif(pparams[:dlv_price_type] == 'alone')
									@dlv_price_type = DELIVERY_COST_ALONE_PRICE
								elsif(pparams[:dlv_price_type] == 'include')
									@dlv_price_type = DELIVERY_COST_ADD_TO_PROD_PRICES
								else
									@dlv_price_type = Order.delivery_price_type_default
								end
							else
								@dlv_price_type = Order.delivery_price_type_default
							end
							
							if(@order.is_express_mode?)
								order_express_mode = true
								expr_add_to_prods_prices = @order.express_cost_add_to_products_price?
							else
								order_express_mode = false
								expr_add_to_prods_prices = false
							end
							
							dlv_add_to_prods = (@dlv_price_type == DELIVERY_COST_ADD_TO_PROD_PRICES)
							@order.prod_prices_incl_delivery = dlv_add_to_prods if(@order.prod_prices_incl_delivery != dlv_add_to_prods)
							
							# CHANGE ITEM QUANTITY and Show total list again
							if((pparams[:order_stage_sub].present?) && (pparams[:order_stage_sub] == "prod_quantity")) 
								@order_prods = pparams[:phash]
								pparams = params.permit(:item_id, :quantity)
								
								
								if(pparams[:item_id].present?)
									if(pparams[:quantity].present? && pparams[:quantity].numeric?)
										prod_id = SellerProduct.from_safe_uid(pparams[:item_id][0,SAFE_UID_MAX_LENGTH])
										if(!prod_id.nil?) && (@order_items.has_key?(prod_id))
											new_value = SellerProduct.quantity_unit(prod_id, {qntraw: pparams[:quantity], quantity: nil})
											if(@order_items[prod_id][:cnt] != new_value)
												@order_items[prod_id][:cnt] = new_value
												order_items_prods = SellerProduct.for_order.where(id: @order_items.keys).find_all
												if(order_items_prods.present?)
													
												end
												
												order_calc_prices_and_discounts(@user_cart_items, false, order_express_mode, expr_add_to_prods_prices)

											end
										end
									end
								end

								render 'total_prod_price'
								return
							
							# MARK A NEW ORDER IS PLACED  AND  FILL IT WITH PRODUCTS
							else
								order_prods = SellerProduct.for_order.where(id: @order_items.keys).find_all
								if(order_prods.present?)
									order_prods.each{|prod| order_items_fill_new(@order, @order_items, prod, @order_items[prod[:id]][:cnt], true)}
	
									#if(marketplace_is_full?)
									#end
								end

								@delivery_cost_info = @order.get_delivery_charges
								order_calc_prices_and_discounts(@order_items, true, order_express_mode, expr_add_to_prods_prices)
							
								if(MARKETPLACE_SHOP or MARKETPLACE_RETAIL)
									@order.one_seller_id = 0
									@order.comments = pparams[:order_comment][0,256] if(pparams[:order_comment].present?)
								end
								
								if(!user_signed_in?) # Create random password to access this order for not registered user-customer
									
								end
								
								@order_placed_ok = @order.save
								if(@order_placed_ok)
									if(user_signed_in?)
										
									else
										user_id = nil
									end
	
									Cart.remove_from_cart(@order_items.keys, {user_id: user_id}, cookies)
									
									@order.send_operator__new_order
									@order.send_information__order_placed
									
									@waiting_delivery_cost = @order.waiting_delivery_charges?
									
									if(@order.waiting_prepay?)
										@more_items_in_cart = Cart.total_count_all(nil, cookies)
									end
									
									save_cookie('stage', nil, nil)
									save_cookie('oid', 0, nil)
									
									@paydoc_type = 'order'
									@form_time_now = Time.now.utc.to_i
									@form_hash = form_hash_generate((.....), .....)
									
									set_cabinet_breadcrumbs({:name => I18n.t(:orders, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => SITE_PATH_ADDRESS_ROOT_CANONICAL + orders_cabinet_index_path})
									render 'placed_success'
									return
								end
							end
						end
					end
				else
					@order_placed_ok = true
					@order = exist_order[:order]
					@waiting_delivery_cost = @order.waiting_delivery_charges?
					@delivery_cost_info = @order.get_delivery_charges
					@more_items_in_cart = Cart.total_count_all(nil, cookies)
					
					save_cookie('stage', nil, nil)
					
					@paydoc_type = 'order'
					@form_time_now = Time.now.utc.to_i
					@form_hash = form_hash_generate((.....), ....)
				
					set_cabinet_breadcrumbs({:name => I18n.t(:orders, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => SITE_PATH_ADDRESS_ROOT_CANONICAL + orders_cabinet_index_path})
					render 'placed_success'
					return
				end

				@order_error_text = '<p>Во время сохранения заказа произошла непредвиденная ситуация. Приносим извинения за доставленные неудобства.</p>'.html_safe
				render 'error'
				return
			
			elsif(pparams[:order_stage] == "pay_method")
				
				return
			end
		end
		
		if((@delivery_method.nil?) or (@delivery_method == 0))
			exist_order = find_order_by_hash_id(@new_order_hash_uid)
			if(exist_order[:order].present?)
				@delivery_method = exist_order[:order][:delivery_type]
			end
		end
		
		make_list_of_available_delivery_methods if(@available_delivery_methods.nil?)
		
		if(!@available_delivery_methods.nil?)
			@total_cost_with_delivery = GenSetting.default_total_cost_include_delivery?
			@delivery_postcod_on = Order.post_office_pay_on_delivery_use_by_default?
		end
		
		if(pparams[:customer_select] == 'existing') && (pparams[:customer_uid].present?)
			@customer_uid = pparams[:customer_uid][0,SAFE_UID_MAX_LENGTH]
			@customer_dest_uid = pparams[:customer_dest_uid][0,SAFE_UID_MAX_LENGTH] if(pparams[:customer_dest_uid].present?)
		end
		
		@delivery_method = GenSetting.default_available_delivery_method if(@delivery_method.nil?)
		@order_stage = 'delivery_method'
		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((......), .....)
	end
	
	
	def delete
	
	
	end
	
	
	def delete_item
		ret_json = {}
		ret_msg = I18n.t(:not_found_with_item, scope: [:dt_ishop, :orders])
		
		
		
		if(request.post? or (params[:ajax] == 'Y'))
			render json: ret_json
		else
			respond_to do |format|
				format.json { render json: ret_json }
				format.html { 
					if(bOk)
						flash[:notice] = ret_msg
					else
						flash[:alert] = ret_msg
					end
					redirect_to cabinet_index_path
				}
			end
		end
	end

	
	def change_delivery_charges
		bOk = false
		ret_json = {}
		
		if(@order.present?)
			pparams = params.permit(:shippment_charges, :delivery_charges)
			pparams[:shippment_charges] = nil if(pparams[:shippment_charges].blank? or !pparams[:shippment_charges].numeric?)
			pparams[:delivery_charges] = nil if(pparams[:delivery_charges].blank? or !pparams[:delivery_charges].numeric?)
			
			@order.set_delivery_charges_and_recalc_costs(pparams[:shippment_charges].to_f, !pparams[:shippment_charges].nil?, pparams[:delivery_charges].to_f, !pparams[:delivery_charges].nil?, false)
			if(@order.changed?)
				ret = @order.save_logged($current_user, $action_name, [:delivery_charges_from_seller, :delivery_charges_to_customer, :delivery_charges_ready, :total_incl_delivery_to_customer])
				if(ret.present?)
					if(ret[:saved])
						bOk = true
					else
						ret_json['status_text'] = 'Не удалось сохранить изменения !'
					end
				else
					ret_json['status_text'] = 'Изменения не произведены !'
				end
			end
		end

		ret_json['status'] = (bOk ? 'ok' : 'error')
		render_on_changes(ret_json)
	end
	
	
	def change_agree
		bOk = false
		bOk_SendInfo = false
		ret_json = {}
		
		if(@order.present?)
			@order.agree
			
			if(@order.agreed_at_changed?)
				ret = @order.save_logged($current_user, $action_name, nil)
				if(ret.present?)
					if(ret[:saved])
						bOk = true
						bOk_SendInfo = true
					else
						ret_json['status_text'] = I18n.t(:unable_to_save_changes, scope: [:dt_breeze, :messages])
					end
				else
					ret_json['status_text'] = I18n.t(:no_changes_made, scope: [:dt_breeze, :messages])
				end
			else
				if(@order.agreed_at.present?)
					ret_json['status_text'] = 'Заказ уже был одобрен ' + @order.agreed_at.in_time_zone(TZ_UTC_OFFSET_MOSCOW).to_formatted_s(:rus_post_date) + ' (мск).'
					bOk = true
				elsif(!@order.delivery_charges_ready)
					ret_json['status_text'] = I18n.t(:delivery_cost_waiting_calc, scope: [:dt_ishop, :orders])
				end
			end
		end

		ret_json['status'] = (bOk ? 'ok' : 'error')
		render_on_changes(ret_json)
		@order.send_information__order_agreed if(bOk_SendInfo && bOk)
	end
	
	
	def change_accept
		bOk = false
		bOk_SendInfo = false
		ret_json = {}
		
		if(@order.present?)
			if(@order.accepted_at.present?)
				
			elsif(@order.agreed_at.blank?)
				
			else
				can_accept = false
				if(@order[:prepaid_at].present?)
					
				elsif(GenSetting.accept_not_prepaid_orders_allowed?)
					if(GenSetting.confirm_accept_not_prepaid_orders?)
						
						if(params[:confirm].present?)
							if(check_frontend_confirmation(params[:confirm], cval_1, cval_2, @order[:created_at].to_i))
								can_accept = true
							end
						else
							
						end
					else
						can_accept = true
					end
				else
					ret_json['status_text'] = I18n.t(:msg_not_prepaid_disallowed_accept, scope: [:dt_ishop, :orders])
				end
				
				if(can_accept)
					ret = @order.accept
					if(ret.present?)
						if(ret[:saved])
							bOk = true
							bOk_SendInfo = true
						else
							ret_json['status_text'] = I18n.t(:unable_to_save_changes, scope: [:dt_breeze, :messages])
						end
					else
						ret_json['status_text'] = I18n.t(:no_changes_made, scope: [:dt_breeze, :messages])
					end
				end
			end
		end

		ret_json['status'] = (bOk ? 'ok' : 'error')
		render_on_changes(ret_json)
		@order.send_information__order_accepted if(bOk_SendInfo && bOk)
	end
	
	
	def change_delete_item
		if(request.format.html?)
			redirect_to cancel_orders_path(order_uid: @order_safe_uid, item_uid: @order_item_safe_uid)
			return
		end
		
		bOk = false
		ret_json = {}
		
		if(@order.present? && @order_item_id.present?)
			if(@order.cancelled_at.present? or @order.finished_at.present? or @order.deleted or @order.buyer_received_at.present? or @order.buyer_full_receive_confirmed)
				ret_json['status_text'] = I18n.t(:msg_unable_to_remove_items, scope: [:dt_ishop, :orders])
			else
				if(@order.agreed_at.blank?)
					
					
					if(params[:confirm].present?)
						if(check_frontend_confirmation(params[:confirm], cval_1, cval_2, @order[:created_at].to_i))
							
						else
							ret_json['status_text'] = 'Bad confirmation parameters !'
						end
					else
						order_item = @order[:products][@order_item_id.to_s]
						
						
					end
				else
					ret_json['visit_me'] = true
					ret_json['visit_me_method'] = 'get'
				end
			end
		else
			ret_json['status_text'] = ret_msg = I18n.t(:not_found_with_item, scope: [:dt_ishop, :orders])
		end
		ret_json['status'] = (bOk ? 'ok' : 'error')
		render_on_changes(ret_json, true)
	end
	
	
	def cancel
		bOk = false
		bOk_SendInfo = false
		ret_json = {}
		
		if(@order.present?)
			if(@order.cancelled_at.present?)
				ret_json['status_text'] = I18n.t(:msg_already_cancelled, scope: [:dt_ishop, :orders]) + ' ' + @order.cancelled_at.in_time_zone(TZ_UTC_OFFSET_MOSCOW).to_formatted_s(:rus_post_date) + ' (мск).'
				bOk = true
			elsif(@order.finished_at.present? or @order.deleted)
				ret_json['status_text'] = I18n.t(:msg_unable_cancel_finished, scope: [:dt_ishop, :orders])
			elsif(@order.buyer_received_at.present? or @order.buyer_full_receive_confirmed)
				ret_json['status_text'] = I18n.t(:msg_unable_cancel_received, scope: [:dt_ishop, :orders])
			else
				can_cancel = false
				
				if(request.format.json?)
					if(@order.agreed_at.blank? or @order[:products].blank? or @order[:products].select{|ord| (ord['removed'] != '1')}.blank?)
						
						if(params[:confirm].present?)
							if(check_frontend_confirmation(params[:confirm], cval_1, cval_2, @order[:created_at].to_i))
								can_cancel = true
							end
						else
							
						end
					
					else

					end
					
					if(can_cancel)
						ret = @order.cancel_if_not_agreed_not_paid
						if(ret.present?)
							
						else
							ret_json['status_text'] = I18n.t(:no_changes_made, scope: [:dt_breeze, :messages])
						end
					end
				
				elsif(request.format.html?)
					pparams = params.permit(:fhash, :ftime, :cancel_type_select, :type, :cancel_reason_select, :cancel_comment, :cheaper_comment)
					
					if(@order.products.blank? or (@order.products.size <= 1))
						@cancel_entire = true
					elsif(@order_item_id.present?)
						@cancel_items = true
					end
					@order_pub_id = @order.pub_visible_safe_id(false, false, false, true)
					
					set_cabinet_breadcrumbs({:name => I18n.t(:orders, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => orders_cabinet_index_path})
					set_cabinet_breadcrumbs({:name => @order_pub_id.to_s, :url => ('/orders/show' + '?' + URI.encode_www_form('order_uid' => @order_safe_uid))})
					set_cabinet_breadcrumbs({:name => I18n.t(:order_cancellation, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true})
					
					if(pparams[:fhash].present?)
						cancel_type_param = ((pparams[:type].present?) ? pparams[:type].to_s[0,10] : '')
						if(!form_hash_verify(pparams[:fhash], (.....)))
							render 'error'
							return
						end
						
						reason_code = ((pparams[:cancel_reason_select].present? && pparams[:cancel_reason_select].numeric?) ? pparams[:cancel_reason_select].to_i : 0)
						
						if(reason_code != 0) && ((cancel_type == 'entire') or (cancel_type == 'items'))

							items_to_remove = nil
							if(cancel_type == 'items')
								if(@order[:products].present?)
									if(params[:order_items_checkboxes].present? && params[:order_items_checkboxes].is_a?(Array))
										items_to_remove = []
										params[:order_items_checkboxes].each do |pid|
											pid = SellerProduct.from_safe_uid(pid)
											items_to_remove << pid if(!pid.nil?)
										end
									end

									if(items_to_remove.nil?)
										flash[:alert] = I18n.t(:msg_must_select_order_items, scope: [:dt_ishop, :orders])
										render
										flash[:alert] = nil
										return
									elsif((items_to_remove - @order[:products].map{|k,v| k.to_i}).present?)
										
									end
								end
								
								if(items_to_remove.blank?)
									render 'error'
									return
								end
								
								can_remove_safely = (@order.can_cancel_auto?(true) && @order[:one_seller_id].present?)
								
								if((fails != 0) && (fails == items_to_remove.length))
									@cancellation_duplicate = true
								else
									@order.recalculate_items_prices
								end
							else
								@order_cancel = OrdersCancellation.where(id: @order[:cancellations]).find_all
								if(@order_cancel.first.present?)
									@order_cancel.each do |ocn|
										if(ocn[:entire_order] && (ocn[:decision_cancel].nil? or (ocn[:decision_tobe_approved] && ocn[:approved_by_user_id].nil?) or ocn[:decision_cancel]))

											break
										end
									end
								end
							end
							
							if(@cancellation_duplicate)
								render 'cancel_submit'
								return
							end
							
							@order_cancel = OrdersCancellation.new({
								order_id: @order.id,
								order_year: @order.created_at.year,
								entire_order: (cancel_type == 'entire'),
								order_items: items_to_remove,
								reason_code: reason_code,
							})
							
							@create_success = @order_cancel.save
							if(@create_success)
								if(@order_cancel[:entire_order] && !@order_cancel[:decision_tobe_approved])
									ret = @order.cancel_if_not_agreed_not_paid(false,true,false)
									if(ret == true)
										
										@order.save_logged($current_user, $action_name, [:cancelled_at, :cancelled_by_user_id, :cancellations], false)
										@order_cancel.save
									end
								else
									if(@order_cancel[:entire_order])
										upd_params = [:cancellations]
									
									else
										upd_params = [:cancellations, :products]
										
										if(!@order_cancel[:decision_tobe_approved] && (cancel_type == 'items'))
											
										end
									end
									
									@order[:cancellations] = [] if(@order[:cancellations].nil?)
									@order[:cancellations] << @order_cancel.id
									@order.save_logged($current_user, $action_name, upd_params, false)
								end
							end

							render 'cancel_submit'
							return
						end
					end
					
					@prod_code_form = 0
					@no_remove_btn_on_items = true
					@checkboxes_on_items = true
					@checkboxes_on_items_required = true
					@checkboxes_on_items_checked = @order_item_id if(@cancel_items)
					
					@cancel_type = (@cancel_entire ? 'entire' : (@cancel_items ? 'items' : ''))
					@form_time_now = Time.now.utc.to_i
					@form_hash = form_hash_generate(.....)
					
					render
					return
				end
			end
		end

		ret_json['status'] = (bOk ? 'ok' : 'error')
		render_on_changes(ret_json, true)
		@order.send_information__order_cancelled if(bOk_SendInfo && bOk)
	end
	
	
	
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	private
	
	
	def render_on_changes (json_answer, render_action_view = false)
		if(params[:json] == 'show_answer')
			render json: json_answer
		else
			respond_to do |format|
				format.json {
					# add to json: <%= hidden_field_tag :authenticity_token, form_authenticity_token, id: :form_token %>
					render json: json_answer
				}
				format.html { 
					if(render_action_view)
						if(@order_pub_id.nil?)
							@order_pub_id = @order.pub_visible_safe_id(false, false, false, true)
							set_cabinet_breadcrumbs({:name => I18n.t(:orders, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => orders_cabinet_index_path})
							set_cabinet_breadcrumbs({:name => @order_pub_id.to_s, :url => ('/orders/show' + '?' + URI.encode_www_form('order_uid' => @order_safe_uid))})
							set_cabinet_breadcrumbs({:name => I18n.t(:order_cancellation, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true})
						end
						@json_answer = json_answer
						render action_name
					else
						if(json_answer['status'] == 'ok')
							flash[:notice] = json_answer['status_text']
						else
							flash[:alert] = json_answer['status_text']
						end
						redirect_to cabinet_index_path
					end
				}
			end
		end
	end

	
	def validate_required_params (pparams, delivery_method)
		err_bad_fields=[]
		err_bad_fields_why=[]
		err_json_text=''
		
		delivery_to_tk = (delivery_method == DELIVERY_METHOD_TO_TRANSPORT_COMPANY)
		delivery_to_rupost = (delivery_method == DELIVERY_METHOD_TO_POST_OFFICE)
		delivery_to_shop = (delivery_method == DELIVERY_METHOD_TO_SHOP)
		
		need_delivery_addr = (delivery_to_tk or delivery_to_rupost)
		need_delivery_region_city = (need_delivery_addr or (delivery_method == DELIVERY_METHOD_TO_PICKPOINT))
		
		@total_cost_with_delivery = false if(delivery_to_shop)
		@delivery_postcod_on = false if(!delivery_to_rupost)
		
		result_err = Customer.validate_required_params_before_create(pparams)
		if(result_err['status_text'].present?)
			err_bad_fields = result_err['bad_fields']
			err_bad_fields_why = result_err['bad_reasons']
			err_json_text = result_err['status_text']
		end
		
		if((pparams[:int_customer_type] == CUSTOMER_TYPE_FIZ_LICO) or (pparams[:customer_type_select] == "individual"))
			if(need_delivery_region_city)
				if(GenSetting.trade_between_countries?)
					pparams[:ind_country] = pparams[:ind_country][0,120].strip if(pparams[:ind_country].present?)
					if(pparams[:ind_country].blank?)
						err_json_text = 'Не указана Страна для доставки покупки.'
						err_bad_fields << 'ind_country'
						err_bad_fields_why << 'e'
					end
				end
				
				
			end
			
			if(delivery_to_tk)
				
			end
			
			if(need_delivery_addr)
				
			end
			
		elsif((pparams[:int_customer_type] == CUSTOMER_TYPE_LEGAL) or (pparams[:customer_type_select] == "legal"))
			if(need_delivery_region_city)
				
			end
			
			if(need_delivery_addr)
				
				
			end
		end
	
		return {'status' => 'error', 'status_text' => err_json_text, 'bad_fields' => err_bad_fields, 'bad_reasons' => err_bad_fields_why }
	end
	
	
	def find_order_by_hash_id (order_hash_uid, order_id = nil)
		return Order.find_order_by_hash_id(order_hash_uid, order_id = nil)
	end
	
	
	def save_cookie (name, value, id)
		pcookie_order = cookies.encrypted[:order]
		if(pcookie_order.present?)
			cookie_order = JSON.parse(pcookie_order)
			if(cookie_order.is_a?(Hash))
				cookie_order['id'] = id
				cookie_order[name] = value
			else
				cookie_order = {'id' => id, name => value}
			end
		else
			cookie_order = {'id' => id, name => value}
		end
		cookies.encrypted[:order] = {value: JSON.generate(cookie_order), expires: 7.days.from_now}
	end
	
	
	def items_ids_hash_string (safeid_params, items_list)
		return '' if(items_list.nil?)
		order_prods_orig = ''

		items_list.each do |prod_id, prod_props|
			order_prods_orig += SellerProduct.pub_safe_uid_lite(safeid_params, prod_id)
			order_prods_orig += '/' + prod_props[:cart_count].to_s + ','
		end
		order_prods_orig += safeid_params[:multiplier].to_s + '.' + safeid_params[:summand_hash].to_s
		str_enc = SellerProduct.pub_safe_uid_encode(safeid_params, order_prods_orig, true)
		return (str_enc + '-' + XXhash.xxh32(str_enc + ......).to_s)
	end
	
	
	def make_list_of_available_delivery_methods
		@available_delivery_methods = GenSetting.available_delivery_methods
		
		if(marketplace_is_shop? or marketplace_is_full_retail?)
			delivery_partners = SellerDeliveryPartner.includes(:delivery_partner).references(:delivery_partner).where('(seller_id = 0) AND (seller_delivery_partners.bactive IS TRUE) AND ((delivery_partners.bactive IS TRUE) OR (delivery_partners.bactive IS NULL))').order('delivery_partners.preferrable DESC, seller_delivery_partners.preferrable DESC, delivery_partners.sort_order ASC NULLS LAST, seller_delivery_partners.sort_order ASC NULLS LAST, delivery_partners.name ASC NULLS LAST, seller_delivery_partners.name ASC NULLS LAST').find_all
			if(delivery_partners.first.blank?)
				@available_delivery_methods[DELIVERY_METHOD_TO_TRANSPORT_COMPANY] = false
				@available_delivery_methods[DELIVERY_METHOD_TO_PICKPOINT] = false
			else
				
			end
		
		else
			
		end
	end
	
	
	def order_items_fill_new (order, items_arr, prod, item_cnt, for_order_save = false)
		item_id = prod[:id]
		
		if(!for_order_save)
			items_arr[item_id] = {
				id: item_id,
				name: prod[:name],
				prod_code: prod[:prod_code],
				prod_info: prod[:prod_info],
				lot_dealers: prod[:lot_dealers],
				lot_cost_type: prod[:lot_cost_type],
				lot_measure_type: prod[:lot_measure_type],
				lot_unit_type: prod[:lot_unit_type],
				lot_unit_count: prod[:lot_unit_count],
				cart_count: item_cnt,
				pbrand: prod[:seller_brand_id],
				gbrand: prod[:global_brand_id],
			}
			
			prod_price = SellerProduct.calc_pub_cost(prod, nil, true) # price with tax included
			if(!prod_price.nil?)
				items_arr[item_id][:lot_cost] = prod_price[:price]
				items_arr[item_id][:currency] = prod_price[:currency]
				items_arr[item_id][:tax] = prod_price[:tax_id]
				items_arr[item_id][:taxsys] = prod_price[:tax_system_id]
			end
	
			if(item_cnt != 0)
				items_arr[item_id]['pr_tbase'] = SellerProduct.calc_quantity_cost(SellerProduct.calc_pub_entire_lot_cost(items_arr[item_id], items_arr[item_id][:lot_cost]), item_cnt) # Total Base Price for entire quantity
			else
				items_arr[item_id]['pr_tbase'] = 0
				items_arr[item_id]['pr_ibase'] = SellerProduct.calc_pub_entire_lot_cost(items_arr[item_id], items_arr[item_id][:lot_cost]) + order.calc_item_price_markup(items_arr[item_id])
			end
		
		else # for save Order products to DB when order is placed
			items_arr[item_id] = {
				id: item_id,
				name: prod[:name],
				code: prod[:prod_code],
				info: prod[:prod_info],
				lct: prod[:lot_cost_type],
				lmt: prod[:lot_measure_type],
				lut: prod[:lot_unit_type],
				luc: prod[:lot_unit_count],
				pbrand: prod[:seller_brand_id],
				gbrand: prod[:global_brand_id],
				avail: prod[:available_count],
			}
			
			prod_price = SellerProduct.calc_pub_cost(prod, nil, true) # price with tax included
			if(!prod_price.nil?)
				
			end

			
			if(item_cnt != 0)
				items_arr[item_id]['pr_tbase'] = SellerProduct.calc_quantity_cost(SellerProduct.calc_pub_entire_lot_cost(items_arr[item_id], items_arr[item_id]['lc']), item_cnt) # Total Base Price for entire quantity
			else
				items_arr[item_id]['pr_tbase'] = 0
				items_arr[item_id]['pr_ibase'] = SellerProduct.calc_pub_entire_lot_cost(items_arr[item_id], items_arr[item_id]['lc']) + order.calc_item_price_markup(items_arr[item_id])
			end
		
		end
		items_arr[item_id][:photo] = prod[:photo_ids].take(3) if(prod[:photo_ids].present?)
		items_arr[item_id]['cnt'] = item_cnt

	end
	
	
	def order_calc_prices_and_discounts (items_list, for_order_save = false, order_express_mode, expr_add_to_prods_prices)
		redistrib_costs = {}
		prods_price_summ_base = 0
		
		items_list.each_pair{|pid, prod| prods_price_summ_base += prod['pr_tbase']}
		@order.products_count = items_list.length
		@order.apply_discounts(prods_price_summ_base, (!order_express_mode or !expr_add_to_prods_prices), items_list) # Calculate Discounts and Prices for sale this product: For-One Price, Total Price For entire item
		
		if(order_express_mode)
			
		end

		@order.redistribute_more_costs_to_products(redistrib_costs, items_list, prods_price_summ_base)
		@order.products = items_list
		@products_cost_total = @order.products_cost_total
	end
	
	
	def fill_form_with_customer_info (pparams, customer, customer_dest)
		pparams[:int_customer_type] = customer[:customer_type]
		
		if(customer[:customer_type] == CUSTOMER_TYPE_FIZ_LICO)
			if(customer[:customer_contacts].present?)
				pparams[:individual_anynm]   = customer[:customer_contacts]['name1']
				pparams[:individual_contact] = customer[:customer_contacts]['phone1']
				pparams[:individual_mail]    = customer[:customer_contacts]['email1']
			end
		else
			pparams[:customer_type_select] = 'legal'
			if(customer[:customer_contacts].present?)
				pparams[:legal_person1_name]  = customer[:customer_contacts]['name1']
				pparams[:legal_person1_phone] = customer[:customer_contacts]['phone1']
				pparams[:legal_person1_mail]  = customer[:customer_contacts]['email1']
			end
			
			if(customer[:customer_legal_info].present?)
				
			end
		end
		
		if(customer_dest.present?)
			if(customer_dest[:addr].present?)
				if(customer[:customer_type] == CUSTOMER_TYPE_FIZ_LICO)

				else

				end
			end
		end
	end
	
	
	def authenticate_and_authorize_user_action
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		authorize Order # Pundit authorization.
	end
	
	
	def authenticate_and_authorize_user_action_and_object
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		if(params[:order_uid].blank?)
			respond_to do |format|
				format.html {
					if(action_name == 'show')
						redirect_to orders_cabinet_index_path
					else
						redirect_to controller: 'welcome', action: 'error_access_denied'
					end
					
				}
				format.json {  
					render :json => [{:status => 'error', :error => 'Доступ запрещён!', :status_text => 'Доступ запрещён!'}], :status => 403
				}
			end
			return
		end
		
		@order_safe_uid = params[:order_uid][0,SAFE_UID_MAX_LENGTH]
		order_id = Order.from_safe_uid(@order_safe_uid)
		if(order_id.nil?)
			respond_to do |format|
				format.html {redirect_to controller: 'welcome', action: 'error_404'}
				format.json {render :json => [{:status => 'error', :error => 'Элемент не найден!', :status_text => 'Элемент не найден!'}], :status => 404}
			end
			return
		end
		
		@order = Order.where(id: order_id).first
		if(@order.blank?)
			respond_to do |format|
				format.html {redirect_to controller: 'welcome', action: 'error_404'}
				format.json {render :json => [{:status => 'error', :error => 'Элемент не найден!', :status_text => 'Элемент не найден!'}], :status => 404}
			end
			return
		end
		
		if(params[:item_uid].present?)
			@order_item_safe_uid = params[:item_uid][0,SAFE_UID_MAX_LENGTH]
			@order_item_id = SellerProduct.from_safe_uid(@order_item_safe_uid)
			if(@order_item_id.nil? or @order[:products].blank? or @order[:products][@order_item_id.to_s].nil?)
				respond_to do |format|
					format.html {redirect_to controller: 'welcome', action: 'error_404'}
					format.json {render :json => [{:status => 'error', :error => 'Элемент не найден!', :status_text => 'Элемент не найден!'}], :status => 404}
				end
				return
			end
		end

		authorize @order # Pundit authorization.
		return
	end
	
end