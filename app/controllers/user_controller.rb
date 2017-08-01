class UserController < ApplicationController
	before_action :authenticate_and_authorize_user_action_and_object, :except => [:wait_confirm, :new, :create]
	before_action :authenticate_and_authorize_user_action, :only => [:new, :create]
	after_action  :verify_authorized, :except => [:wait_confirm]

	
	def index
		show
	end
	
	
	def show # User's profile
		set_cabinet_breadcrumbs({:name => I18n.t(:profile, scope: [:dt_breeze, :cabinet, :menu_crumb]), :active => true}, true)

		if(@user.customers_list.present?)
			@cur_customer_id = @user.current_customer_id
			@user_customers = Customer.sorted_customers_list(nil, @user.customers_list.keys, @cur_customer_id)
		else
			@user_customers = nil
		end
		
		@user_destinations = CustomerDestination.where(user_id: current_user.id, customer_id: 0).order('is_default DESC, created_at DESC').find_all
		@user_destinations = nil if(@user_destinations.first.blank?)
		
		@cur_year = Time.now.year
		render 'profile'
	end
	
	
	def profile_edit
		pparams = params.permit(:fhash, :ftime, :user_uid, :name, :lastname, :middlename, :sex)
		@user_profile_path = user_profile_path(current_user, pparams, @user)
		
		set_cabinet_breadcrumbs({:name => I18n.t(:profile, scope: [:dt_breeze, :cabinet, :menu_crumb]), :url => @user_profile_path, :active => false}, true)
		set_cabinet_breadcrumbs({:name => I18n.t(:profile_edit, scope: [:dt_breeze, :cabinet, :menu_crumb]), :active => true}, false)

		if(params[:fhash].present? && request.post?)
			
		end
		
		@cur_year = Time.now.year
		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((.....), .....)
	end
	
	
	def profile_fill
		pparams = params.permit(:fhash, :ftime, :name, :lastname, :middlename, :sex, :email, :phone)
		
		if(@user.customers_list.present?)
			@cur_customer_id = @user.current_customer_id
			@user_customers = Customer.sorted_customers_list(nil, @user.customers_list.keys, @cur_customer_id)

			if(!@user_customers.nil? && (@user.name.present? or @user.lastname.present? or @user.middlename.present?))
				redirect_to user_index_path
				return
			end
		end
		
		set_cabinet_breadcrumbs(nil, true)

		if(params[:fhash].present? && request.post?)
			
		
		else
			
			
		end
		
		@cur_year = Time.now.year
		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((.....), .....)
	end
	
	
	def payments
		set_cabinet_breadcrumbs({:name => I18n.t(:payments, scope: [:dt_ishop, :cabinet, :menu_main]), :active => true}, true)
		
		pparams = params.permit(:customer_uid, :list, :page)
		pparams[:list] = 'balance' if(pparams[:list].nil? or not ['balance', 'list', 'invoices'].include?(pparams[:list]))
		page = ((pparams[:page].present? && pparams[:page].numeric?) ? pparams[:page].to_i : 1)
		per_page = 20
		
		if(@user.customers_list.present?)
			@user_customers = Customer.eager_load(:balance).where(id: @user.customers_list.keys, user_id: @user.id, is_deleted: false).find_all
			@user_customers = nil if(@user_customers.first.blank?)
			
			@cur_customer_id = @user.current_customer_id
			
			if(!@user_customers.nil?)
				if(pparams[:customer_uid].present?)

				end
				
				@selected_customer_id = @cur_customer_id if(@selected_customer_id.nil?)
				
				@selected_customer = @user_customers.select{|x| x.id == @selected_customer_id}.first
				if(@selected_customer.present?)
					@selected_customer.create_acl(@user)
					@has_access_buh = @selected_customer.has_access?([:buh])
					@has_access_buy_all = @selected_customer.has_access?([:buy, :view_all_purchases])
					@has_access_buy_self = (!@has_access_buy_all && @selected_customer.has_access?([:buy, :view_self_purchases]))
					
					
				end
			end
		else
			@user_customers = nil
		end
		
		@list_type = pparams[:list]
		
		@isAjax = (params[:ajax]=='Y')
		if(@isAjax)
			render layout: false
		end
	end
	
	
	def wait_confirm
	end
	
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	private
	
	def authenticate_and_authorize_user_action
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		authorize User # Pundit authorization.
	end
	
	
	def authenticate_and_authorize_user_action_and_object
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		
		user_uid = ((params[:id].present?) ? params[:id] : params[:user_uid])
		if(user_uid.blank?)
			@user = current_user
		else
			@user_safe_uid = user_uid[0,SAFE_UID_MAX_LENGTH]
			user_id = User.from_safe_uid(@user_safe_uid)
			if(user_id.nil?)
				respond_to do |format|
					format.html {redirect_to controller: 'welcome', action: 'error_404'}
					format.json {
						err = I18n.t(:item_not_found, scope: [:dt_breeze, :messages])
						render :json => [{:status => 'error', :error => err, :status_text => err}], :status => 404
					}
				end
				return
			end
			
			@user = User.where(id: user_id).first
			if(@user.blank?)
				respond_to do |format|
					format.html {redirect_to controller: 'welcome', action: 'error_404'}
					format.json {
						err = I18n.t(:item_not_found, scope: [:dt_breeze, :messages])
						render :json => [{:status => 'error', :error => err, :status_text => err}], :status => 404
					}
				end
				return
			end
			
			# here need to set user.static_pub_safe_uid = @user_safe_uid
		end

		authorize @user # Pundit authorization.
		
		@is_admin_or_usersmoder = current_user.is_admin_or_usersmoder?
		return
	end
	
	
	def user_profile_path (current_user, pparams = nil, user = nil)
		
		
	end
	
	
	#def verify_non_user_pages # это для того, чтобы случайно не обработать запрос для дочернего контроллера # уже не надо
	#	if((controller_name == 'user') && (action_name !~ /\A(users_|user_|profile).+/))
	#		redirect_to controller: 'welcome', action: 'error_access_denied'
	#	end
	#end
end
