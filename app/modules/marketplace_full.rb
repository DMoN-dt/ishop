#############################
### FULL MARKETPLACE MODE ###
#############################

if(defined?(MARKETPLACE_MODE_ONLINE_SHOP) && (MARKETPLACE_MODE_ONLINE_SHOP != true) && (!defined?(MARKETPLACE_MODE_RETAIL) or (MARKETPLACE_MODE_RETAIL != true)))
	class Marketplace < Marketplace_General
		
		
		
	end
end


