class CabinetController < ApplicationController
	before_action :authenticate_and_authorize_user_action, :except => [:e_commerce]
	after_action  :verify_authorized, :except => [:e_commerce]
	
	before_action :prepare_inside_cabinet, :except => [:e_commerce]
	
	def index
		@is_allowed_to_ecommerce = current_user.is_allowed_to_ecommerce?
	end
	
	
	def e_commerce
		if(!user_signed_in?)
			render 'welcome/ad_ecommerce'
			return
		end
		
		authenticate_and_authorize_user_action
		verify_authorized
		set_cabinet_breadcrumbs({:name => I18n.t(:commerce, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, true)
		
		@is_allowed_to_ecommerce = current_user.is_allowed_to_ecommerce?
	end
	
	
	def orders
		pparams = params.permit(:list_type, :page)
		set_cabinet_breadcrumbs({:name => I18n.t(:orders, scope: [:dt_ishop, :cabinet, :menu_crumb]), :active => true}, true)
		
		page = ((pparams[:page].present? && pparams[:page].numeric?) ? pparams[:page].to_i : 1)
		per_page = 20
		
		@is_admin = current_user.is_admin?
		@is_moderator = (@is_admin or current_user.is?(:moderator_orders))
		
		ret = Order.list_orders(((pparams[:list_type].present?) ? pparams[:list_type] : nil), page, per_page, current_user, nil)
		
		@orders = ret[:orders]
		@title = ret[:title]
		@list_type = ret[:type]
		
		if(@orders.present? && (@orders.first.present?))
			@orders_ids = @orders.collect {|order| order[:id]}
			@prods_assemblies = OrdersProductsAssembly.where(order_id: @orders_ids).find_all
			@prods_assemblies = nil if(@prods_assemblies.first.blank?)
		end
		
		@order_safeid_params = Order.prepare_make_safe_id
		@prod_code_form = 0 # 0=Brand & ProdCode, 1=Artikul
	end

	
	def discounts
		set_cabinet_breadcrumbs({:name => I18n.t(:discounts, scope: [:dt_ishop, :cabinet, :menu_main]), :active => true}, true)
		render 'welcome/not_yet_available'
	end
	
	
	### =========== [ FULL MARKETPLACE ONLY ] ===========
	### =================================================
	if(MARKETPLACE_MODE_ONLINE_SHOP != true)
	
	
	end
	
	
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	private
	
	def authenticate_and_authorize_user_action
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		authorize Cabinet # Pundit authorization.
	end
	
	
	def prepare_inside_cabinet
		@inside_cabinet = true
		set_cabinet_breadcrumbs(nil, false)
	end
end