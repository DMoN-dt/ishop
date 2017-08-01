class SellerBrandModel < ActiveRecord::Base

	def self.validate_model_name (model_name)
		
	end
	
	
	def self.year_2digits_to_4digits (year_2digits)
		year_2digits = year_2digits.to_i if(year_2digits.is_a?(String))
		cur_year = Time.now.year
		dty = cur_year.to_s[2,2].to_i
		if(dty < year_2digits)
			year_2digits += cur_year - 100 - dty
		else
			year_2digits += cur_year - dty
		end

		return year_2digits
	end
	
	
	def self.find_model_with_years (seller_id, brand_id, main_model_id, model_name, global_model_id, year_from, year_to)
		str = ((year_from.nil?) ? ' and (model_year_first IS NULL)' : ' and (model_year_first = ' + year_from.to_s + ')')
		str += ((year_to.nil?) ? ' and (model_year_last IS NULL)' : ' and (model_year_last = ' + year_to.to_s + ')')
		
		if(global_model_id.nil?)
			if(main_model_id.nil?)
				return self.select('id').where("(seller_id = ?) and (brand_id = ?) and (name ilike ?)" + str, seller_id, brand_id, model_name).first
			else
				return self.select('id').where("(seller_id = ?) and (brand_id = ?) and (main_model_id = ?) and (name ilike ?)" + str, seller_id, brand_id, main_model_id, model_name).first
			end
		else
			if(main_model_id.nil?)
				return self.select('id').where("(seller_id = ?) and (brand_id = ?) and (global_model_id = ?)" + str, seller_id, brand_id, global_model_id).first
			else
				return self.select('id').where("(seller_id = ?) and (brand_id = ?) and (main_model_id = ?) and (global_model_id = ?)" + str, seller_id, brand_id, main_model_id, global_model_id).first
			end
		end
	end
	
	
	def self.find_or_create_new (seller_id, brand_id, brand_name, model_name, str_multiple)
		
		
	end
end
