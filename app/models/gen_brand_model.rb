class GenBrandModel < ActiveRecord::Base
	has_one :gen_brand, :foreign_key => :id, :primary_key => :brand_id
	# also has_one :gen_brand, :foreign_key => :id, :primary_key => :sub_brand_id
	
	def pub_id
		return self.id
	end

	
	def self.from_pub_id (pub_id)
		return pub_id
	end
	
	
	def link_name
		self.name.gsub(' ','_')
	end
	
	
	def self.find_model_with_years (brand_id, main_model_id, model_name, year_from, year_to)
		
	end
	
	
	def self.create_model (brand_id, brand_name, main_model_id, model_name, year_from, year_to)
		
	end
	
end
