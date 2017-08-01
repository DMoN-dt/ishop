class PaymentSvcMethod < ActiveRecord::Base
	has_one  :payment_method,  :foreign_key => :id, :primary_key => :method_id
	has_one  :payment_service, :foreign_key => :id, :primary_key => :pay_svc_id
	has_many :payments, :foreign_key => :pay_svc_method, :primary_key => :id
	
end
