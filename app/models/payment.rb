class Payment < ActiveRecord::Base

	scope :for_list, -> {select("payments.*, payment_services.name AS ps_name, payment_methods.name AS pm_name").joins('LEFT OUTER JOIN payment_services ON (payment_services.id = payments.pay_service) LEFT OUTER JOIN payment_svc_methods ON (payment_svc_methods.id = payments.pay_svc_method) LEFT OUTER JOIN payment_methods ON (payment_methods.id = payment_svc_methods.method_id)')}
	
	
	def accept_pay (order, paydoc)
		
	end
	
	
	def send_information__payment_arrived
		PaymentMailer.payment_arrived(subscribed_to_info, self).deliver_later
	end
	
	
	def subscribed_to_info
		
	end
	

	def self.round_price (price, round_2 = false, remainder = nil)
		
	end
	
	
	def self.round_comission (percent)
		
	end
	
	
	def self.delimiter_thousands (anumber, separator = ' ')
		
	end
	
	
	def self.cost_text (cost, currency_type, inside_tag = true, notscram = true, currency_id = CURRENCY_CODE_NUM_RUB)
		
		return str.html_safe
	end
	
	
	# ENCODED ID WITH CRC-HASH FOR SAFELY PUBLIC USAGE IN FORMS AND REQUESTS
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
