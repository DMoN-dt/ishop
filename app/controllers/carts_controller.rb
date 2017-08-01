class CartsController < ApplicationController
	before_action :set_footer_offer_info , :only => [:show]
	before_action :authenticate_and_authorize_user_action , :except => [:show, :change_item, :delete_item, :is_in_cart]
	after_action  :verify_authorized, :except => [:show, :change_item, :delete_item, :is_in_cart]
	
	def show
		pparams = params.permit(:uid, :ajax, :change_qnt, :item_id, :quantity, :noguest)
		@isAjax = (pparams[:ajax]=='Y')
		@cart_user_safe_id = nil
		cart_user_id = nil
		quantity_changed = false
		quantity_of_measure_type = nil
		prod_id = nil
		
		@mark_guest_prods = false # помечать товары Гостя, ниже изменится
		@cart_no_guest = (pparams[:noguest].present? && (pparams[:noguest] == '1')) # затемнить товары Гостя и не использовать при оформлении заказа
		@user_cart_prods = nil # товары из корзины пользователя (из БД)
		@guest_cart_prods = nil # товары из корзины гостя (из cookies)
		@guest_cart_items = nil # корзина гостя
		@user_cart_items = nil # корзина пользователя
		
		if(user_signed_in?)
			authenticate_and_authorize_user_action
			@is_admin_or_cartsmoder = current_user.is_admin_or_cartsmoder?
			if(@is_admin_or_cartsmoder)
				cart_user_id = User.from_safe_uid(pparams[:uid][0,SAFE_UID_MAX_LENGTH]) if(pparams[:uid].present?)
				cart_user_id = current_user.id if(cart_user_id.nil?)
			else
				cart_user_id = current_user.id
			end
			verify_authorized
			@is_signed_user = true
		else
			@is_signed_user = false
			@is_admin_or_cartsmoder = false
		end
		
		# Корзина Пользователя
		if(!cart_user_id.nil?)
			suid_params = User.prepare_make_safe_id
			@cart_user_safe_id = User.pub_safe_uid(suid_params, cart_user_id)
			user_cart_params = {user_id: cart_user_id, user_safe_id: @cart_user_safe_id}
			
			# Запрос на Изменение количества товара в корзине.
			if((pparams[:change_qnt] && pparams[:item_id].present?) && (pparams[:quantity].present? && pparams[:quantity].numeric?))
				pparams[:quantity] = pparams[:quantity].to_i
				if(pparams[:quantity] >= 0)
					prod_id = SellerProduct.from_safe_uid(pparams[:item_id][0,SAFE_UID_MAX_LENGTH]) if(prod_id.nil?)
					ret = change_user_cart(user_cart_params, prod_id, false, pparams[:quantity])

				end
			end
			
			# Получение списка товаров
			if((user_cart_params[:cart].present? || Cart.open_user_cart(user_cart_params)) && (user_cart_params[:cart][:products].present?))
				@user_cart_items = user_cart_params[:cart][:products]
				@user_cart_prods = SellerProduct.for_order.where(id: @user_cart_items.keys).find_all
			end
		end

		# Корзина Гостя
		pcookie_cart = cookies.encrypted[:cart]
		if(pcookie_cart.present?)
			# Запрос на Изменение количества товара в корзине.
			if((pparams[:change_qnt] && !quantity_changed && pparams[:item_id].present?) && (pparams[:quantity].present? && pparams[:quantity].numeric?))
				pparams[:quantity] = pparams[:quantity].to_i
				if(pparams[:quantity] >= 0)
					prod_id = SellerProduct.from_safe_uid(pparams[:item_id][0,SAFE_UID_MAX_LENGTH]) if(prod_id.nil?)
					ret = change_guest_cart(pcookie_cart, prod_id, false, pparams[:quantity])
					if(!ret.nil?)
						quantity_changed = true
						pcookie_cart = cookies.encrypted[:cart]
					end
				end
			end
			
			# Получение списка товаров
			cookie_cart = JSON.parse(pcookie_cart)
			if(cookie_cart.is_a?(Hash))
				if((cookie_cart['guest_items'].present?) && (cookie_cart['guest_items'].length > 0))
					@guest_cart_items = cookie_cart['guest_items']
					@guest_cart_prods = SellerProduct.for_order.where(id: @guest_cart_items.keys).find_all
					if(@guest_cart_prods.present?)
						@mark_guest_prods = true if((@user_cart_items.present?) && (@user_cart_items.length != 0))
					end
				end
				
				# Вывод товаров пользователя под гостем, если разрешено
				if(cart_user_id.nil? && cookie_cart['user'].is_a?(Hash))
					@user_cart_cookie_cnt = cookie_cart['user']['cnt'].to_i # для строчки уведомления
					@user_cart_invisible = true # для строчки уведомления
					# Отключено пока
					#if(cookie_cart['user']['uhid'].present?)
					#end
				end
			end
		end
		
		@parent_groups = SellerProduct.parent_nodes_list(@user_cart_prods, @guest_cart_prods)
		@safeid_params = SellerProduct.prepare_make_safe_id
		
		# Get porducts images
		prod_img_ids = []
		@user_cart_prods.each  {|prod| prod_img_ids += prod[:photo_ids] if(prod[:photo_ids].present?)} if(!@user_cart_prods.nil?)
		@guest_cart_prods.each {|prod| prod_img_ids += prod[:photo_ids] if(prod[:photo_ids].present?)} if(!@guest_cart_prods.nil?)
		prod_img_ids.uniq!
		@prod_imgs = ProductsImage.where(id: prod_img_ids, b_allowed: true).find_all
		
		if(@isAjax)
			render layout: false
		else
			if(@is_signed_user) # У пользователя: Корзина - это часть Личного кабинета
				set_cabinet_breadcrumbs({:name => I18n.t(:cart, scope: [:dt_ishop, :cabinet, :menu_main])})
			end
		end
	end
	
	
	# Добавление в корзину
	def change_item
		pparams = params.permit(:id, :job, :ajax)
		ret_json = {'status' => 'error', 'status_text' => 'Неправильный запрос'}
		
		if(pparams[:id].present?)
			pid = SellerProduct.from_safe_uid(pparams[:id][0,SAFE_UID_MAX_LENGTH])
			if(!pid.nil?)
				if(user_signed_in?)
					authenticate_and_authorize_user_action
					verify_authorized
					
					ret = change_user_cart({user_id: current_user.id}, pid, true, nil)
					if(!ret.nil?)
						
					end
					
				else
					ret = change_guest_cart(nil, pid, true, nil)
					ret_json = ret if(!ret.nil?)
				end

			end
		end
		
		ret_json.delete_if{|k,v| ((k == 'user_list') or (k == 'guest_list'))}
		respond_to do |format|
			format.json { render json: ret_json }
		end
	end
	
	
	def delete_item
		pparams = params.permit(:id)
		ret_json = {'status' => 'error', 'status_text' => 'Неправильный запрос'}
		
		if(pparams[:id].present?)
			pid = SellerProduct.from_safe_uid(pparams[:id][0,SAFE_UID_MAX_LENGTH])
			if(!pid.nil?)
				if(user_signed_in?)
					authenticate_and_authorize_user_action
					verify_authorized
					
					ret = change_user_cart({user_id: current_user.id}, pid, false, -1)
					if(!ret.nil?)

					end

				else
					ret = change_guest_cart(nil, pid, false, -1)
					ret_json = ret if(!ret.nil?)
				end
				
				if(ret_json['status'] == 'ok') && (ret_json['result']['noaction'] != true)
					price_summ = 0
					price_user_summ = 0
					is_any_noprice_notavailable = false
					is_user_noprice_notavailable = false

					if(ret_json['guest_list'].present?)
						if(ret_json['user_list'].present?)
							cart_list = ret_json['user_list'].merge(ret_json['guest_list']){|key, oldval, newval| newval.to_f + oldval.to_f}
							
							user_list_present = true
						else
							cart_list = ret_json['guest_list']
							user_list_present = false
						end
						guest_list_present = true
					else
						cart_list = ret_json['user_list']
						user_list_present = true
						guest_list_present = false
					end
					
					if(cart_list.present?)
						user_cart_prods = SellerProduct.for_price.where(id: cart_list.keys).find_all
						if(user_cart_prods.present?)
							user_cart_prods.each do |prod|
								if((prod[:lot_prices].present?) || SellerProduct.is_any_dealer_available?(prod))
									prod_price = SellerProduct.calc_pub_cost(prod, @parent_groups)
									if(prod_price.nil? or prod_price[:price].nil?)
										is_any_noprice_notavailable = true
									else
										price = prod_price[:price]
										pid_s = prod[:id].to_s
										if(user_list_present && ret_json['user_list'].has_key?(pid_s))
											price_user = SellerProduct.calc_quantity_cost(price, ret_json['user_list'][pid_s].to_f)
											price_user_summ += price_user
										else
											price_user = 0
										end
										
										if(guest_list_present && ret_json['guest_list'].has_key?(pid_s))
											price_guest = SellerProduct.calc_quantity_cost(price, cart_list[pid_s].to_f)
										else
											price_guest = 0
										end
										
										price_summ += price_user + price_guest
									end
								else
									is_any_noprice_notavailable = true
									if(user_list_present && ret_json['user_list'].has_key?(prod[:id].to_s))
										is_user_noprice_notavailable = true
									end
								end
							end
						end
					end
					
					if((price_summ == 0) && is_any_noprice_notavailable)
						price_summ = 'требует уточнения'
					else
						price_summ = ((is_any_noprice_notavailable) ? 'от ' : '') + SellerProduct.delimiter_thousands(price_summ)
					end
					
					if((price_user_summ == 0) && is_user_noprice_notavailable)
						price_user_summ = 'требует уточнения'
					else
						price_user_summ = ((is_user_noprice_notavailable) ? 'от ' : '') + SellerProduct.delimiter_thousands(price_user_summ)
					end
					
					ret_json['result']['price_total'] = price_summ
					ret_json['result']['price_user'] = price_user_summ
				end
			end
		end

		ret_json.delete_if{|k,v| ((k == 'user_list') or (k == 'guest_list'))}
		respond_to do |format|
			format.json { render json: ret_json }
		end
	end
	
	
	def is_in_cart
		pparams = params.permit(:id)
		ret_json = {'status' => 'error', 'status_text' => 'Неправильный запрос'}
		item_quantity = 0
		
		if(pparams[:id].present?)
			pid = SellerProduct.from_safe_uid(pparams[:id][0,SAFE_UID_MAX_LENGTH])
			if(!pid.nil?)
				pid_s = pid.to_s
				if(user_signed_in?)
					authenticate_and_authorize_user_action
					verify_authorized
					
					user_cart_params = {user_id: current_user.id}
					if(Cart.open_user_cart(user_cart_params))
						user_cart = user_cart_params[:cart][:products]
						if(user_cart.present? && user_cart.has_key?(pid_s))
							item_quantity = user_cart[pid_s]
						end
					end
				end
				
				cookie_cart = cookies.encrypted[:cart]
				if(cookie_cart.present?)
					cookie_cart = JSON.parse(cookie_cart)
					if(cookie_cart.is_a?(Hash))
						if(cookie_cart['guest_items'].is_a?(Hash) && cookie_cart['guest_items'].has_key?(pid_s))
							item_quantity += cookie_cart['guest_items'][pid_s]
						end
					end
				end
				
				ret_json = {'status' => 'ok', 'status_text' => '', 'result' => {'pid_cnt' => item_quantity}}
			end
		end

		respond_to do |format|
			format.json { render json: ret_json }
		end
	end
	
	
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	private
	
	
	def change_user_cart (user_cart_params, pid, plusone, quantity)
		return nil if(pid.nil?)
		ret_json = nil

		if(Cart.open_user_cart(user_cart_params))
			quantity_is_delete = (!quantity.nil? && (quantity == -1))
			quantity_is_zero = (!quantity.nil? && (quantity == 0))
			user_cart = user_cart_params[:cart][:products]
			user_cart = {} if(user_cart.blank?)
			pid_s = pid.to_s
			user_cart_items_count = user_cart.length
			b_changes = true
			
			if(!user_cart.has_key?(pid_s))

			else

			end
			user_cart_params[:cart][:products_count] = user_cart_items_count
			user_cart_params[:cart][:products] = user_cart

			if(b_changes)
				if(user_cart_params[:cart].save)
					cart_guest_items_count = 0
					pcookie_cart = cookies.encrypted[:cart]
					cookie_cart = JSON.parse(pcookie_cart) if(pcookie_cart.present?)
					cookie_cart = {} if(!cookie_cart.is_a?(Hash))
					
					if(user_cart_params[:user_id].present?) && (user_cart_params[:user_id] != 0)

					end
					
					if(cookie_cart['guest_items'].present? && cookie_cart['guest_items'].is_a?(Hash) && (cookie_cart['guest_cnt'].present?))

					end
	
					cookies.encrypted[:cart] = {value: JSON.generate(cookie_cart), expires: 14.days.from_now}
					
					ret_json = {'status' => 'ok', 'status_text' => '', 'result' => {'cnt' => cart_guest_items_count + user_cart_items_count, 'pid_cnt' => ((user_cart.has_key?(pid_s)) ? user_cart[pid_s] : nil)}, 'guest_list' => cookie_cart['guest_items'], 'user_list' => user_cart}
				else
					ret_json = {'status' => 'error', 'status_text' => 'Ошибка сохранения корзины в базу данных'}
				end
			else
				if(ret_json.nil?)
					ret_json = {'status' => 'ok', 'status_text' => '', 'result' => {'noaction' => true}, 'user_list' => user_cart}
				else
					ret_json['result']['noaction'] = true
					ret_json['user_list'] = user_cart
				end
			end
		end
		return ret_json
	end
	
	
	def change_guest_cart (cookie_cart, pid, plusone, quantity)
		return nil if(pid.nil?)
		ret_json = nil
		quantity_is_delete = (!quantity.nil? && (quantity == -1))
		quantity_is_zero = (!quantity.nil? && (quantity == 0))
		quantity_is_delete = true if(quantity_is_zero)
		
		cookie_cart = cookies.encrypted[:cart] if(cookie_cart.nil?)
		if(cookie_cart.blank?)
			cookie_cart = {'user' => {}, 'guest_items' => {}, 'guest_cnt': 0}
		else
			cookie_cart = JSON.parse(cookie_cart)
			if(!cookie_cart.is_a?(Hash))
				cookie_cart = {'user' => {}, 'guest_items' => {}, 'guest_cnt': 0}
			else
				cookie_cart['guest_items'] = {} if(!cookie_cart['guest_items'].is_a?(Hash))
				cookie_cart['user'] = {} if(!cookie_cart['user'].is_a?(Hash))
			end
		end
		
		pid_s = pid.to_s
		cookie_cart['guest_items'].delete_if{|k, v| v.to_i == 0}


		if(!cookie_cart['guest_items'].has_key?(pid_s))
			
		else
			
		end

		if(can_save)
			cookies.encrypted[:cart] = {value: JSON.generate(cookie_cart), expires: 14.days.from_now}
			ret_json = {
				'status' => 'ok',
				'status_text' => '',
				'result' => {
					'cnt' => cart_guest_items_count + cart_user_items_count,
					'pid_cnt' => ((cookie_cart['guest_items'].has_key?(pid_s)) ? cookie_cart['guest_items'][pid_s] : nil)
				},
				'guest_list' => cookie_cart['guest_items']
			}
		end
		
		ret_json['noaction'] = !b_changes
		
		return ret_json
	end
	
	
	def authenticate_and_authorize_user_action
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		authorize Cart # Pundit authorization.
	end
end
