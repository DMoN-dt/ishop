class User < ActiveRecord::Base
	has_one    :cart, :foreign_key => :user_id, :primary_key => :id
	has_many   :customers, :foreign_key => :user_id, :primary_key => :id
	has_many   :sellers, :foreign_key => :user_id, :primary_key => :id
	has_many   :partners, :foreign_key => :user_id, :primary_key => :id
	has_many   :orders, :foreign_key => :user_id, :primary_key => :id
	has_many   :products_images, :foreign_key => :user_id, :primary_key => :id
	
	TEMP_EMAIL_PREFIX = 'change@me'
	TEMP_EMAIL_REGEX = /\Achange@me/
	
	scope :for_verify, -> {select("id, email, encrypted_password, sex, roles_mask, password_date, notsecurepsw, b_banned_full, b_banned_write, ban_full_dateto, ban_write_dateto, b_premoderated, locked_at, blocked_at, unconfirmed_email, confirmed_at, created_by_oauth, b_allow_login_by_passw, b_passw_rnd")}
	scope :for_mail_list, -> {select('name, email, sex, last_activity, login_history, password_date, notsecurepsw, timezone, current_sign_in_at, current_sign_in_ip, locked_at, blocked_at, roles_mask, (users.confirmed_at IS NOT NULL) AS email_confirmed, unconfirmed_email, confirmation_sent_at, confirmation_token, confirmed_at')}
	
	ROLES = {
		# Глобальные роли Торговой площадки:
		:user => ,
		:moderator_only_citylist => ,# модерирует только по городам из его списка допуска
		:moderator_users => ,# модерирует пользователей


		:client_agent => , # представитель одной или нескольких организаций-клиентов. Это Обязательное условие для работы в разделе Партнёров.
		:seller_agent =>  # представитель продавца. Это Обязательное условие для работы с Seller и для доступа в разделы e-commerce личного кабинета. Проставляется автоматом при подтверждении модератором созданного Продавца или примыкания к Продавцу.
		
		# права пользователя как продавца - брать из ACL продавца и определять через verified_access? или has_access? модели !
		# права пользователя как покупателя - брать из ACL покупателя и определять через verified_access? или has_access? модели !
	}


	after_initialize :set_default_role, :if => :new_record?
	after_create     :send_welcome_email
	
	devise :invitable, :database_authenticatable, :confirmable, :omniauthable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable, :invite_for => 1.week, :invitation_limit => 5, :allow_insecure_sign_in_after_accept => false, :omniauth_providers => [:vkontakte, :odnoklassniki, :yandex, :mail_ru, :google_oauth2, :facebook]

	
	## ROLES CALCULATION
	def is?(role)
		roles.include?(role.to_sym)
	end
	
	def roles (rmask = self.roles_mask)
		ROLES.reject {|rk,rv| ((rmask.to_i || 0) & 2**rv).zero?}
	end
	
	def calc_roles_mask (roles)
		return (roles & ROLES.keys).map {|rk| 2**ROLES[rk]}.inject(0, :+)
	end
	
	def self.roles_mask (roles)
		return (roles & ROLES.keys).map {|rk| 2**ROLES[rk]}.inject(0, :+)
	end
	
	def is_any_role? (roles)
		test_mask = calc_roles_mask(roles)
		return ((self.roles_mask & test_mask) != 0)
	end
	
	
	## IS (CROSS-ROLES)
	def active_for_authentication?
		super && is_not_blocked?
	end
	
	def is_signin_by_oauth?
		
	end
	
	def is_created_by_oauth?
		
	end
	
	def is_allowed_to_profile?
		return true if((is_not_blocked?) && (self.roles_mask != 0))
		return false
	end
	
	def email_not_temporary?
		(self.email.present? && (self.email !~ TEMP_EMAIL_REGEX))
	end
	
	def email_confirmation_skipped?
		
	end
	
	def email_must_confirm?
		
	end
	
	def email_need_confirm?
		
	end
	
	def email_verified?
		
	end
	
	def get_allowed_identities_count
		
	end
	
	def is_password_random?
		
	end
	
	def is_allowed_login_by_password?
		
	end

	def identity_action (idt_id, action_name, force_admin)
		
	end
	
	## IS ROLES	
	def is_objowner?
		
	end
	
	def is_admin?
		is?(:admin) or is?(:super_admin)
	end
	
	def is_admin_or_objmoder?
		
	end
	
	def is_admin_or_productmoder?
		
	end
	
	def is_admin_or_cartsmoder?
		
	end
	
	def is_admin_or_ordersmoder?
		
	end
	
	def is_admin_or_orderscreator?
		
	end
	
	def is_admin_or_any_ordersmoder?
		is_any_role?([:admin, :super_admin, :moderator_orders, :moderator_orders_new, :moderator_orders_prepaid_accepted, :moderator_orders_delivered])
	end
	
	def is_allowed_objedit?
		
	end
	
	def is_allowed_to_ecommerce?
		
	end
	
	def is_admin_or_usersmoder?
		
	end
	
	
	## IS PER-USER ROLES
	def is_user_allowed_to_edit_profile?
		
	end
	
	def is_user_allowed_to_manage_objects?
		
	end
	
	def is_user_not_banned_owner?
		
	end
	
	
	def is_user_allowed_to_own_ecommerce?
		
	end
	
	
	## ===== AUTHENTICATION THROUGH OMNI-AUTH IDENTITIES ====
	
	
	### ====================================================================
	
	def send_reset_password_instructions
		
	end
	
	def set_terms_of_use_agreement(status)
		
	end
	
	def terms_of_use_accepted?
		
	end
	
	def terms_of_use_answered?
		
	end
	
	
	def subscribe_to_portal_news(status)
		
	end
	
	
	def subscribed_to_portal_news?
		
	end
	
	
	def check_and_set_join_date
		
	end
	
	
	def get_filtered_name
		if(self.nickname.blank?)
			_name = self.name
		else
			_name = self.nickname
		end
		
		if(_name.present?) && !(is?(:admin) or is?(:super_admin))
			RESTRICTED_NAMES.each {|rn| _name.gsub!(rn,'***')}
		end
		return _name
	end
	
	
	def get_name_for_email
		
	end
	
	
	def get_name_string
		[self.lastname, self.name, self.middlename].join(' ').strip
	end
	
	
	def sex_name
		if(self.sex == 1)
			I18n.t(:user_woman, scope: [:dt_breeze, :cabinet, :profile])
		elsif(self.sex == 2)
			I18n.t(:user_man, scope: [:dt_breeze, :cabinet, :profile])
		else
			I18n.t(:user_sex_undefined, scope: [:dt_breeze, :cabinet, :profile])
		end
	end
	
	
	def self.email_hide_symbols (s_email)
		
	end
	
	
	def get_email_hidden_symbols (s_email = self.email)
		User.email_hide_symbols(s_email)
	end
	

	def inactive_message
		is_not_blocked? ? super : (I18n.t(:your_account_blocked, scope: [:dt_breeze, :login, :your_account_blocked]) + ' ' + self.blocked_at.to_s)
	end
	
	
	# ENCODED ID WITH CRC HASH
	def static_pub_safe_uid (uri_encode = false)
		
	end
	
	
	def self.prepare_make_safe_id
		
	end
	
	
	def pub_safe_uid(safeid_params, gen_params_if_nil = false, uri_encode = false)
		
	end
	
	
	def self.pub_safe_uid(safeid_params, pid, gen_params_if_nil = false, uri_encode = false)
		
	end
	
	
	def self.from_safe_uid (pub_safe_id)
		
	end
	
	
	def set_profile_environment
		$user_tzone = {wtz: RUS_TIMEZONES['MSK'][:wtz], name: RUS_TIMEZONES['MSK'][:name]}
		$user_tzone_name = ' ' + I18n.t(:moscow_short, scope: [:dt_breeze, :tzone_name])
		
		$user_preferred_lang = GenSetting.page_selected_language
	end
	
	
	#def after_database_authentication
	#	self.update_attributes(:name => "")
	#end

	def current_customer_id=(customer_id)
		@current_customer_id = customer_id
	end
	
	
	def save_current_customer_id (pcookie)
		self.update({last_current_customer_id: @current_customer_id})
	end
	
	
	def current_customer_id
		user_customers_ids = ((self.customers_list.present?) ? self.customers_list.keys : nil)

		if(user_customers_ids.present?)
			
		end
		
		return nil
	end
	
	
	def current_customer_avail_prices (seller_id)
		
	end
	
	
	def current_customer
		customer_id = current_customer_id
		if(@current_customer.nil? or (@current_customer[:id] != customer_id))
			@current_customer = ((!customer_id.nil? && (customer_id != 0)) ? Customer.where(id: customer_id).first : nil)
		end
		return @current_customer
	end
	

	### =================================== PROTECTED ==========================================
	### ========================================================================================
	protected
	
	def confirmation_required?
		return email_must_confirm?
	end
	
	
	def unconfirmed_access_allowed?
		
	end
	
	
	def unconfirmed_access_expired?
		
	end
	
	
	def after_confirmation
		
    end
	
	### ==================================== PRIVATE ===========================================
	### ========================================================================================
	private
	
	def roles=(roles)
		
	end
	
	
	def set_default_role
		if(self.saved_changes?)
			self.roles = [:user] if(unconfirmed_access_allowed?)
		end
	end
	
	
	def is_not_blocked?
		return self.blocked_at.blank?
	end
	
	
	def send_welcome_email (force = false)
		if(force or (self.saved_change_to_email? && self.email_before_last_save.blank?))
			if(self.confirmed_at.present? or !unconfirmed_access_expired?)
				UserMailer.welcome_email(self).deliver_later
			end
		end
    end

	
	# def is_banned_email?
	# end
end
