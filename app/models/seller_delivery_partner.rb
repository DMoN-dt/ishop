class SellerDeliveryPartner < ApplicationRecord
	has_one    :delivery_partner, :foreign_key => :id, :primary_key => :global_dp_id
	has_many   :sellers,  :foreign_key => :id, :primary_key => :seller_id
end
