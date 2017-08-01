class GenBrand < ActiveRecord::Base
	has_one :vendor, :foreign_key => :id, :primary_key => :vendor_id
	
	has_many :gen_brand_models, :foreign_key => :brand_id, :primary_key => :id
	has_many :seller_brands, :foreign_key => :global_brand_id, :primary_key => :id


	def self.validate_brand_name (brand_name)

	end
	
	
	def pub_id
		return self.id
	end
	
	
	def self.from_pub_id (pub_id)
		return pub_id
	end
	
	
	def link_name
		self.name.gsub(' ','_')
	end
	
	
	def get_vendor
		return ((self.vendor_id.present?) ? Vendor.where(id: self.vendor_id).first : nil)
	end
	
	
	def self.find_or_create_new (brand_name, create_new = true)
		return nil if(brand_name.blank?)
		brand_name = validate_brand_name(brand_name)
		
		brand = self.select('id').where("name ilike ?", brand_name).first
		if(brand.present?)
			return brand[:id]
		elsif(create_new)
			brand = self.new({name: brand_name})
			if(!brand.nil?)
				return brand.id.to_s if(brand.save)
			end
		end
		return nil
	end
	
	
	def self.CarMakersList
		return self.where("(bcarmaker is TRUE) and (models_cnt != 0)").order("name ASC").find_all
	end

end
