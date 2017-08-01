class SellerBrand < ActiveRecord::Base
	has_one  :gen_brand, :foreign_key => :id, :primary_key => :global_brand_id
	has_one  :vendor, :foreign_key => :id, :primary_key => :vendor_id
	has_many :seller_products, :foreign_key => :seller_brand_id, :primary_key => :id
	
	def self.validate_brand_name (brand_name)
		
		
	end
	
	
	def self.find_or_create_new (seller_id, brand_name, str_multiple, create_new_if_no_global = true)
		return nil if(brand_name.blank?)
		if(!str_multiple)
			

		else
			ids = []
			names = brand_name.split(',')
			names.each do |bname|
				bname = (bname.strip! || bname)
				iid = find_or_create_new(seller_id, bname, false)
				ids << {:id => iid, :name => bname} if(!iid.nil?)
			end
			
			return ((ids.blank?) ? nil : ids.uniq)
		end
		return nil
	end
	
	
	def self.id_from_global(seller_id, global_brand_id)
		
	end
	
	
	def get_name
		
	end
	
	
	def get_vendor
		
	end
	
	
	private
	
	
	def get_gen_brand
		
	end
end
