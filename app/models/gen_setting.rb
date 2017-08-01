class GenSetting < ActiveRecord::Base
	@@stored = {}
	@@stored_ok = {}
	
	
	def self.stored_param (pname)
		@@stored[pname] = GenSetting.where(setgroup: pname).first.to_hash if(@@stored[pname].nil?)
		@@stored_ok[pname] = @@stored[pname].present? if(@@stored_ok[pname].nil?)
		return @@stored[pname]
	end
	
	def self.stored_ok? (pname)
		@@stored_ok[pname].is_a?(TrueClass)
	end

	
	## ======================================================================================================================
	## ===== MARKET MAIN SETTINGS =====
	def self.default_currency
		return stored_param('currency')['def'] if(stored_ok?('currency'))
		CURRENCY_CODE_NUM_RUB
	end
	
	
	def self.default_currency_seller_preffer?
		(stored_ok?('currency') ? (stored_param('currency')['seller_own'].is_a?(TrueClass)) : true)
	end
	

end
