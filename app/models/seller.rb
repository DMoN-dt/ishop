class Seller < ActiveRecord::Base
	has_one    :user, :foreign_key => :id, :primary_key => :user_id
	has_one    :partner, :foreign_key => :id, :primary_key => :partner_id
	
	has_many   :seller_delivery_partners,  :foreign_key => :seller_id, :primary_key => :id
	has_many   :seller_suppliers,  :foreign_key => :seller_id, :primary_key => :id
	has_many   :seller_products,   :foreign_key => :seller_id, :primary_key => :id
	has_many   :seller_warehouses, :foreign_key => :seller_id, :primary_key => :id

	
	RIGHTS = {
		# Права продавца:

	}

	
	def calc_rights_mask (rights)
		return (((rights & RIGHTS.keys).map {|rk| 2**RIGHTS[rk]}.inject(0, :+)) + AccessList.calc_rights_mask(rights))
	end
	
	
	# Return ACL for AccessList
	def access_list
		if(MARKETPLACE_MODE_ONLINE_SHOP)
			return {}
		else
			acl = self.acl
			acl = {} if(acl.blank?)
			acl[:creator_user_id] = self.user_id
			return self.acl
		end
	end
	
	
	def has_access? (pAccessList, rights)
		return ((!pAccessList.nil?) ? pAccessList.has_access?(calc_rights_mask(rights)) : false)
	end
	
	
	def self.verified_access? (test_user, seller_id, seller, verify_rights)
		if(MARKETPLACE_MODE_ONLINE_SHOP)
			
		else
			
		end
		return false
	end
	
	
	def self.from_safe_uid (uid)
		
	end
	
	## ================================================================================ ##
	## ==============================  SELLER's SETTINGS ============================== ##
	## ================================================================================ ##
	
	def self.default_currency (seller = nil, seller_id = nil)
		return GenSetting.default_currency if(MARKETPLACE_SHOP or MARKETPLACE_RETAIL or (seller.nil? && seller_id.nil?) or (seller_id == 0) or !GenSetting.default_currency_seller_preffer?)
		seller = Seller.where(seller_id: seller_id).first if(seller.blank?)
		return ((seller.present?) ? seller.currency : GenSetting.default_currency)
	end
	
	
	def self.default_gov_tax_system_id (seller = nil, seller_id = nil)
		return GenSetting.default_gov_tax_system_id if(MARKETPLACE_SHOP or MARKETPLACE_RETAIL or (seller.nil? && seller_id.nil?) or (seller_id == 0))
		seller = Seller.where(seller_id: seller_id).first if(seller.blank?)
		return ((seller.present?) ? seller.def_gov_tax_system_id : GenSetting.default_gov_tax_system_id)
	end
	
	
	def self.default_gov_tax_id (seller = nil, seller_id = nil)
		return GenSetting.default_gov_tax_id if(MARKETPLACE_SHOP or MARKETPLACE_RETAIL or (seller.nil? && seller_id.nil?) or (seller_id == 0))
		seller = Seller.where(seller_id: seller_id).first if(seller.blank?)
		return ((seller.present?) ? seller.def_gov_tax_id : GenSetting.default_gov_tax_id)
	end
	
	
	## IMPORT FROM SUPPLIER
	def CreateProductForNewFromSupplier?
		
	end

	def OnImportFindBrokenLinkFromSupplier?
		
	end
	
	
	## DELIVERY
	def self.delivery_charges_from_seller_to_own_office (seller_id, seller = nil, office_id = nil, order = nil)
		
	end
	
	def self.delivery_charges_from_seller_to_delivery_partner (seller_id, seller = nil, delivery_method = 0, delivery_partner = nil, order = nil)
		
	end
	
	def self.delivery_charges_from_carrier_to_customer (seller_id, seller = nil, delivery_method = 0, delivery_partner = nil, order = nil)
		
	end
	
	## DELIVERY - POST OFFICE
	def self.price_shippment_to_post_office (seller_id, seller = nil)
		
	end


end
