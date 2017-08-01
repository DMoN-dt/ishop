class PaymentService < ActiveRecord::Base
	has_many :payment_svc_methods, :foreign_key => :pay_svc_id, :primary_key => :id
	
end
