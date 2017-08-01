
require "unicode_utils/downcase"
require "unicode_utils/upcase"

require 'common/codes_check' # проверка ОГРН, ИНН, БИК-Корр.счет, формы юр.лица
require 'common/constants' # константы, не перемещённые в config/initializers


if(!defined?(SITE_IS_UNDER_CONSTRUCTION))
	SITE_IS_UNDER_CONSTRUCTION = false
end


module BreadcrumbsOnRails
  module Breadcrumbs
    class SimpleBuilder < Builder

      def render
        @elements.collect do |element|
          render_element(element)
        end.join(@options[:separator] || " &raquo; ")
      end

      def render_element(element)
        if element.path == nil
          content = compute_name(element)
        else
          content = @context.link_to_unless_current(compute_name(element), compute_path(element), element.options || @options[:html])
        end
		if @options[:tag]
          @context.content_tag(@options[:tag], content, @options[:html])
        else
          ERB::Util.h(content)
        end
      end

    end
  end
end


class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception # Prevent CSRF attacks by raising an exception. For APIs, you may want to use :null_session instead.
  
  include Pundit
  #include PunditNamespaces
  
  # RESCUEs
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  rescue_from ActionController::InvalidAuthenticityToken do |exception|
	if user_signed_in?
		sign_out current_user
	end
	flash[:error] = "Время сеанса истекло. Для продолжения, необходимо Войти вновь."
  	redirect_to new_user_session_path
  end
  
  
  before_action :ensure_signup_complete, only: [:new, :create, :update, :destroy, :write_review]
  before_action :session_params_check
  #before_action :set_current_city
  #before_action :store_current_location, :unless => :devise_controller?
  before_action :set_user_environment

  #after_action  :metrika_store_visit

  if(SITE_IS_UNDER_CONSTRUCTION == true)
	before_action :show_under_construction
  end
  
  Date::DATE_FORMATS[:rus_normal_date] = '%d.%m.%Y'
  Time::DATE_FORMATS[:rus_normal_date] = '%d.%m.%Y'
  Time::DATE_FORMATS[:rus_post_date] = '%d.%m.%Y %k:%M'
  Time::DATE_FORMATS[:input_datestr] = '%Y-%m-%dT%H:%M'
  Time::DATE_FORMATS[:output_hh_mm] = '%H:%M'
  
  @global_cart_list = nil
  @footer_offer_info = false
  
  def generate_rnd_chars(num)
		o = [('a'..'z'), ('A'..'Z'), (0..9)].map { |i| i.to_a }.flatten
		return ((0...num).map { o[rand(o.length)] }.join)
  end
  
  def generate_rnd_chars_extra(num)
		o = [('a'..'z'), ('A'..'Z'), (0..9), ['!','@','#','$','%','+','(',')','_','-','=','<','.',':','~','|','\\','/','>','^','&','*','[',']','{','}']].map { |i| i.to_a }.flatten
		return ((0...num).map { o[rand(o.length)] }.join)
  end
  
  def after_sign_in_path_for(resource)
	current_user.check_and_set_join_date
	
	#if(current_user.terms_of_use_answered? == false) && (session['usage_agree_showed'].blank?)
	#	return '/users/terms_use'
	#end
	
	return '/user/profile_fill' if((current_user.customers.blank?) or (current_user.name.blank? && current_user.lastname.blank? && current_user.middlename.blank?))

	return '/cabinet/' #root_path #request.referrer
  end
  

  ### ======================================================================== PRIVATE ===============================================================================
  ### ================================================================================================================================================================
  
  private
  
  def session_params_check
	$current_user = (user_signed_in?) ? current_user : nil
	$action_name = action_name

	@visitor_hash = nil
	if(session["vis"].present?)
		@visitor_hash = session["vis"]["hash"].to_s[0,8]
	else
		session["vis"] = {}
	end
	
	if(@visitor_hash.nil?)
		@visitor_hash = cookie_visitor_value('vhash')
		if(@visitor_hash.blank?)
			@visitor_hash = generate_rnd_chars_extra(9)
			cookie_visitor_value('vhash', @visitor_hash, true)
		end
		session["vis"]["hash"] = @visitor_hash
	end
  end
  
  def cookie_visitor_value (val_key, val_data = nil, bset = false)
	ret = nil
	pcookie_visitor = cookies.encrypted[:vhash]
	if(pcookie_visitor.present?)
		cookie_visitor = JSON.parse(pcookie_visitor)
		if(cookie_visitor.is_a?(Hash))
			if(bset)
				cookie_visitor[val_key] = val_data
				if(val_key == 'guest_login')
					cookie_visitor['gltm'] = Time.now.utc.to_i
				end
			end
			ret = cookie_visitor[val_key]
			if(val_key == 'guest_login') && (cookie_visitor['gltm'].present?) && ((Time.now.utc.to_i - cookie_visitor['gltm'].to_i) > 1.hour)
				ret = nil
			end
		elsif(bset)
			cookie_visitor = {}
			cookie_visitor[val_key] = val_data
		end
		
	elsif(bset)
		cookie_visitor = {}
		cookie_visitor[val_key] = val_data
	end
	
	if(bset)
		if(!val_data.nil?)
			cookies.encrypted[:vhash] = {value: JSON.generate(cookie_visitor), expires: 1.month.from_now} 
		else
			cookies.encrypted[:vhash] = {value: JSON.generate(cookie_visitor.delete_if{|k,v| k == val_key}), expires: 1.month.from_now}
		end
	end
	return ret
  end
  
  
  def set_user_environment
	if(user_signed_in?)
		current_user.current_customer_id = session["customer"] if(session["customer"].present?)
		current_user.set_profile_environment
		
		@user_tzone = $user_tzone
		@user_tzone_name = $user_tzone_name

	else
		@user_tzone = {wtz: RUS_TIMEZONES['MSK'][:wtz], name: RUS_TIMEZONES['MSK'][:name]}
		@user_tzone_name = ' ' + I18n.t(:moscow_short, scope: [:dt_breeze, :tzone_name])
		
		$user_preferred_lang = GenSetting.page_selected_language
	end
  end
  
  
  def show_under_construction
	if(controller_name != 'welcome' && action_name != 'index')
		redirect_to root_path
	end
  end
  
  
  def user_not_authorized(exception)
    if(Rails.env.development?)
		if(exception.message.present? && (exception.message.length > 1000))
			flash[:alert] = exception.message[0,512]
		else
			flash[:alert] = exception.message
		end
	end
	redirect_to '/error/403'
  end
  
  
  def require_login
    unless logged_in?
      flash[:error] = "Необходимо Войти, чтобы получить доступ в данный раздел"
    end
  end
  
  def id_str_to_i (test_id)
	if(test_id.nil? == false)
		if(test_id.is_a?(String))
			if(test_id.numeric?)
				return test_id.to_i
			end
		elsif(test_id.is_a?(Integer))
			return test_id
		elsif(test_id.is_a?(Float))
			return test_id.to_i
		end
	end
	return 0
  end
  
  def email_is_valid? (e_mail)
	e_mail =~ VALID_EMAIL_REGEX
  end
  
  
	
	def form_hash_salt_user_role
		if(user_signed_in?)
			if(current_user.roles_mask > 1)
				if(current_user.is?(:super_admin))
					salt_user_roles = 'sdfsdfsdf'
				elsif(current_user.is?(:admin))
					salt_user_roles = 'sdfsdfsdfsdff'
				elsif(current_user.is?(:moderator_users))
					salt_user_roles = 'sdfsdasdasdasd'
				else
					salt_user_roles = current_user.roles_mask.to_s
				end
			else
				salt_user_roles = 'usr'
			end
		else
			salt_user_roles = ''
		end
		return salt_user_roles
	end
	
	def form_hash_generate (text_data, salt_addon = '', salt1 = nil, salt2 = nil)
		salt1 = '#&yTE' if(salt1.nil?)
		salt2 = '&^2hs' if(salt2.nil?)
		salt_addon = '' if(salt_addon.nil?)
		return ((text_data.present?) ? Digest::MD5.hexdigest(Digest::MD5.hexdigest(text_data + salt1 + form_hash_salt_user_role) + salt2 + salt_addon.to_s) : nil)
	end
	
	def form_hash_verify (test_hash, text_data, salt_addon = nil, salt1 = nil, salt2 = nil)
		return (test_hash == form_hash_generate(text_data, salt_addon, salt1, salt2))
	end
	
	def float_to_integer_pointzero (afloat)
		price_int = afloat.round(0)
		afloat = price_int.to_i if(afloat == price_int)
		return afloat
	end
	
	def set_nocache_headers
		response.headers["Cache-Control"] = "no-cache, no-store"
		response.headers["Pragma"] = "no-cache"
		response.headers["Expires"] = "Mon, 01 Jan 1990 00:00:00 GMT"
	end
	
	def destroy_cookie_guest_onlogin
		cookie_guest_login = cookies.encrypted[:guest_login]
		cookies.delete(:guest_login) if(cookie_guest_login.present?)
	end
	
	def set_footer_offer_info
		@footer_offer_info = true
	end
	
	def self.asset_exist?(path)
		if Rails.configuration.assets.compile
			Rails.application.precompiled_assets.include? path
		else
			Rails.application.assets_manifest.assets[path].present?
		end
	end
	
	def self.abort_security_restrictions
		abort('This page cannot be displayed because of security restrictions in a settings of web-site.')
	end
	
	def accept_url_acl_sid_info (acl, sid_param)
		url_sid = AccessList.read_url_sid(sid_param)
		if(url_sid.nil?)
			redirect_to controller: 'welcome', action: 'error_access_denied'
			return nil
		else
			acl.from_URL!(url_sid[:access_mask])
			doc_info = Document.from_pub_visible_safe_id(url_sid[:id], false, false)
			return {sid: url_sid, doc_info: doc_info}
		end
	end
	
	def set_cabinet_breadcrumbs (menu_arr = nil, add_cabinet_url = false)
		@txt_cabinet_title = I18n.t(:home_title, scope: [:dt_breeze, :cabinet])
		
		per_site_title = I18n.t(:html_title_short_part, scope: [:dt_breeze], :default => '')
		@txt_cabinet_html_title = @txt_cabinet_title
		@txt_cabinet_html_title += ' - ' + per_site_title if(per_site_title.present?)
		
		if(add_cabinet_url or !@inside_cabinet)
			add_breadcrumb @txt_cabinet_title, SITE_PATH_ADDRESS_ROOT_CANONICAL + cabinet_index_path
		elsif(!add_cabinet_url && @inside_cabinet) && (action_name == 'index')
			add_breadcrumb @txt_cabinet_title, nil, :active
		end
		
		if(!menu_arr.nil?)
			menu_arr = [menu_arr] if(menu_arr.is_a?(Hash))
			menu_arr.each do |menu_item|
				if(menu_item[:active])
					add_breadcrumb menu_item[:name], menu_item[:url], :active
				else
					add_breadcrumb menu_item[:name], menu_item[:url]
				end
			end
		end
		
		@inside_cabinet = true
	end
	
	def render_in_namespace (name)
		render controller_name + '/' + name + '/' + action_name
	end
	
	
	def marketplace_is_shop?
		return (!defined?(MARKETPLACE_MODE_ONLINE_SHOP) or MARKETPLACE_MODE_ONLINE_SHOP)
	end
	
	def marketplace_is_full?
		return (defined?(MARKETPLACE_MODE_ONLINE_SHOP) && (MARKETPLACE_MODE_ONLINE_SHOP != true))
	end
	
	
	def get_workspace_seller_params
		if(marketplace_is_shop?)
			@gws_seller_id = 0
		else
			@gws_seller_id = nil
			if(session['user'].present? && session['user']['ws'].present?)
				if(session['user']['ws']['seller_uid'].present?)
					@gws_seller_id = Seller.from_safe_uid(session['user']['ws']['seller_uid'][0,SAFE_UID_MAX_LENGTH])
				end
			end
		end
	end
	
	
	def get_undef_method_name (e)
		message = e.to_s
		ret_name = nil
		if(/undefined local variable or method/ !~ message)
			if(/\A.*`(\w*)'.*/ =~ message)
				ret_name = $1.to_s
			end
		end
		if(ret_name.nil?)
			ret_name = e.missing_name
			ret_name = nil if(/Class|Model|Module/ =~ ret_name)
		end
		return ret_name
	end
	
	
	def ask_frontend_to_confirm (const_value1, const_value2, variable, with_captcha = false)
		time_s = Time.now.to_i.to_s
		str_var = const_value1.to_s + variable.to_s
		str_enc = str_var + ...
		return (XXhash.xxh32(str_var, SAFE_UID_SEED_FRONTEND_VAR).to_s)
)
	end
	
	
	def check_frontend_confirmation (answer, const_value1, const_value2, variable, with_captcha = false)
		if(answer.present?)
			n0 = answer.rindex('-')
			if(n0.nil? == false)
				
			end
		end
		return false
	end
	
	
	def render_with_changes_confirm (json_answer, render_action_view = false, redirect_to_path = '/', pparams = nil)
		if(params[:json] == 'show_answer')
			render json: json_answer
		else
			respond_to do |format|
				format.json {
					render json: json_answer
				}
				format.html { 
					if(json_answer['confirm'].present?)
						render 'welcome/confirm_action'
					else
						if(render_action_view)
							@json_answer = json_answer
							render action_name
						else
							if(json_answer['status'] == 'ok')
								flash[:notice] = json_answer['status_text']
							else
								flash[:alert] = json_answer['status_text']
							end
							redirect_to redirect_to_path
						end
					end
				}
			end
		end
	end
	
end
