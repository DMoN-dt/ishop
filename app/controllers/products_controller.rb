require 'common/products_import'

MEASURE_TYPE_PIECE = 1

if(!defined?(ProductPricing)) && (defined?(ProductPricing_General))
	class ProductPricing < ProductPricing_General
	end
end


class ProductsController < ApplicationController
	@@import_pages = [:import, :import_price, :import_price_groups_save, :import_price_products, :import_price_products_save]
	@@update_pages = [:update_with_suppliers, :update_with_suppliers_save]
	
	before_action :set_footer_offer_info, :only => [:show, :show_list]
	before_action :breadcrumbs_inside_import_supplier_price, :only => @@import_pages
	before_action :breadcrumbs_inside_update_supplier_prod,  :only => @@update_pages
	
	before_action :authenticate_and_authorize_user_action,             :only => (@@import_pages + @@update_pages)
	before_action :authenticate_and_authorize_user_action_and_object,  :only => [:images_add, :images_delete]
	after_action  :verify_authorized, :except => [:show, :show_archived, :show_list]
	
	before_action :get_workspace_seller_params, :only => (@@import_pages + @@update_pages)
	
	
	def self.import_supplier_adpo_full_tgroups
		abort('wow')
	end
	
	
	def show
		pparams = params.permit(:pub_id)
		
		if(pparams[:pub_id].present?)
			pid = SellerProduct.from_pub_id(pparams[:pub_id])
			@product = SellerProduct.eager_load(:seller_products_group, :seller).where(id: pid, seller_products_groups: {bactive: true}).first
			if(@product.present?)
				@parent_groups = SellerProduct.parent_nodes_list(@product)
				
				vendor_countries = {}
				if(@product[:seller_brand_id] != 0)
					@prod_brand = SellerBrand.includes(:gen_brand).where("seller_brands.id = ?", @product[:seller_brand_id]).first
					if(@prod_brand.present?)
						@prod_brand_name = @prod_brand.get_name
						@prod_vendor = @prod_brand.get_vendor
						
						if(@prod_vendor.present?)
							@prod_vendor_full_name_or_brand = ((@prod_vendor[:name_full].present?) ? @prod_vendor[:name_full] : @prod_brand_name)
							
							vendor_countries[@prod_vendor[:brand_country]] = nil if(@prod_vendor[:brand_country].present?)
							vendor_countries[@prod_vendor[:products_country]] = nil if(@prod_vendor[:products_country].present?)
						else
							@prod_vendor_full_name_or_brand = @prod_brand_name
						end
					end
				end
				
				vendor_countries[@product[:prod_info]['pctry'].to_i] = nil if(@product[:prod_info].present? && @product[:prod_info]['pctry'].present?)

				if(!vendor_countries.empty?)
					@prod_countries = AddrCountry.where(country_code: vendor_countries.keys).find_all
				end
				
				@safeid_params = SellerProduct.prepare_make_safe_id
			end
		end
		
		if(@product.blank?)
			render '_not_found'
			return
		end
		
		if(user_signed_in?)
			authenticate_and_authorize_user_action
			verify_authorized
			@is_signed_user = true
			
			@product.create_acl(current_user)
			@can_edit = @product.has_access?([:edit])
			if(@can_edit)
				@product_safe_uid = SellerProduct.pub_safe_uid(@safeid_params, @product[:id])
				@form_time_now = Time.now.utc.to_i
				@form_hash = form_hash_generate((.....), .....)
			end
			
		else
			@is_signed_user = false
		end
	end
	
	
	def show_archived
		pparams = params.permit(:pub_id, :order_safe_uid, :order_safe_uid_part, :sid)
		
		if(pparams[:order_safe_uid].present?) && (pparams[:order_safe_uid_part].present?)
			pparams[:order_safe_uid] = pparams[:order_safe_uid][0,SAFE_UID_MAX_LENGTH] 
			pparams[:order_safe_uid_part] = pparams[:order_safe_uid_part][0,SAFE_UID_MAX_LENGTH]
			pparams[:order_safe_uid] = pparams[:order_safe_uid].to_s + '.' + pparams[:order_safe_uid_part].to_s
		end

		order_id = Order.from_safe_uid(pparams[:order_safe_uid])
		if(order_id.nil?)
			redirect_to controller: 'welcome', action: 'error_404'
			return
		end
		
		if(user_signed_in?)
			authenticate_and_authorize_user_action
			verify_authorized
			@is_admin = current_user.is_admin?
			@is_signed_user = true
		else
			@is_signed_user = false
		end
		
		@oAcl = AccessList.new
		@oAcl.set_user(@is_signed_user, current_user)
		
		if(pparams[:sid].present?)
			pparams[:sid] = pparams[:sid][0,150] 
			url_acl = accept_url_acl_sid_info(@oAcl, pparams[:sid])
			return if(url_acl.nil?)
		else
			url_acl = nil
		end
		
		@order = Order.where(id: order_id).first
		if(@order.blank?)
			redirect_to controller: 'welcome', action: 'error_404'
			return
		end
		
		bOk = false
		if(!url_acl.nil?)
			doc_info = url_acl[:doc_info]
			if((!doc_info.nil?) && (doc_info[:shop] == SAFE_UID_PAYDOCUMENT_SHOP_ID))
				if(doc_info[:doc_type] == DOC_TYPE_ORDER)
					
				end
			end
		end
		@oAcl.set_default_acl if(!bOk)
		
		@order.acl_set_and_merge(@oAcl)
		if(!@order.has_access?([:view_list_items, :view_list_items_names, :view_list_items_summs]))
			redirect_to controller: 'welcome', action: 'error_access_denied'
			return
		end
		
		@product = nil
		if(pparams[:pub_id].present? && pparams[:pub_id].numeric?)
			pparams[:pub_id] = pparams[:pub_id][0,SAFE_UID_MAX_LENGTH].to_s
			if(@order[:products].present?) && (@order[:products].has_key?(pparams[:pub_id]))
				
				
			end
		end
		
		if(@product.nil?)
			redirect_to controller: 'welcome', action: 'error_404'
			return
		end
		
		@archived = true
		@safeid_params = SellerProduct.prepare_make_safe_id
		
		render 'show'
		return
	end
	
	
	def show_list
		pparams = params.permit(:cat_group_id, :brand_name, :model_name, :model_year_id, :model_year_num, :page)

		
		if(pparams[:cat_group_id].present?)
			if(pparams[:cat_group_id].numeric?)
				@cat_group_id = pparams[:cat_group_id].to_i
				@group = ProductsGroup.select('id').where("(id = ?) AND (b_show IS TRUE)", @cat_group_id).first
				@cat_group_id = 0 if(@group.blank?)
			else
				@cat_group_id = 0
			end
			
			if(@cat_group_id != 0)
				@groups = ProductsGroup.select('products_groups.id, products_groups.gr_name as gr_name, seller_products_groups.sort_order, seller_products_groups.id as seller_group_id, seller_products_groups.main_group_id as seller_main_id').joins(inner_join_seller_products).where("(products_groups.def_main_id = ?) AND (products_groups.b_show IS TRUE)", @cat_group_id).order('seller_products_groups.sort_order ASC NULLS LAST').find_all
				if(@groups.blank?) or (@groups.count == 0)
					@groups = nil
					
					page = (((pparams[:page].present?) && (pparams[:page].numeric?)) ? pparams[:page].to_i : 1)
					search_params = {brand_model_year_num: @brand_model_year_num, g_brand_model_id: @brand_model_id, g_brand_id: @brand_id, with_inactive: false}
					
					@result = SellerProduct.list_paginated(0, nil, @cat_group_id, search_params, page)
					@products = @result[:products]
					@seller_group = @result[:seller_group]
					
					prod_img_ids = []
					if(@products.present?)
						@parent_groups = SellerProduct.parent_nodes_list(@products)
						
						@products.each do |prod|
							prod_img_ids += prod[:photo_ids] if(prod[:photo_ids].present?)
						end
					
						if(@show_not_allowed_test_images)
							@prod_imgs = ProductsImage.where(id: prod_img_ids).find_all
						else
							@prod_imgs = ProductsImage.where(id: prod_img_ids, b_allowed: true).find_all
						end
					else
						@prod_imgs = [] # it should be blank, not nil.
					end
				end
			end
		end
		
		@safeid_params = SellerProduct.prepare_make_safe_id
	end

	
	# Upload Files (from comp or url)
	def images_add

		is_marketplace_moder_or_admin = (current_user.is?(:moderator_products) or current_user.is_admin?)
		
		if(params[:files].blank? && (!is_marketplace_moder_or_admin or params[:upload_urls].blank? or params[:upload_ids].blank?))
			render :json => {'files' => [{'error' => 'Не указаны файлы для загрузки.'}]}
			return
		end

		uploads = {}
		uploads[:bChanges] = false
		uploads[:images_max_num] = PRODUCT_IMAGE_MAX_FILE_COUNT
		
		if(@product[:photo_ids].present?)
			n = @product[:photo_ids].count
			if(n != 0)
				prod_imgs = ProductsImage.select('id').where(id: @product[:photo_ids]).limit(uploads[:images_max_num]).find_all
				nn = prod_imgs.size
				if(n != nn)
					if(nn == 0)
						@product[:photo_ids] = []
					else
						@product[:photo_ids] = prod_imgs.map{|p| p.id}
					end
					bChanges = true
					n = nn
				end
			end
			uploads[:images_max_num] -= n if(n <= 5)
		end
		
		if(uploads[:images_max_num] > 0)
			

		else
			render :json => {'files' => [{'error' => 'Превышено максимальное число изображений для товара.'}]}
			return
		end
		
		if(uploads[:uploaded_json_list].blank?)
			uploads[:uploaded_json_list] = [{'files' => [{'error' => 'Никаких изменений не произошло.'}]}]
		end

		if(uploads[:bChanges])
			ActiveRecord::Base.connection.execute("UPDATE seller_products SET photo_ids = (SELECT ARRAY(SELECT DISTINCT UNNEST(photo_ids || ARRAY#{@product[:photo_ids]}::int[]))) WHERE id = #{@product[:id]}")
		end
		
		ret = {:status => (uploads[:bChanges] ? 'ok' : 'error'), :files => uploads[:uploaded_json_list]}
		
		respond_to do |format|
			format.html {
				render :json => ret,
				:content_type => 'text/html',
				:layout => false
			}
			
			format.json {  
				render :json => ret
			}
		end
		
	end
	
	
	# Delete Images from Product and ProductImages if not used anymore
	def images_delete
		pparams = params.permit(:images)
		
		if(pparams[:images].blank?)
			render :json => {:status => 'error', :status_text => 'Не указаны изображения для удаления.'}
			return
		end
		
		ret = {:status => 'error', :status_text => 'Изображение не связано с данным товаром!'}
		
		if(@product[:photo_ids].present?)
			
			
		end
		
		respond_to do |format|
			format.html {
				render :json => ret,
				:content_type => 'text/html',
				:layout => false
			}
			
			format.json {  
				render :json => ret
			}
		end
	end
	
	
	def import
		seller_id = @gws_seller_id
		user_has_access = Seller.verified_access?(current_user, seller_id, nil, [:objorg_seller])
		if(!user_has_access)
			redirect_to controller: 'welcome', action: 'error_access_denied'
			return
		end
		
		@noscram_supplier_name = true
		
		@suppliers = SellerSupplier.where("(seller_id = ?) and (allow_import IS TRUE) and (import_func_id IS NOT NULL) and (import_func_hash IS NOT NULL)", seller_id).order('name ASC, short_name ASC, scram_name ASC').find_all
		@suppliers_cnt = @suppliers.size
		@suppliers = nil if(@suppliers_cnt == 0)
		
		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((.....), .....)
		
		render_in_namespace 'import'
	end
	
	
	def import_price
		pparams = params.permit(:fhash, :ftime, :supplier_select, :from_supplier_select)

		if(!form_hash_verify(pparams[:fhash], ....))
			render 'error'
			return
		end
		
		@is_admin_or_productmoder = current_user.is_admin_or_productmoder?
		@supplier = nil
		seller_id = @gws_seller_id
		user_has_access = nil
		
		if(pparams[:supplier_select] == 'select')
			if(pparams[:from_supplier_select].present?)
				supplier_uid = pparams[:from_supplier_select][0,60]
			end
		elsif(!pparams[:supplier_select].nil?)
			supplier_uid = pparams[:supplier_select][0,60]
		end
		
		if(!supplier_uid.nil?)
			supplier_data = SellerSupplier.from_safe_uid(supplier_uid)
			if(!supplier_data.nil?)
				if(marketplace_is_full?)
					seller_id = supplier_data[:seller_id] if(@is_admin_or_productmoder)
				end
				
				if((seller_id == supplier_data[:seller_id]) && (supplier_data[:supplier_id] != 0)) # supplier_id is ID, not seller_supplier_id
					user_has_access = Seller.verified_access?(current_user, seller_id, nil, [:objorg_seller]) if(user_has_access.nil?)
					if(user_has_access)
						@supplier = SellerSupplier.where("(id = ?) and (seller_id = ?) and (allow_import IS TRUE) and (import_func_id IS NOT NULL) and (import_func_hash IS NOT NULL)", supplier_data[:supplier_id], seller_id).first
					end
				end
			end
		end
		
		if(!user_has_access.nil? && !user_has_access)
			redirect_to controller: 'welcome', action: 'error_access_denied'
			return
		end

		if((@supplier.present?) && (@supplier[:allow_import]))
			@time_gr_start = Time.zone.now.utc

			@impres = @supplier.exec_import_function('groups', {filename: 'price.xls', seller_id: seller_id, supplier_id: @supplier[:seller_supplier_id]})
			
			if(!@impres.nil? && !@impres[:success].nil? && @impres[:success])

				
				@form_time_now = Time.now.utc.to_i
				@form_hash = form_hash_generate((.....), .....)
			else
				flash[:alert] = @impres[:alert] if(!@impres.nil? && !@impres[:alert].nil?)
			end
		
		else
			# Supplier import is restricted !
			
		end
		render_in_namespace 'import'
	end
	
	
	def import_price_groups_save
		pparams = params.permit(:fhash, :ftime, :supplier_uid, :hash, :groups)
		
		
		@upd_params = {}
		SellerProductsGroup.update_nodes_trees(@upd_params, seller_id) if(@groups_created != 0)
		ProductsGroup.update_nodes_trees(@upd_params) if(@global_groups_created != 0)
		
		
		@after_groups = 1
		@supplier_uid = supplier_uid
		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((.....), .....)
				
		render_in_namespace 'import'
	end
	
	
	def import_price_products
		pparams = params.permit(:fhash, :ftime, :supplier_uid, :hash, :groups)
		
		
		render_in_namespace 'import'
	end
	
	
	def import_price_products_save
		pparams = params.permit(:hash, :groups)
		
		
		render_in_namespace 'import'
	end
	
	
	def update_with_suppliers
		pparams = params.permit(:supplier_uid)
		
		seller_id = @gws_seller_id
		
		
		@form_time_now = Time.now.utc.to_i
		@form_hash = form_hash_generate((.....), .....)
		
		render_in_namespace 'update'
	end
	
	
	def update_with_suppliers_save
		pparams = params.permit(:fhash, :ftime, :supplier_uid, :supplier_select, :from_supplier_select, :add_new_goods, :upd_exist_goods, :upd_goods_avail_supp, :upd_goods_instock, :upd_goods_prices, :upd_goods_name, :upd_goods_info)
		pparams[:supplier_uid] = ((pparams[:supplier_uid].blank?) ? '' : pparams[:supplier_uid][0,60])

		if(!form_hash_verify(pparams[:fhash], ....))
			render 'error'
			return
		end
		
		@is_admin_or_productmoder = current_user.is_admin_or_productmoder?
		seller_id = @gws_seller_id
		
		
		if(!supplier_uid.nil?)
			supplier_data = SellerSupplier.from_safe_uid(supplier_uid)
			if(!supplier_data.nil?)
				if(marketplace_is_full?)
					seller_id = supplier_data[:seller_id] if(@is_admin_or_productmoder)
				end
				
				if((seller_id == supplier_data[:seller_id]) && (supplier_data[:supplier_id] != 0)) # seller_id is ID of Seller, not seller_supplier_id
					user_has_access = Seller.verified_access?(current_user, seller_id, nil, [:objorg_seller]) if(user_has_access.nil?)
					if(user_has_access)
						@supplier = SellerSupplier.select('id, seller_id, seller_supplier_id, name, short_name, scram_name').where("(id = ?) and (seller_id = ?) and (allow_import IS TRUE)", supplier_data[:supplier_id], seller_id).first
						@suppliers = [@supplier] if(@supplier.present?)
					end
				end
			end
		end
		
		if(!user_has_access.nil? && !user_has_access)
			redirect_to controller: 'welcome', action: 'error_access_denied'
			return
		end
		
		# Updates from Suppliers
		if(!@suppliers.nil?)
			@time_op_start = Time.zone.now.utc
			
			if(pparams[:upd_exist_goods] == 'on')
				if(pparams[:upd_goods_avail_supp] == 'on')
					@wait_upd_avail = true
					SellerProduct.update_available(@upd_params, seller_id, (pparams[:upd_goods_instock] == 'on'), true)
				end
			end
			
			if(pparams[:add_new_goods] == 'on')
				@need_insert_new_prods = true
				SellerSuppliersProductsInfo.update_seller_links(@upd_params, seller_id, (((pparams[:supplier_select] != 'all') && @supplier.present?) ? @supplier[:seller_supplier_id] : nil), false, true)
			end
		end
		
		# Updates from Own In-Stock
		

		# Update products Prices with Pricing Rules
		if(pparams[:upd_goods_prices] == 'on')
			@wait_upd_prices = true
			only_not_calculated_yet = false
			force_recalculate_warehouses = false
			
			ProductPricing.calc_products_prices(@upd_params, nil, seller_id, (pparams[:supplier_select] == 'all'), @suppliers, only_not_calculated_yet, force_recalculate_warehouses)
		end

		render_in_namespace 'update'
	end
	
	
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	private
	
	def authenticate_and_authorize_user_action
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		authorize SellerProduct # Pundit authorization.
	end
	
	
	def authenticate_and_authorize_user_action_and_object
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.

		if(params[:item_uid].blank?)
			respond_to do |format|
				format.html {
					redirect_to controller: 'welcome', action: 'error_access_denied'
				}
				format.json {  
					render :json => [{:status => 'error', :error => 'Доступ запрещён!', :status_text => 'Доступ запрещён!'}], :status => 403
				}
			end
			return
		end
		
		@item_safe_uid = params[:item_uid][0,SAFE_UID_MAX_LENGTH]
		item_id = SellerProduct.from_safe_uid(@item_safe_uid)
		if(item_id.nil?)
			respond_to do |format|
				format.html {
					redirect_to controller: 'welcome', action: 'error_404'
				}
				format.json {  
					render :json => [{:status => 'error', :error => 'Элемент не найден!', :status_text => 'Элемент не найден!'}], :status => 404
				}
			end
			return
		end
		
		@product = SellerProduct.where(id: item_id).first
		if(@product.blank?)
			respond_to do |format|
				format.html {
					redirect_to controller: 'welcome', action: 'error_404'
				}
				format.json {  
					render :json => [{:status => 'error', :error => 'Элемент не найден!', :status_text => 'Элемент не найден!'}], :status => 404
				}
			end
			return
		end
		
		authorize @product # Pundit authorization.
		return
	end
	
	
	def breadcrumbs_inside_import_supplier_price
		set_cabinet_breadcrumbs([
			{:name => I18n.t(:commerce, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => e_commerce_cabinet_index_path},
			{:name => I18n.t(:commerce_import_supp_goods, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => import_products_path}
		])
	end
	
	
	def breadcrumbs_inside_update_supplier_prod
		set_cabinet_breadcrumbs([
			{:name => I18n.t(:commerce, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => e_commerce_cabinet_index_path},
			{:name => I18n.t(:commerce_prod_update_from_suppliers, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => with_suppliers_update_products_path}
		])
	end

	
	def add_new_file_from_url (upload_path, upload_id, uploads)
		if((uploads[:images_max_num] > 0) && (uploads[:max_try_files_count] > 0) && upload_id.present?)
			if(upload_path =~ /\Ahttp(s)?:\/\/(.+\.)?(.+)\.(.+)\/(.+)(\.(png|jp(e)?g|jpe))?\z/)
				new_image = ProductsImage.new

				
			else
				uploads[:uploaded_json_list] << {:upload_id => upload_id, :error => 'Указанный адрес изображения не соответствует ожидаемому формату или типу файла.'}
				return true
			end
			uploads[:max_try_files_count] -= 1
			return true
		else
			return false
		end
	end
	
	
	def add_new_file (uploaded_file, uploads)
		if((uploads[:images_max_num] > 0) && (uploads[:max_try_files_count] > 0))



			return true
		else
			return false
		end
	end
end