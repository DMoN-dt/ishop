class Cart < ActiveRecord::Base
	belongs_to :user, :foreign_key => :user_id, :primary_key => :id
	
	
	def self.open_user_cart (user_cart_params)
		if(user_cart_params[:cart].blank?)
			
		end
		
		return user_cart_params[:cart].present?
	end
	
	
	# Чтение информации о корзине гостя и пользователя только из cookies (для шапки)
	def self.total_count_from_cookie (cookies, plus_user = true)
		user_cart = cookies.encrypted[:cart]
		if(user_cart.present?)
			user_cart = JSON.parse(user_cart)
			if(user_cart.is_a?(Hash))
				
			end
		end
		
		return nil
	end
	
	
	# Чтение информации о корзине гостя и пользователя из базы и cookies
	def self.total_count_all (user_cart_params, cookies)
		
		return cart_total_items
	end
	
	
	def self.remove_from_cart (remove_list, user_cart_params, cookies)
		if(open_user_cart(user_cart_params) && user_cart_params[:cart][:products].present?)
			
		end

		if(!cookies.nil?)
			user_cart = cookies.encrypted[:cart]
			if(user_cart.present?)
				user_cart = JSON.parse(user_cart)
				if(user_cart.is_a?(Hash))
					if(user_cart['guest_items'].is_a?(Hash))
						if(user_cart['guest_items'].length > 0)
							
						end
					end
					
					cookies.encrypted[:cart] = {value: JSON.generate(user_cart), expires: 14.days.from_now}
				end
			end
		end
	end
	
	
	# ENCODED ID WITH CRC-HASH FOR SAFELY PUBLIC USAGE IN FORMS AND REQUESTS
	def self.prepare_make_safe_id
		
		
	end
	
	
	def self.pub_safe_uid(safeid_params, pid)
		
		
	end
	
	
	def self.from_safe_uid (pub_safe_id)
		if(pub_safe_id.present?)
			
			
			return nil
		end
	end
	
	
	# Разрешено ли площадкой и пользователем показывать содержимое корзины пользователя (из БД) под Гостем через cart_user_id в cookies
	def is_allowed_show_items_for_guest?
		return false
		#return self.guest_visible
	end
	
	### =================================== PROTECTED ==========================================
	### ========================================================================================
	protected
	
	
	### ==================================== PRIVATE ===========================================
	### ========================================================================================
	private
end
