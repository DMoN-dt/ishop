MERCHANT_PAYMENT_STAGE_CHECK_ORDER  = 1
MERCHANT_PAYMENT_STAGE_PAY_SUCCEED  = 2

MERCHANT_PAYMENT_ANSWER_ACCEPT      = 1
MERCHANT_PAYMENT_ANSWER_BAD_CRC     = 2
MERCHANT_PAYMENT_ANSWER_NOT_FOUND   = 3
MERCHANT_PAYMENT_ANSWER_BAD_PARAMS  = 4


require 'common/merchant_yakassa'


class PaymentsController < ApplicationController
	#protect_from_forgery with: :null_session, :only => [:check_order, :success]
	skip_before_action :verify_authenticity_token, :only => [:check_order, :success]
	
	before_action :authenticate_and_authorize_user_action , :except => [:pay, :check_order, :success, :onsucceed, :onfailure]
	after_action  :verify_authorized, :except => [:pay, :check_order, :success, :onsucceed, :onfailure]

	def pay
		if(user_signed_in?)
			authenticate_and_authorize_user_action
			@is_admin_or_orderscreator = current_user.is_admin_or_orderscreator?

			verify_authorized
			@is_signed_user = true
		else
			@is_signed_user = false

		end
		
		@is_partner_rs = false
		
		if(request.get?)
			pparams = params.permit(:sid, :id, :uid, :mid, :mtoken)
			# sid может содержать метки для этой ссылки:
			#   список товаров скрыт от всех
			#   список товаров скрыт от гостей
			#
			# запись в бд может содержать:
			#   user_id пользователя, который может получить доступ к этому счёту, помимо покупателя и продавца.
			#   время действия счёта
			#
			# если доступ имеется, тогда:
			#   если не гость, то проверить это заказ этого покупателя или нет и написать.
			#   если не его или гость, тогда:
			#     если скрыт от всех - написать, что покупатель предпочёл скрыть от всех список товаров.
			#     иначе если гость
			#       если скрыт от гостей - предложить войти
			#
			
			
			@oAcl = AccessList.new
			@oAcl.set_user(@is_signed_user, current_user)
			
			# Get access mask from URL
			if(pparams[:sid].present?)
				pparams[:id] = nil
				pparams[:uid] = nil
				pparams[:sid] = pparams[:sid][0,SID_URL_MAX_LENGTH]
				
				url_acl = accept_url_acl_sid_info(@oAcl, pparams[:sid])
				return if(url_acl.nil?)
				doc_info = url_acl[:doc_info]
			else
				pparams[:id] = pparams[:id][0,SAFE_UID_MAX_LENGTH] if(pparams[:id].present?)
				pparams[:uid] = pparams[:uid][0,5] if(pparams[:uid].present?)
				if(pparams[:uid].blank?)
					redirect_to controller: 'welcome', action: 'error_access_denied'
					return
				end
				doc_info = Document.from_pub_visible_safe_id(pparams[:id], false, true)
			end

			if((!doc_info.nil?) && (doc_info[:shop] == SAFE_UID_PAYDOCUMENT_SHOP_ID))
				sql = "(id = ?) and (to_char(created_at, 'YY') = ?)"
				if(doc_info[:doc_type] == DOC_TYPE_ORDER)
					@order = Order.where(sql, doc_info[:id], doc_info[:doc_year].to_s).first
					doc = @order
				elsif(doc_info[:doc_type] == DOC_TYPE_PAY_INVOICE)
					if(doc_info[:doc_rs] == DOC_RELATIONSHIP_CUSTOMER)
						@pay_invoice = PayInvoiceCustomer.where(sql, doc_info[:id], doc_info[:doc_year].to_s).first
					elsif(doc_info[:doc_rs] == DOC_RELATIONSHIP_PARTNER)
						@pay_invoice = PayInvoicePartner.where(sql, doc_info[:id], doc_info[:doc_year].to_s).first
					else
						@pay_invoice = nil
					end
					doc = @pay_invoice
				end
				
				@is_partner_rs = (doc_info[:doc_rs] == DOC_RELATIONSHIP_PARTNER)
				
				if(doc.present?)
					if(doc[:hashstr].present?)
						if((!pparams[:uid].nil? && (doc[:hashstr] != pparams[:uid])) or (pparams[:sid].present? && (doc[:hashstr] != url_acl[:sid][:idhashstr])))
							redirect_to controller: 'welcome', action: 'error_404'
							return
						end
					end
					
					@sid_param = pparams[:sid]
					doc.acl_set_and_merge(@oAcl)
					
					if(doc_info[:doc_type] == DOC_TYPE_ORDER)
						if(!@order.has_access?([:pay]))
							redirect_to controller: 'welcome', action: 'error_access_denied'
							return
						end
						
						@paydoc_type = 'order'
						safeid_params = Order.prepare_make_safe_id
						@paydoc_safe_uid = Order.pub_safe_uid(safeid_params, @order[:id])
						if(@order[:customer_contacts].present?) && (@order[:customer_contacts][:pay_type].present?)
							@pay_type_exist = (PAY_TYPES.include?(@order[:customer_contacts][:pay_type].to_i))
						end
						
						@acl_view_delivery_addr = @order.has_access?([:view_delivery_addr])
						@acl_view_customer_legal_info = @order.has_access?([:view_customer_legal_info])
						@acl_view_contacts = @order.has_access?([:view_contacts])

						if(@acl_view_customer_legal_info or @acl_view_contacts)
							@customer = Customer.where(id: @order[:customer_id]).first if(@order[:customer_id] != 0)
						end
						
					elsif(doc_info[:doc_type] == DOC_TYPE_PAY_INVOICE)
						@paydoc_type = 'invoice'
						safeid_params = Document.prepare_make_safe_id
						@paydoc_safe_uid = Document.pub_safe_uid(safeid_params, @pay_invoice[:id])
					end
					
					@id_hashstr = doc[:hashstr]
					@pay_doc_type = doc_info[:doc_type]

				else
					redirect_to controller: 'welcome', action: 'error_404'
					return
				end
			else
				redirect_to controller: 'welcome', action: 'error_404'
				return
			end
			
		elsif(request.post?)
			pparams = params.permit(:paydoc, :paydoc_id, :order_id, :pay_partner, :ftime, :fstamp, :fhash, :sidacl, :pay_stage, :pay_type, :pay_method, :pay_svc_method)
			flash[:alert] = nil
			@paydoc_type = pparams[:paydoc][0,20] if(pparams[:paydoc].present?)
			@paydoc_safe_uid = pparams[:paydoc_id][0,SAFE_UID_MAX_LENGTH] if(pparams[:paydoc_id].present?)
			@id_hashstr = ((pparams[:fstamp].present?) ? pparams[:fstamp].to_s[0,5] : '')
			
			if(pparams[:pay_stage].present?)
				if(pparams[:pay_stage] == "pay_method")
					pay_type = ((pparams[:pay_type].present? && pparams[:pay_type].numeric?) ? pparams[:pay_type].to_i : 0)
					if((pay_type == 0) or !form_hash_verify(pparams[:fhash], ....))
						render 'error'
						return
					end
					
					
					@form_time_now = Time.now.utc.to_i.to_s
					@form_hash = form_hash_generate((.....), .....)
					return
				
				elsif(pparams[:pay_stage] == "pay_bank_load_payment")
					pay_type = ((pparams[:pay_type].present?) ? PAY_TYPES[pparams[:pay_type][0,20]].to_i : 0)
					
					@is_partner_rs = (pparams[:pay_partner].present? && (pparams[:pay_partner] == '1'))
					
					form_hash_text = ....
					form_hash_text += (@is_partner_rs ? '1' : '0') if(pparams[:pay_partner].present?)
					
					if((pay_type == 0) or (pay_type != PAY_TYPE_BANK_PAY_INVOICE) or !form_hash_verify(pparams[:fhash], ....))
						render 'error'
						return
					end

					find_order_or_payinvoice(pparams)

					return
				
				elsif(pparams[:pay_stage] == "pay_type")
					pay_type = ((pparams[:pay_type].present?) ? PAY_TYPES[pparams[:pay_type][0,20]].to_i : 0)
					@is_partner_rs = (pparams[:pay_partner].present? && (pparams[:pay_partner] == '1'))
					
					form_hash_text = ....
					form_hash_text += (@is_partner_rs ? '1' : '0') if(pparams[:pay_partner].present?)
					
					if((pay_type == 0) or !form_hash_verify(pparams[:fhash], .....))
						render 'error'
						return
					end

					# Check access mask stored from previous URL-get
					if((pay_type == PAY_TYPE_BANK_PAY_INVOICE) && pparams[:sidacl].present?)
						pparams[:sidacl] = pparams[:sidacl][0,150]
						
						@oAcl = AccessList.new
						@oAcl.set_user(@is_signed_user, current_user)
						
						url_acl = accept_url_acl_sid_info(@oAcl, pparams[:sidacl])
						return if(url_acl.nil?)
						
						if(@id_hashstr != url_acl[:sid][:idhashstr])
							redirect_to controller: 'welcome', action: 'error_access_denied'
							return
						end
						
						@sid_param = pparams[:sidacl]
					else
						url_acl = nil
					end

					# save new pay_type to order or pay_invoice after pay
					find_order_or_payinvoice(pparams)
					collect_pay_methods(pay_type, @is_partner_rs)
					
					if(pay_type == PAY_TYPE_BANK_PAY_INVOICE)
						if(!@payinvoice.nil?)
						# show payinvoice
					
						elsif(!@order.nil?)
							if(!url_acl.nil?)
								if(url_acl[:doc_info][:id] != @order[:id])
									redirect_to controller: 'welcome', action: 'error_access_denied'
									return
								end
							end
							if(@order[:is_placed] && @order[:agreed_at].present?)
								if(!@order[:customer_id].nil? && (@order[:customer_id] != 0))
									
									
									# Create new Pay Invoice if existing not found
									if(@pinv_wait_pay.blank?)
										if(@order.pay_allowed?)
											pay_invoice = PayInvoiceCustomer.new({hashstr: generate_rnd_chars(5), doc_activated: true, doc_client_id: @customer[:id], doc_type: DOC_TYPE_PAY_INVOICE, doc_year: Date.today.year, doc_parent_type: DOC_TYPE_ORDER, doc_parent_id: @order[:id]})
											if(!pay_invoice.nil?)
												
												if(@order[:products].present?)
													pay_invoice[:doc_fields] = {}
													n = 0
													@brandList = {}
													brand_name = nil
													
													@order[:products].each_pair do |pid, pprops|
														if(pprops.present?)
															
															
															pay_invoice[:doc_fields][n] = .....
															n += 1
														end
													end

												end
												
												if(pay_invoice.save)
													@pinv_wait_pay = pay_invoice
												end
											end
										end
									end
								end
							else
								return
							end
						else
							return
						end
						
						@rekvizit = GenSetting.where("setgroup = 'rekvizit'").first
						@rekvizit = (((@rekvizit.present?) && (@rekvizit[:setts].present?)) ? @rekvizit[:setts] : nil)
					end
					
					return
				
				elsif(pparams[:pay_stage] == "pay_service")
					@pay_type = ((pparams[:pay_type].present? && pparams[:pay_type].numeric?) ? pparams[:pay_type].to_i : 0)
					if(!form_hash_verify(pparams[:fhash], ....))
						render 'error'
						return
					end
					
					return if(find_order_or_payinvoice(pparams).nil?)
					show_pay_confirm_page(pparams)
					
					return
				end
			end
			
			@new_order_hash_uid = ((pparams[:fstamp].present?) ? pparams[:fstamp].to_s[0,30] : '')
			if(!form_hash_verify(pparams[:fhash], .....))
				render 'error'
				return
			end
			
			find_order_or_payinvoice(pparams, false)
		end
		
		collect_pay_methods
	end
	
	
	# ############################################################################################### #
	# Проверка корректности параметров платежа до того, как платёжная система засчитает оплату заказа #
	def check_order 
		answer_params = {current_stage: MERCHANT_PAYMENT_STAGE_CHECK_ORDER, for_me: false }
		
		# Откидывать запросы не для этого ID или с неправильной CRC
		return if(merchant_request_reject_bad(params, answer_params))
		
		# Поиск платёжки, ожидающей оплаты, а также заказа/счёта/покупателя/контрагента
		pay_docs = merchant_find_payment_for_request(params, answer_params[:pay_service], true) # только ожидающие оплаты платежи
		if(pay_docs.nil?)
			merchant_answer(MERCHANT_PAYMENT_ANSWER_BAD_PARAMS, params, answer_params)
			return
		end
		
		# Проверка запроса на соответствие платёжным документам
		return if(merchant_request_verify_paydocs(params, answer_params, pay_docs))
		ret = answer_params[:summ_validity]
		
		# Если сумма оплаты или метод оплаты не были указаны при формировании платёжки, тогда сделать это сейчас
		payment_update = {}
		if(pay_docs[:payment][:summ_paycash].nil?)

		end

		
		# Формирование ответа платёжной системе
		answer_params[:summ] = ret[:summ]
		merchant_answer(MERCHANT_PAYMENT_ANSWER_ACCEPT, params, answer_params)
		return
	end
	
	
	# ############################################################################### #
	# Сообщение от платёжной системы об успешном платеже (снятии/замораживании денег) #
	def success
		answer_params = {current_stage: MERCHANT_PAYMENT_STAGE_PAY_SUCCEED, for_me: false, my_time: true}
		
		# Откидывать запросы не для этого ID или с неправильной CRC
		return if(merchant_request_reject_bad(params, answer_params))
		
		# Поиск платёжки, ожидающей оплаты или уже оплаченной, а также заказа/счёта/покупателя/контрагента
		pay_docs = merchant_find_payment_for_request(params, answer_params[:pay_service], false) # false = найти даже уже оплаченные документы
		if(pay_docs.nil?)
			merchant_answer(MERCHANT_PAYMENT_ANSWER_BAD_PARAMS, params, answer_params)
			return
		end
		
		# Проверка запроса на соответствие платёжным документам
		return if(merchant_request_verify_paydocs(params, answer_params, pay_docs))
		ret = answer_params[:summ_validity]
		
		# Повторный запрос уже оплаченного платежа
		if((pay_docs[:payment][:paid_at]) && (pay_docs[:paid_this] == true))
			answer_params[:summ] = ret[:summ]
			merchant_request_repeat_paid(params, answer_params)
			return
		end
		
		# Если сумма оплаты или метод оплаты не были указаны при формировании платёжки, тогда сделать это сейчас
		if(pay_docs[:payment][:summ_paycash].nil?)

		end
		pay_docs[:payment][:pay_svc_method] = ret[:pay_method_id] if(pay_docs[:payment][:pay_svc_method].blank?)
		
		# Записать в платёжку информацию о платеже, предоставленную платёжной системой
		pay_docs[:payment][:auto_process] = true
		pay_docs[:payment][:pay_type] = PAY_TYPE_ONLINE
		merchant_payment_store_data(params, answer_params[:pay_service], pay_docs)
		
		# Формирование ответа платёжной системе
		merchant_answer(MERCHANT_PAYMENT_ANSWER_ACCEPT, params, answer_params)
		
		# Обновление платёжки в БД.
		pay_docs[:payment].save
		
		# Принять оплату и засчитать её в документах/заказе
		pay_docs[:payment].accept_pay(pay_docs[:order], pay_docs[:pay_invoice])
		return
	end
	
	
	# ################################### #
	# Вернуться в магазин: ОПЛАТА УСПЕШНО #
	def onsucceed
		
	end
	
	
	# ###################################### #
	# Вернуться в магазин: ОПЛАТА НЕ УСПЕШНО #
	def onfailure
		
	end
	
	
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	private
	
	
	def authenticate_and_authorize_user_action
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		authorize Payment # Pundit authorization.
	end
	
	
	def find_order_or_payinvoice (pparams, only_hashstr = true)
		if(!@paydoc_safe_uid.nil?)
			if(@paydoc_type == 'order') # Оплата Заказа
				order_id = Order.from_safe_uid(@paydoc_safe_uid)
				if(!order_id.nil?)
					exist_order = ((only_hashstr) ? Order.find_order_by_hashstr(@id_hashstr, order_id) : Order.find_order_by_hash_id(@new_order_hash_uid, order_id)[:order])
					if(exist_order.present?)
						@order = exist_order
						@id_hashstr = @order[:hashstr]
					end
				end
	
			elsif(@paydoc_type == 'invoice') # Оплата Счёта
			
			end
		end
		
		if((!@order.nil?) && (!@payinvoice.nil?))
			@order_error_text = 'Заказ или счёт на оплату не найдены !'
			render 'error'
			return nil
		end
		return true
	end
	
	
	def collect_pay_methods (pay_type = nil, is_partner = false)
		
	end
	
	
	def show_pay_confirm_page(pparams, pay_service = nil)
		# Create Payment to wait for money come
		if(!@paydoc_safe_uid.nil?)
			if(pay_service.nil?)
				
			end
			if(pay_service.present?)
				
				@pay_service_params = pay_service[:params] if(pay_service[:params].present?)
			else
				render 'error'
				return nil
			end
		end
		
		if(!@pay_service_params.nil?)
			if((payment.present?) && (!payer_id.nil?))
				
			else
				flash[:alert] = 'Платёж не создан, либо покупатель не существует !'
			end
		else
			flash[:alert] = 'Не указаны параметры платёжной системы в настройках сайта !' if(flash[:alert].nil?)
		end

		
		@pay_stage = 'pay_confirm_online'
	end
	
	
	###  MERCHANT Methods ###
	
	def merchant_is_for_me? (params, pay_service)
		if(pay_service[:id] == PAYMENT_SERVICE_YANDEX_KASSA)
			return Merchant::is_for_me_from_yandex_kassa?(params, pay_service)
		end
		return false
	end

	
	def merchant_detect_pay_service_and_check_crc (params, stage_action)
		if(params[:shopId].present? && params[:md5].present?) # shopId and MD5 presents, so it looks like a Yandex.Kassa
			if(params[:md5].length == 32)
				pay_service = PaymentService.where("(id = ?) and (is_enabled) and (params IS NOT NULL)", PAYMENT_SERVICE_YANDEX_KASSA).first
				if(pay_service.present?)
					crc_check = (Merchant.calc_crc_yandex_kassa(params, pay_service[:params]['shop_password'], stage_action) == params[:md5])
					return {pay_service: pay_service, crc_valid: crc_check}
				end
			else
				return {pay_service: nil, crc_valid: false}
			end
		end
		return nil
	end
	
	
	def merchant_query_is_valid_and_for_me? (params, stage_action)
		crc_check = merchant_detect_pay_service_and_check_crc(params, stage_action)
		if(!crc_check.nil?)
			if(!crc_check[:pay_service].nil?)
				crc_check[:for_me] = merchant_is_for_me?(params, crc_check[:pay_service])
			end
			return crc_check
		end
		return nil
	end
	
	
	def merchant_find_payment_for_request (params, pay_service, only_waiting_pay = false)
		# Detect Pay Document and verify ID
		fparams = {shop_id: SAFE_UID_PAYDOCUMENT_SHOP_ID}
		if(pay_service[:id] == PAYMENT_SERVICE_YANDEX_KASSA)

		end
		
		return merchant_pay_documents(params, fparams, pay_service, only_waiting_pay)
	end
	
	
	def merchant_find_payment (payment_params)
		payment_params = {} if(payment_params.nil?)
		payment = nil
		paid = false
		
		
		
		return {payment: payment, paid: paid}
	end
	
	
	def merchant_pay_documents (params, fparams, pay_service, only_waiting_pay = false)
		bOk = false
		bPaid = false
		payinvoice_info = nil
		order_info = nil
		doc_info = nil
		
		payment = nil
		payer = nil
		order = nil
		pay_invoice = nil

		if(fparams[:doc_enc_id].present?)
			
		end
		
		if(fparams[:payment_safe_id].present?)
			
		end
		
		if(fparams[:customer_safe_id].present?)
			
			return nil if(payer.nil?)
		end
		
		# Поиск заказа/счёта с проверкой оплачен или нет
		if(!order_info.nil?)
			
		
		elsif(!payinvoice_info.nil?)
			sql_query = "(id = ?) "
			sql_query += " and (paid_at IS NULL)" if(only_waiting_pay)
			if(doc_info[:doc_rs] == DOC_RELATIONSHIP_CUSTOMER)
				pay_invoice = PayInvoiceCustomer.where(sql_query, payinvoice_info[:id]).first
			elsif(doc_info[:doc_rs] == DOC_RELATIONSHIP_PARTNER)
				pay_invoice = PayInvoicePartner.where(sql_query, payinvoice_info[:id]).first
			end
		end
		
		# Проверка соответствия документов друг другу
		if(payment.present?)
			if(order.present?)
				
			elsif(pay_invoice.present?)
				
			elsif(payer.present?)
				
			end
		
		elsif(payer.present?)
			payment_params = {pay_service_id: pay_service[:id], payer_id: payer[:id]}
			if(!only_waiting_pay)
				payment_params[:check_paid_this_request] = true
				payment_params[:transact_id] = merchant_request_transaction_id(params, pay_service)
			end
			if(order.present?)
				
			elsif(pay_invoice.present?)
				
			end
		end
		
		if(bOk)
			bPaid = (payment_info[:paid] == true)
			return {found: true, paid_this: bPaid, payment: payment, customer: customer, partner: partner, order: order, pay_invoice: pay_invoice, relationship: ((order_info.nil?) ? nil : order_info[:doc_rs])}
		else
			return {found: false}
		end
	end
	
	
	def merchant_request_transaction_id (params, pay_service)
		if(pay_service[:id] == PAYMENT_SERVICE_YANDEX_KASSA)
			id = Merchant::request_transaction_id_yandex_kassa(params)
		else
			id = nil
		end
		return id
	end
	
	
	def merchant_pay_method_valid? (params, pay_docs, pay_svc_method)
		
	end
	
	
	def merchant_pay_summ_inside_range? (summ, currency, test_arr)
		
	end
	
	
	def merchant_pay_summ_valid? (params, pay_docs, pay_service, pay_svc_method)
		
		return ret
	end
	
	
	def merchant_payment_store_data (params, pay_service, pay_docs)
		
	end
	
	
	def merchant_answer(answer_code, params, answer_params)
		if(answer_params[:pay_service].nil?)
			head(444)
			return
		end
		
		if(answer_params[:pay_service][:id] == PAYMENT_SERVICE_YANDEX_KASSA)
			ret = Merchant::answer_yandex_kassa(answer_code, answer_params[:pay_service], params, answer_params)
		else
			return
		end
		
		if(!ret.nil?)
			if(ret[:format] == 'xml')
				render :xml => ret[:result]
			end
		end
	end
	
	
	def merchant_request_reject_bad (params, answer_params)
		
	end
	
	
	def merchant_request_verify_paydocs (params, answer_params, pay_docs)
		# Если платёжка, ожидающая оплаты, для указанного заказа/счёта (который тоже должен ожидать оплату), не найдена
		if(!pay_docs[:found])
			
		end
		
		# Определение метода оплаты, который указан в платёжке
		if(pay_docs[:payment][:pay_svc_method].blank?)
			pay_svc_method = nil
		else
			
			# Проверка соответствия метода оплаты
			if(!merchant_pay_method_valid?(params, pay_docs, pay_svc_method))
				
			end
		end
		
		# Проверка правильности суммы оплаты, с учётом комиссии
		# Если сумма оплаты ещё не указана в платёжке, то определить её по заказу/счёту. Комиссия тогда определяется по pay_svc_method или pay_service
		ret = merchant_pay_summ_valid?(params, pay_docs, answer_params[:pay_service], pay_svc_method)
		if(!ret[:valid])
			
		end
		
		answer_params[:summ_validity] = ret
		return false
	end
	
	
	def merchant_request_repeat_paid (params, answer_params)
		if(answer_params[:pay_service][:id] == PAYMENT_SERVICE_YANDEX_KASSA)
			if(answer_params[:current_stage] == MERCHANT_PAYMENT_STAGE_PAY_SUCCEED)
				merchant_answer(MERCHANT_PAYMENT_ANSWER_ACCEPT, params, answer_params) # На повторные запросы paymentAviso надо отвечать OK.
			end
		end
	end
	
end