class PaymentMethod < ActiveRecord::Base
	has_many :payment_svc_methods, :foreign_key => :method_id, :primary_key => :id

	
	# Список доступных онлайн-платежей из настроек сайта
	@@avail_select = 'pmtd.id, pmtd.parent_id, parentmt.name as parent_name, pmtd.name, pmtd.logo_name, pmtd.min_limit, pmtd.onetime_max_limit, psvm.pay_svc_id, psvm.payer_comission, psvm.min_limit as svc_min_limit, psvm.onetime_max_limit as svc_onetime_max_limit, psvm.prohibit_max_limit'
	@@avail_from   = 'payment_methods as pmtd'
	@@avail_join   = 'INNER JOIN payment_svc_methods as psvm on (psvm.method_id = pmtd.id) INNER JOIN payment_services as psvc on (psvc.id = psvm.pay_svc_id) INNER JOIN payment_methods as parentmt on (parentmt.id = pmtd.parent_id)'
	@@avail_where  = '(parentmt.is_enabled) and (pmtd.is_enabled) and (psvm.is_enabled) and (psvc.is_enabled)'
	@@avail_order  = 'parentmt.sort_order ASC NULLS LAST, pmtd.sort_order ASC NULLS LAST, psvm.priority DESC NULLS LAST, psvm.comission ASC NULLS LAST, pmtd.name ASC'
	@@avail_method = 'psvc.id, psvc.name, psvc.logo_name, psvc.params, psvc.test_demo, psvm.payer_comission, parentmt.name as parent_name, pmtd.name as method_name, pmtd.logo_name as method_logo_name, psvm.method_code, psvm.min_limit as svc_min_limit, psvm.onetime_max_limit as svc_onetime_max_limit, pmtd.min_limit as method_min_limit, pmtd.onetime_max_limit as method_onetime_max_limit, psvm.prohibit_max_limit, psvm.id as svc_method_id'
	
	def self.available_online_list (get_list = true)
		
	end
	
	
	def self.available_services_of_method (method_id)
		if(!method_id.nil?)
			avail_methods_list = PaymentMethod.select(@@avail_method).from(@@avail_from).joins(@@avail_join).where("(psvm.method_id = ?) and " + @@avail_where, method_id).order('psvm.priority DESC NULLS LAST, psvm.comission ASC NULLS LAST, psvc.priority DESC NULLS LAST').find_all
			avail_methods_list = nil if((avail_methods_list.blank?) or (avail_methods_list.first.blank?))
		end
		return avail_methods_list
	end
	
	
	def self.pay_info_for_svc_method (svc_method_id)
		if(!svc_method_id.nil?)
			avail_methods_list = PaymentMethod.select(@@avail_method).from(@@avail_from).joins(@@avail_join).where("(psvm.id = ?) and " + @@avail_where, svc_method_id).order('psvm.id asc').first
			avail_methods_list = nil if(avail_methods_list.blank?)
		end
		return avail_methods_list
	end
	
	
	# Способы, доступные для оплаты конкретного платежа
	def self.allowed_types (customer, contract, pay_summ, total_paid_by_contract, get_online_list = false, check_online_available = false)
		# Чтение настроек сайта
		available_pay_types = GenSetting.available_pay_types
		
		# Проверить физ.лицо / юр.лицо / ип
		# С ИП можно нал и карты, но проверять сумму до 100 тыс.р. по текущему договору.
		# При превышении - сообщать и потом делать новый договор.
		# Юр. лицу - только безнал через банк.
		if(!customer.nil?)
			if(customer.is_a?(Integer))
				if(customer != 0)
					customer = Customer.where(id: customer).first
					available_pay_types[:pcustomer] = customer
				else
					customer = nil
				end
			end
			
			if(customer.present?)
				if(customer[:customer_type] != CUSTOMER_TYPE_FIZ_LICO)
					if(customer[:customer_legal_info].present?)
						if(customer[:customer_legal_info][:orgtype] == ORGANIZATION_TYPE_IND_PREDP)
							limit = GenSetting.pay_cash_legal_ip_limit # Лимит для ИП
							
							if(total_paid_by_contract.nil?)
								
								
							end
							
							if((pay_summ >= limit) or (total_paid_by_contract >= limit) or ((total_paid_by_contract != 0) && ((total_paid_by_contract + pay_summ) >= limit)))
								if(available_pay_types[:online])
									available_pay_types[:online] = false
									available_pay_types[:online_restrict_limit] = true
								end
								if(available_pay_types[:cash])
									available_pay_types[:cash] = false
									available_pay_types[:cash_restrict_limit] = true
								end
								if(available_pay_types[:bank_card])
									available_pay_types[:bank_card] = false
									available_pay_types[:bank_card_restrict_limit] = true
								end
								available_pay_types[:nfc][:all] = false
							end
						else
							available_pay_types[:online] = false
							available_pay_types[:cash] = false
							available_pay_types[:bank_card] = false
							available_pay_types[:nfc][:all] = false
						end
					else
						available_pay_types[:nocustomer] = true
					end
				end
			else
				available_pay_types[:nocustomer] = true
			end
		else
			available_pay_types[:nocustomer] = true
		end
		
		if(available_pay_types[:online]) # получить информацию о наличии доступных онлайн-платежей
			if(get_online_list)
				available_pay_types[:online_list] = available_online_list(true)
			elsif(check_online_available)
				available_pay_types[:online_count] = available_online_list(false)
			end
		end
		
		return available_pay_types
	end

	
	def actual_limits
		
	end
	
	
	# ENCODED PAY-SERVICE ID WITH CRC HASH
	def self.prepare_make_safe_id
		
	end
	
	
	def self.pub_safe_uid(safeid_params, pid)
		
	end
	
	
	def self.from_safe_uid (pub_safe_id)
		
	end
	
	
	
	### =================================== PROTECTED ==========================================
	### ========================================================================================
	protected
	
	
	### ==================================== PRIVATE ===========================================
	### ========================================================================================
	private
	
	
end
