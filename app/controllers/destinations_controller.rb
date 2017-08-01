class DestinationsController < ApplicationController
	before_action :authenticate_and_authorize_user_action_and_object, :except => [:new, :create, :index]
	before_action :authenticate_and_authorize_user_action, :only => [:new, :create, :index]
	after_action  :verify_authorized

	
	def index
		pparams = params.permit(:user_uid, :customer_uid)
		
		set_cabinet_breadcrumbs({:name => I18n.t(:profile, scope: [:dt_breeze, :cabinet, :menu_crumb]), :url => profile_user_index_path, :active => false}, true)
		
		user_id = verify_user_uid(pparams, true)
		return if(user_id.nil?)
		
		ret = verify_customer_uid(pparams)
		return if(ret.nil?)
		customer_id = ret[:customer_id]
		
		if(!customer_id.nil? && @customer.present?)
			set_cabinet_breadcrumbs({:name => I18n.t(:customers, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => customers_path, :active => false}, false)
			@customer_type = @customer.customer_type
			@customer_fiz_or_ip = (@customer[:customer_legal_info].present? && (@customer[:customer_legal_info]['orgtype'] == ORGANIZATION_TYPE_IND_PREDP))
		end

		@destinations = find_stored_destinations(pparams, user_id, customer_id)
	end
	
	
	def create
		@pparams = pparams = params_for_edit_create(params)
		bSavedOk = false
		
		if(pparams[:fhash].present? && request.post?)
			user_id = verify_user_uid(pparams, false)
			return if(user_id.nil?)
			
			ret = verify_customer_uid(pparams)
			return if(ret.nil?)
			customer_id = ret[:customer_id]

			if(!form_hash_verify(pparams[:fhash], .....)
				render 'welcome/error_form'
				return
			end

			# Verify required fields
			verify_required_fields(pparams)
			
			if(@result_err['status_text'].present?)
				if(@isAjax)
					render json: @result_err
				else
					@form_time_now = Time.now.utc.to_i
					@form_hash = form_hash_generate((.....), .....)
					
					render 'new'
				end
				return
			end
			
			# Create Destination in DB

			
			@destination = CustomerDestination.create({
				customer_id: customer_id,
				user_id: user_id,
				delivery_type: 0,
				addr: dest_addr,
				person: nil,
				is_private: true,
				is_default: (pparams[:use_default] == '1')
			})
			bSavedOk = true if(@destination.present? && !@destination.id.nil?)
		end

		set_cabinet_breadcrumbs({:name => I18n.t(:profile, scope: [:dt_breeze, :cabinet, :menu_crumb]), :url => profile_user_index_path, :active => false}, true)
		if(@customer.present?)
			set_cabinet_breadcrumbs({:name => I18n.t(:customers, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => customers_path, :active => false}, false)
			@customer_type = @customer.customer_type
			@customer_fiz_or_ip = (@customer[:customer_legal_info].present? && (@customer[:customer_legal_info]['orgtype'] == ORGANIZATION_TYPE_IND_PREDP))
		end
		if(!bSavedOk)
			set_cabinet_breadcrumbs({:name => I18n.t(:destination_new, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, false)
			
			flash.alert = I18n.t(:unable_to_save_changes, scope: [:dt_breeze, :messages])
			@form_time_now = Time.now.utc.to_i
			@form_hash = form_hash_generate((.....), .....)
			@form_path = {:controller => :destinations, action: :create}
			render 'new'
			return
		end
		
		flash.now.notice = I18n.t(:msg_new_destination_created, scope: [:dt_ishop, :cabinet, :profile])
		
		if(@customer.present?)
			redirect_to customer_path(id: Customer.pub_safe_uid(nil,@customer.id.to_i,true).gsub('.', '%2E'))
		else
			@destinations = find_stored_destinations(pparams, user_id, customer_id)
			render 'index'
		end
	end
	
	
	def new
		pparams = params.permit(:user_uid, :customer_uid)

		user_id = verify_user_uid(pparams, true)
		return if(user_id.nil?)
		
		ret = verify_customer_uid(pparams)
		return if(ret.nil?)
		customer_id = ret[:customer_id]
		
		set_cabinet_breadcrumbs({:name => I18n.t(:profile, scope: [:dt_breeze, :cabinet, :menu_crumb]), :url => profile_user_index_path, :active => false}, true)
		if(@customer.present?)
			set_cabinet_breadcrumbs({:name => I18n.t(:customers, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => customers_path, :active => false}, false)
			@customer_type = @customer.customer_type
			@customer_fiz_or_ip = (@customer[:customer_legal_info].present? && (@customer[:customer_legal_info]['orgtype'] == ORGANIZATION_TYPE_IND_PREDP))
			
			@customer.ensure_acl_exist(current_user)
		end
		set_cabinet_breadcrumbs({:name => I18n.t(:destination_new, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, false)
		
		@pparams = pparams
		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((.....), .....)
		@form_path = {:controller => :destinations, action: :create}
	end
	
	
	def edit
		pparams = params.permit(:user_uid, :customer_uid)

		user_id = verify_user_uid(pparams, true)
		return if(user_id.nil?)
		
		vparams = verify_customer_uid(pparams)
		return if(vparams.nil?)
		
		# Verify the destination is for this User or Customer
		if(@destination.user_id != user_id) && (vparams[:customer_id].nil? or (@destination.customer_id != vparams[:customer_id]))
			redirect_to controller: 'welcome', action: 'error_access_denied'
			return
		end
		
		set_cabinet_breadcrumbs({:name => I18n.t(:profile, scope: [:dt_breeze, :cabinet, :menu_crumb]), :url => profile_user_index_path, :active => false}, true)
		if(@customer.present?)
			set_cabinet_breadcrumbs({:name => I18n.t(:customer, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => customer_path(id: Customer.pub_safe_uid(nil,@customer.id.to_i,true).gsub('.', '%2E')), :active => false}, false)
			@customer_type = @customer.customer_type
			@customer_fiz_or_ip = (@customer[:customer_legal_info].present? && (@customer[:customer_legal_info]['orgtype'] == ORGANIZATION_TYPE_IND_PREDP))
			
			@customer.ensure_acl_exist(current_user)
		end
		set_cabinet_breadcrumbs({:name => I18n.t(:destination, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, false)
		
		
		@pparams = pparams
		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((.....), .....)
		@form_path = {:controller => :destinations, action: :update}
	end

	
	def update
		@pparams = params_for_edit_create(params)
		bSavedOk = false
		
		if(@pparams[:fhash].present?)
			user_id = verify_user_uid(@pparams, false)
			return if(user_id.nil?)
			
			vparams = verify_customer_uid(@pparams)
			return if(vparams.nil?)

			if(!form_hash_verify(@pparams[:fhash], ....))
				render 'welcome/error_form'
				return
			end
			
			# Verify the destination is for this User or Customer
			if(@destination.user_id != user_id) && (vparams[:customer_id].nil? or (@destination.customer_id != vparams[:customer_id]))
				redirect_to controller: 'welcome', action: 'error_access_denied'
				return
			end

			# Verify required fields
			verify_required_fields(@pparams)
			
			if(@result_err['status_text'].present?)
				if(@isAjax)
					render json: @result_err
				else
					@form_time_now = Time.now.utc.to_i
					@form_hash = form_hash_generate((.....), .....)
					
					render 'edit'
				end
				return
			end
			
			
			new_default = (!@destination.is_default && upd[:is_default])
			
			# Update Destination in DB
			bSavedOk = @destination.update(upd)
			
			if(new_default)
				CustomerDestination.where("(id != ?) AND (user_id = ?) AND (customer_id = ?) AND (is_deleted IS FALSE)", @destination.id, @destination.user_id, @destination.customer_id).update_all({is_default: false})
			end
		end

		if(!bSavedOk)
			set_cabinet_breadcrumbs({:name => I18n.t(:profile, scope: [:dt_breeze, :cabinet, :menu_crumb]), :url => profile_user_index_path, :active => false}, true)
			
			set_cabinet_breadcrumbs({:name => I18n.t(:destination_edit, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, false)
			
			flash.now.alert = I18n.t(:unable_to_save_changes, scope: [:dt_breeze, :messages])
			@form_time_now = Time.now.utc.to_i
			@form_hash = form_hash_generate((.....), .....)
			@form_path = {:controller => :destinations, action: :update}
			render 'edit'
			return
		end
		
		flash.notice = I18n.t(:msg_destination_updated, scope: [:dt_ishop, :cabinet, :profile])
		
		if(@customer.present?)
			redirect_to customer_path(id: Customer.pub_safe_uid(nil,@customer.id.to_i,true).gsub('.', '%2E'))
		else
			if(current_user.id == user_id)
				redirect_to profile_user_index_path
			else
				redirect_to profile_user_index_path(id: @user.pub_safe_uid(nil,true).gsub('.', '%2E'))
			end
		end
	end
	
	
	def destroy
		pparams = params.permit(:id, :confirm)
		bOk = false
		ret_json = {}
		can_do_job = false
		
		cval_1 = @destination[:id].to_s + @destination[:user_id].to_s
		cval_2 = params[:id].to_s + action_name
		
		if(params[:confirm].present? && !request.get?)
			if(check_frontend_confirmation(params[:confirm], cval_1, cval_2, @destination[:created_at].to_i))
				can_do_job = true
			end
		else
			
		end
		
		if(can_do_job)
			
			
			
		end
		
		ret_json['status'] = (bOk ? 'ok' : 'error')
		render_with_changes_confirm(ret_json, true, nil)
	end
	
	
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	private
	
	
	def authenticate_and_authorize_user_action
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		authorize CustomerDestination # Pundit authorization.
	end
	
	
	def authenticate_and_authorize_user_action_and_object
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		if(params[:id].blank?)
			respond_to do |format|
				format.html {
					if(action_name == 'show')
						redirect_to profile_user_index_path
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
		
		@destination_safe_uid = params[:id][0,SAFE_UID_MAX_LENGTH]
		destination_id = CustomerDestination.from_safe_uid(@destination_safe_uid)
		if(destination_id.nil?)
			respond_to do |format|
				format.html {redirect_to controller: 'welcome', action: 'error_404'}
				format.json {
					err = I18n.t(:item_not_found, scope: [:dt_breeze, :messages])
					render :json => [{:status => 'error', :error => err, :status_text => err}], :status => 404
				}
			end
			return
		end
		
		@destination = CustomerDestination.where(id: destination_id, is_deleted: false).first
		if(@destination.blank?)
			respond_to do |format|
				format.html {redirect_to controller: 'welcome', action: 'error_404'}
				format.json {
					err = I18n.t(:item_not_found, scope: [:dt_breeze, :messages])
					render :json => [{:status => 'error', :error => err, :status_text => err}], :status => 404
				}
			end
			return
		end

		authorize @destination # Pundit authorization.
		return
	end
	
	
	def verify_user_uid (pparams, get_user = false)
		@is_admin_or_usersmoder = current_user.is_admin_or_usersmoder?
		if(@is_admin_or_usersmoder && pparams[:user_uid].present?)
			
		else
			user_id = current_user.id
		end
		
		if(get_user)
			@user = ((current_user.id == user_id) ? current_user : User.where(id: user_id).first) # for Admin or UsersModer a User could be not existing
		end
		return user_id
	end
	
	
	def verify_customer_uid (pparams)
		if(pparams[:customer_uid].present?)
			
		else
			customer_id = nil
		end
		
		return {customer_id: customer_id}
	end
	
	
	def verify_required_fields (pparams)
		if(GenSetting.trade_between_countries?)
			
		end

		pparams[:region] = pparams[:region][0,120].strip if(pparams[:region].present?)
		if(pparams[:region].blank?)
			@result_err['status_text'] = I18n.t(:msg_region_not_specified, scope: [:dt_ishop, :cabinet, :profile])
			@result_err['bad_fields'] << 'region'
			@result_err['bad_reasons'] << 'e'
		end
		
		pparams[:city] = pparams[:city][0,120].strip if(pparams[:city].present?)
		if(pparams[:city].blank?)
			@result_err['status_text'] = I18n.t(:msg_city_not_specified, scope: [:dt_ishop, :cabinet, :profile])
			@result_err['bad_fields'] << 'city'
			@result_err['bad_reasons'] << 'e'
		end
		
		
	end
	
	
	def find_stored_destinations (pparams, user_id, customer_id)
		if(pparams[:customer_uid].present? && !customer_id.nil?)
			dest = CustomerDestination.where(user_id: user_id, customer_id: customer_id, is_deleted: false).order('is_default DESC, created_at DESC').find_all
		else
			dest = CustomerDestination.where(user_id: user_id, is_deleted: false).order('is_default DESC, created_at DESC').find_all
		end
		dest = nil if(dest.first.blank?)
		return dest
	end
	
	
	def params_for_edit_create (params)
		@is_admin_or_usersmoder = current_user.is_admin_or_usersmoder?
		@result_err = {'status_text': [], 'bad_fields': [], 'bad_reasons': []}
		return params.permit(:fhash, :ftime, :user_uid, :customer_uid, :country, :region, :postcode, :city, :street, :house, :apartment, :use_default)
	end
end
