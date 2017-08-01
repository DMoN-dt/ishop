class Merchant
	
	def self.calc_crc_yandex_kassa (params, shop_salt, stage_action)
		case stage_action
			when MERCHANT_PAYMENT_STAGE_CHECK_ORDER
				params[:action] = 'checkOrder'
			when MERCHANT_PAYMENT_STAGE_PAY_SUCCEED
				params[:action] = 'paymentAviso'
		end
		
		str = ''
		[:action, :orderSumAmount, :orderSumCurrencyPaycash, :orderSumBankPaycash, :shopId, :invoiceId, :customerNumber].each do |sid|
			str += ((sid != :customerNumber) ? (params[sid].to_s + ';') : (params[sid].to_s.strip + ';'))
		end
		str += shop_salt
		return Digest::MD5.hexdigest(str).upcase
	end
	
	
	def self.is_for_me_from_yandex_kassa? (params, pay_service)
		if(params[:shopId].numeric?)
			if(params[:shopId].to_i == pay_service[:params]['shop_id'].to_i)
				if(params[:scid].present?)
					if(params[:scid].numeric?)
						
					end
				else
					return true
				end
			end
		end
		
		return false
	end
	
	
	def self.request_transaction_id_yandex_kassa(params)
		return ((params[:invoiceId].present? && params[:invoiceId].numeric?) ? params[:invoiceId].to_i : nil)
	end
	
	
	def self.pay_summ_yandex_kassa(params)
		
		return {summ: summ, currency: currency}
	end
	
	
	def self.pay_method_code_yandex_kassa(params)
		if(params[:paymentType].present?)
			return params[:paymentType][0,2] # у Яндекс.Кассы код из двух букв
		end
		return nil
	end
	
	
	def self.payment_store_yandex_kassa(params, pay_service, payment)
		paid_at = nil
		
		
		# Код валюты для суммы оплаты (в ISO)
		if(params[:orderSumCurrencyPaycash].present?)
			if(params[:orderSumCurrencyPaycash].numeric?)
				
			else
				payment[:payment_data][:pay_currency] = params[:orderSumCurrencyPaycash][0,20]
				currency = nil
			end
			payment[:summ_currency] = currency if(currency != payment[:summ_currency])
		end
		
		# Код валюты для суммы к выплате на счёт магазина
		if(params[:shopSumCurrencyPaycash].present?)
			if(params[:shopSumCurrencyPaycash].numeric?)
				
			else
				payment[:payment_data][:shop_currency] = params[:shopSumCurrencyPaycash][0,20]
				currency = nil
			end
			payment[:shop_summ_currency] = currency
		end
		
		# Пометка демо-платежей
		if((pay_service[:test_demo]) or (params[:production_mode].present? && !params[:production_mode]))
			if(params[:shopId].to_i == pay_service[:params]['shop_id'].to_i)
				if(params[:scid].to_i == pay_service[:params]['demo_scid'].to_i)
					payment[:payment_data][:demo_pay] = true
				end
			end
		end
		
		# Отложенные платежи

	end
	
	
	def self.answer_code_yandex_kassa(merchant_code)
		case merchant_code
			when MERCHANT_PAYMENT_ANSWER_ACCEPT
				code = 0
			when MERCHANT_PAYMENT_ANSWER_BAD_CRC
				code = 1
			when MERCHANT_PAYMENT_ANSWER_NOT_FOUND
				code = 100
			when MERCHANT_PAYMENT_ANSWER_BAD_PARAMS
				code = 200
			else
				code = 200
		end
		return code
	end

	
	def self.answer_yandex_kassa (answer_code, pay_service, params, answer_params)
		xml = Builder::XmlMarkup.new
		xml.instruct!(:xml, :encoding => "UTF-8")
		time_now = nil
		if((answer_params[:my_time].nil? or (answer_params[:my_time] != true)) && params[:requestDatetime].present?)
			if(params[:requestDatetime].gsub(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3,6})?([\+\-])(\d{2}:\d{2})\z/).present?)
				
			end
		end
		
		time_now = Time.now.strftime("%FT%T.%L%:z") if(time_now.nil?)
		
		xml_params = {
			performedDatetime: time_now,
			code: answer_code_yandex_kassa(answer_code),

		}

		
		if(answer_params[:current_stage] == MERCHANT_PAYMENT_STAGE_CHECK_ORDER)
			xml.tag!('checkOrderResponse', xml_params)
		elsif(answer_params[:current_stage] == MERCHANT_PAYMENT_STAGE_PAY_SUCCEED)
			xml.tag!('paymentAvisoResponse', xml_params)
		end
		
		return {format: 'xml', result: xml.target!}
	end

end
