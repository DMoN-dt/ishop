class CustomersController < ApplicationController
	before_action :authenticate_and_authorize_user_action_and_object, :except => [:new, :create, :index]
	before_action :authenticate_and_authorize_user_action, :only => [:new, :create, :index]
	after_action  :verify_authorized
	
	
	def index
		pparams = params.permit(:user_uid)
		
		@is_admin_or_usersmoder = current_user.is_admin_or_usersmoder?
		if(@is_admin_or_usersmoder && pparams[:user_uid].present?)
			user_uid = pparams[:user_uid][0,SAFE_UID_MAX_LENGTH]
			if(User.from_safe_uid(user_uid).nil?)
				redirect_to controller: 'welcome', action: 'error_access_denied'
				return
			end
			redirect_to user_path(id: user_uid)
			
		else
			redirect_to user_index_path
		end
	end
	
	
	def show
		pparams = params.permit(:user_uid)
		
		@allow_contacts = @allow_legal_info = @customer.has_access?([:gen_some_access])
		if(@allow_contacts)
			if(current_user.id == @customer.user_id)
				@user = current_user
			elsif(current_user.is_admin? or current_user.is?(:moderator_users))
				@user = User.where(id: @customer.user_id).first
				if(user_id.nil?)
					redirect_to controller: 'welcome', action: 'error_access_denied'
					return
				end
			else
				@user = nil
			end
			
			@destinations = CustomerDestination.where(customer_id: @customer.id, is_deleted: false).order('is_default DESC, created_at DESC').find_all
			@destinations = nil if(@destinations.first.blank?)
		end
		
		set_cabinet_user_profile_breadcrumb(pparams, @user, current_user)
		set_cabinet_breadcrumbs({:name => I18n.t(:customer, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, false)
	end
	
	
	def new
		@pparams = params.permit(:user_uid)

		@is_admin_or_usersmoder = current_user.is_admin_or_usersmoder?
		if(@is_admin_or_usersmoder && @pparams[:user_uid].present?)
			user_id = User.from_safe_uid(@pparams[:user_uid][0,SAFE_UID_MAX_LENGTH])
			if(user_id.nil?)
				redirect_to controller: 'welcome', action: 'error_access_denied'
				return
			end
		else
			user_id = current_user.id
			@pparams[:individual_anynm] = current_user.get_name_string
			@pparams[:individual_mail] = current_user.get_email_hidden_symbols
		end
		
		set_cabinet_user_profile_breadcrumb(@pparams, @user, current_user)
		set_cabinet_breadcrumbs({:name => I18n.t(:customer_new, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, false)

		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((.....), .....)
		@form_path = {:controller => :customers, action: :create}
	end
	
	
	def create
		set_cabinet_user_profile_breadcrumb(params, nil, current_user)
		
		if(request.post?)
			ret = update_create_fill_info('new', :create)
			return if(ret.nil?)
		
			if(ret)
				# Create Customer in DB
				@customer = Customer.create({user_id: @user_id, customer_type: @pparams[:int_customer_type], customer_contacts: @customer_contacts, customer_legal_info: @customer_legal_info})
				if(@customer.present? && !@customer.id.nil?)
					@bSavedOk = true
					@user.customers = {} if(@user.customers.blank?)
					@user.customers[@customer.id.to_s] = {}
					@user.save
				end
			end
		end
		
		if(!@bSavedOk)
			flash.now.alert = I18n.t(:unable_to_save_changes, scope: [:dt_breeze, :messages])
			@form_time_now = Time.now.utc.to_i
			@form_hash = form_hash_generate((.....), .....)
			@form_path = {:controller => :customers, action: :create}
			render 'new'
			return
		end
		
		flash.now.notice = I18n.t(:msg_new_customer_created, scope: [:dt_ishop, :cabinet, :profile])
		
		# Find user's stored delivery destinations
		@user_destinations = CustomerDestination.where(user_id: @user_id, is_deleted: false).order('is_default DESC, created_at DESC').find_all
		@user_destinations = nil if(@user_destinations.first.blank?)
		
		@allow_legal_info = true
		@allow_contacts = true
		render 'show'
	end

	
	def edit
		@pparams = params.permit(:user_uid)
		
		set_cabinet_user_profile_breadcrumb(@pparams, nil, current_user)
		set_cabinet_breadcrumbs({:name => I18n.t(:customer_edit, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, false)
		
		@is_admin_or_usersmoder = current_user.is_admin_or_usersmoder?
		if(@is_admin_or_usersmoder && @pparams[:user_uid].present?)
			user_id = User.from_safe_uid(@pparams[:user_uid][0,SAFE_UID_MAX_LENGTH])
			if(user_id.nil?)
				redirect_to controller: 'welcome', action: 'error_access_denied'
				return
			end
		else
			user_id = current_user.id
		end
		@user = ((current_user.id == user_id) ? current_user : User.where(id: user_id).first)
		
		customer_contacts = @customer.customer_contacts
		customer_contacts = {} if(customer_contacts.nil?)
		
		customer_legal_info = @customer.customer_legal_info
		customer_legal_info = {} if(customer_legal_info.nil?)
		
		@pparams[:customer_type_select] = ((@customer.customer_type == CUSTOMER_TYPE_LEGAL) ? 'legal' : 'individual')
		
		if(@customer.customer_type == CUSTOMER_TYPE_FIZ_LICO)
			@pparams[:individual_anynm]    = customer_contacts['name1']
			@pparams[:individual_contact]  = customer_contacts['phone1']
			if((@is_admin_or_usersmoder && (current_user.id != user_id)) or ((@user.email != customer_contacts['email1']) && (@user.unconfirmed_email != customer_contacts['email1'])))
				@pparams[:individual_mail] = customer_contacts['email1']
			else
				@pparams[:individual_mail] = User.email_hide_symbols(customer_contacts['email1'])
			end
		else
			@pparams[:legal_person1_name]  = customer_contacts['name1']
			@pparams[:legal_person1_phone] = customer_contacts['phone1']
			@pparams[:legal_person2_name]  = customer_contacts['name2']
			@pparams[:legal_person2_phone] = customer_contacts['phone2']
			
			if((@is_admin_or_usersmoder && (current_user.id != user_id)) or ((@user.email != customer_contacts['email1']) && (@user.unconfirmed_email != customer_contacts['email1'])))
				@pparams[:legal_person1_mail] = customer_contacts['email1']
			else
				@pparams[:legal_person1_mail] = User.email_hide_symbols(customer_contacts['email1'])
			end
			
			if((@is_admin_or_usersmoder && (current_user.id != user_id)) or ((@user.email != customer_contacts['email2']) && (@user.unconfirmed_email != customer_contacts['email2'])))
				@pparams[:legal_person2_mail] = customer_contacts['email2']
			else
				@pparams[:legal_person2_mail] = User.email_hide_symbols(customer_contacts['email2'])
			end
			
			
			
			customer_legal_info = @customer.customer_legal_info
			customer_legal_info = {} if(customer_legal_info.nil?)
			
			if((@pparams[:int_org_type] != ORGANIZATION_TYPE_IND_PREDP) && (@pparams[:int_org_type] != ORGANIZATION_TYPE_FIZ_LICO))
				@pparams[:legal_kpp] = customer_legal_info['kpp']
			end

		end
		
		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((.....), .....)
		@form_path = {:controller => :customers, action: :update}
	end

	
	def update
		set_cabinet_user_profile_breadcrumb(params, nil, current_user)
		
		ret = update_create_fill_info('edit', :update)
		return if(ret.nil?)
		
		if(ret)
			@bSavedOk = @customer.update({customer_type: @pparams[:int_customer_type], customer_contacts: @customer_contacts, customer_legal_info: @customer_legal_info})
		end
		
		if(!@bSavedOk)
			flash.now.alert = I18n.t(:unable_to_save_changes, scope: [:dt_breeze, :messages])
			set_cabinet_breadcrumbs({:name => I18n.t(:customer_edit, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, false)
			
			@form_time_now = Time.now.utc.to_i
			@form_hash = form_hash_generate((.....), .....)
			@form_path = {:controller => :customers, action: :update}
			
			render 'edit'
			return
		end
		
		flash.now.notice = I18n.t(:msg_customer_updated, scope: [:dt_ishop, :cabinet, :profile])
		set_cabinet_breadcrumbs({:name => I18n.t(:customer, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, false)
		
		# Find user's stored delivery destinations
		@destinations = CustomerDestination.where(customer_id: @customer.id, is_deleted: false).order('is_default DESC, created_at DESC').find_all
		@destinations = nil if(@destinations.first.blank?)
		
		@allow_legal_info = true
		@allow_contacts = true
		render 'show'
	end
	
	
	def destroy
		pparams = params.permit(:id, :confirm)
		bOk = false
		ret_json = {}
		can_do_job = false
		
		cval_1 = .....
		cval_2 = .....
		
		if(params[:confirm].present? && !request.get?)
			if(check_frontend_confirmation(params[:confirm], cval_1, cval_2, @customer[:created_at].to_i))
				can_do_job = true
			end
		else
			ret_json['confirm'] = ask_frontend_to_confirm(cval_1, cval_2, @customer[:created_at].to_i)
			ret_json['confirm_method'] = 'post'
			ret_json['confirm_text'] = I18n.t(:customer_delete_confirm, scope: [:dt_ishop, :cabinet, :profile]) + ' "' + @customer.pub_name.to_s + '"'
			ret_json['status_text'] = I18n.t(:must_confirm, scope: [:dt_breeze, :messages])
		end
		
		if(can_do_job)
			
			
			if(bOk)
				UsersManipulationsLog.event_log(action_name, I18n.t(:msg_customer_deleted, ttext: '', scope: [:dt_ishop,  :cabinet, :profile]), 'customer', @customer_id, current_user.id, false, false)
				
				CustomerDestination.where("(customer_id = ?) AND (orders_count = 0)", @customer_id).destroy_all
				CustomerDestination.where("(customer_id = ?) AND (orders_count != 0) AND (is_deleted IS FALSE)", @customer_id).find_each do |dest|
					dest.erase_instead_of_delete
					dest.save
				end
				
				
				
				if(user.present? && user.customers.present?)
					@customer_id = @customer_id.to_s
					user.customers.reject!{|k,v| k == @customer_id}
					user.customers = nil if(user.customers.blank?)
					user.save if(user.customers_changed?)
				end
				
				ret_json['status_text'] = I18n.t(:msg_customer_deleted, ttext: @customer_name, scope: [:dt_ishop,  :cabinet, :profile])
			else
				ret_json['status_text'] = I18n.t(:unable_to_save_changes, scope: [:dt_breeze, :messages])
			end
		end
		
		ret_json['status'] = (bOk ? 'ok' : 'error')
		render_with_changes_confirm(ret_json, true, user_profile_path(current_user, params), nil)
	end
	
	
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	private
	
	
	def authenticate_and_authorize_user_action
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		authorize Customer # Pundit authorization.
	end
	
	
	def authenticate_and_authorize_user_action_and_object
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		if(params[:id].blank?)
			respond_to do |format|
				format.html {
					if(action_name == 'show')
						redirect_to user_index_path
					else
						redirect_to controller: 'welcome', action: 'error_access_denied'
					end
					
				}
				format.json {  
					err = I18n.t(:access_denied, scope: [:dt_breeze, :messages])
					render :json => [{:status => 'error', :error => err, :status_text => err}], :status => 403
				}
			end
			return
		end
		
		@customer_safe_uid = params[:id][0,SAFE_UID_MAX_LENGTH]
		customer_id = Customer.from_safe_uid(@customer_safe_uid)
		if(customer_id.nil?)
			respond_to do |format|
				format.html {redirect_to controller: 'welcome', action: 'error_404'}
				format.json {
					err = I18n.t(:item_not_found, scope: [:dt_breeze, :messages])
					render :json => [{:status => 'error', :error => err, :status_text => err}], :status => 404
				}
			end
			return
		end
		
		@customer = Customer.where(id: customer_id).first
		if(@customer.blank? or (@customer[:is_deleted] && !current_user.is_admin?))
			respond_to do |format|
				format.html {redirect_to controller: 'welcome', action: 'error_404'}
				format.json {
					err = I18n.t(:item_not_found, scope: [:dt_breeze, :messages])
					render :json => [{:status => 'error', :error => err, :status_text => err}], :status => 404
				}
			end
			return
		end

		authorize @customer # Pundit authorization.
		return
	end
	
	
	def user_profile_path (current_user, pparams = nil, user = nil)
		
	end
	
	
	def set_cabinet_user_profile_breadcrumb(pparams, user, current_user)
		set_cabinet_breadcrumbs({:name => I18n.t(:profile, scope: [:dt_breeze, :cabinet, :menu_crumb]), :url => user_profile_path(current_user, pparams, user), :active => false}, true)
	end
	
	
	def update_create_fill_info (from_action_name, to_action_name)
		@pparams = params.permit(:fhash, :ftime, :user_uid, :customer_type_select, :individual_contact, :phone, :individual_anynm, :individual_mail,
			:email, :legal_name, :legal_ogrn, :legal_inn, :legal_kpp, :legal_addr_ur, :legal_addr_post, :legal_dir_post, :legal_dir_name,
			:legal_person1_name, :legal_person1_phone, :legal_person1_mail, :legal_person2_name, :legal_person2_phone, :legal_person2_mail)
		
		@is_admin_or_usersmoder = current_user.is_admin_or_usersmoder?
		@bSavedOk = false
		
		if(@pparams[:fhash].present?)
			if(@is_admin_or_usersmoder && @pparams[:user_uid].present?)
				user_id = User.from_safe_uid(@pparams[:user_uid][0,SAFE_UID_MAX_LENGTH])
				if(user_id.nil?)
					redirect_to controller: 'welcome', action: 'error_access_denied'
					return nil
				end
			else
				user_id = current_user.id
			end
			
			if(!form_hash_verify(@pparams[:fhash], ......)
				render 'welcome/error_form'
				return nil
			end
			
			if(@pparams[:customer_type_select].present?)
				
				# Verify contacts
				@result_err = Customer.validate_required_params_before_create(@pparams, [@user.email, @user.unconfirmed_email])
				if(@result_err['status_text'].present?)
					
				end
				
				# Fill info
				if(@pparams[:int_customer_type] == CUSTOMER_TYPE_FIZ_LICO)
					
				else
					email1 = ((@pparams[:int_legal_person1_mail].nil?) ? @pparams[:legal_person1_mail] : @pparams[:int_legal_person1_mail])
					email2 = ((@pparams[:int_legal_person2_mail].nil?) ? @pparams[:legal_person2_mail] : @pparams[:int_legal_person2_mail])
					@customer_contacts = {
						:name1 => @pparams[:legal_person1_name],
						:phone1 => @pparams[:legal_person1_phone],
						:email1 => email1,
						:name2 => @pparams[:legal_person2_name],
						:phone2 => @pparams[:legal_person2_phone],
						:email2 => email2,
						:pay_type => 0
					}
					
				end
				
				return true
			end
		end
		
		return false
	end
end
