class PayInvoicesController < ApplicationController
	before_action :authenticate_and_authorize_user_action , :except => [:show]
	after_action  :verify_authorized, :except => [:show]
	
	
	def show
		set_cabinet_breadcrumbs(nil)
		
		pparams = params.permit(:id, :uid, :sid, :print_ver)
		
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
		sid_doc_info = nil
		
		pparams[:id] = pparams[:id][0,SAFE_UID_MAX_LENGTH] if(pparams[:id].present?)
		pparams[:uid] = pparams[:uid][0,5] if(pparams[:uid].present?)
		
		if(pparams[:id].present? && pparams[:uid].present?)
			if(pparams[:uid].blank?)
				redirect_to controller: 'welcome', action: 'error_access_denied'
				return
			end
			doc_info = Document.from_pub_visible_safe_id(pparams[:id], false, true)
			doc_info = nil if(!doc_info.nil? && (doc_info[:shop] != SAFE_UID_PAYDOCUMENT_SHOP_ID))
		else
			doc_info = nil
		end
		
		if(pparams[:sid].present?)
			pparams[:sid] = pparams[:sid][0,SID_URL_MAX_LENGTH]
			
			url_acl = accept_url_acl_sid_info(@oAcl, pparams[:sid])
			return if(url_acl.nil?)
			sid_doc_info = url_acl[:doc_info]
			sid_doc_info = nil if(!sid_doc_info.nil? && (sid_doc_info[:shop] != SAFE_UID_PAYDOCUMENT_SHOP_ID))
			@sid_param = pparams[:sid]
			
			if(!doc_info.nil? && !sid_doc_info.nil?)
				if(sid_doc_info[:doc_type] == doc_info[:doc_type])
					if(sid_doc_info[:id] == doc_info[:id]) && (sid_doc_info[:doc_year] == doc_info[:doc_year])
						doc_info = sid_doc_info
					end
				end
			end
		end
		
		if(!doc_info.nil? && (doc_info[:doc_type] == DOC_TYPE_PAY_INVOICE))
			sql = "(id = ?) and (to_char(created_at, 'YY') = ?)"
			if(doc_info[:doc_rs] == DOC_RELATIONSHIP_CUSTOMER)
				@pay_invoice = PayInvoiceCustomer.where(sql, doc_info[:id], doc_info[:doc_year].to_s).first
			elsif(doc_info[:doc_rs] == DOC_RELATIONSHIP_PARTNER)
				@pay_invoice = PayInvoicePartner.where(sql, doc_info[:id], doc_info[:doc_year].to_s).first
			else
				@pay_invoice = nil
			end
			doc = @pay_invoice
		else
			doc = nil
		end
		
		if(doc.present?)
			if(doc[:hashstr].present?)
				if(!pparams[:uid].nil? && (doc[:hashstr] != pparams[:uid]))
					redirect_to controller: 'welcome', action: 'error_404'
					return
				end
				
				if(!sid_doc_info.nil?)
					if(sid_doc_info[:doc_type] == doc_info[:doc_type]) && (sid_doc_info[:id] == doc_info[:id]) && (sid_doc_info[:doc_year] == doc_info[:doc_year])
						if(doc[:hashstr] != url_acl[:idhashstr])
							redirect_to controller: 'welcome', action: 'error_404'
							return
						end
						
						doc.acl_set_and_merge(@oAcl)
					
					elsif(sid_doc_info[:doc_type] == DOC_TYPE_ORDER) or (sid_doc_info[:doc_type] == DOC_TYPE_AKT_WORK)
						@oAcl_parent = @oAcl
						@oAcl = nil
					end
				else
					@oAcl.remove_URL!
					doc.acl_set_and_merge(@oAcl)
				end
			end
			
			@is_partner_rs = (doc_info[:doc_rs] == DOC_RELATIONSHIP_PARTNER)
			@has_access_view = false
			
			# Verify access rights
			if(doc.has_access?([:view_list_items]))
				@has_access_view = true
			
			elsif(!sid_doc_info.nil?) && (!@oAcl_parent.nil?)
				if(doc[:doc_parent_type] == sid_doc_info[:doc_type]) && (doc[:doc_parent_id] == sid_doc_info[:id])
					
					sql = "(id = ?) and (to_char(created_at, 'YY') = ?)"
					if(doc[:doc_parent_type] == DOC_TYPE_ORDER)
						@order = Order.where(sql, doc[:doc_parent_id], sid_doc_info[:doc_year].to_s).first
						parent_doc = @order
					end
					
					parent_doc_is_partner_rs = (sid_doc_info[:doc_rs] == DOC_RELATIONSHIP_PARTNER)
					
					if(parent_doc.present?)
						if(parent_doc[:hashstr].present?)
							bOk = (parent_doc[:hashstr] == url_acl[:sid][:idhashstr])
						else
							bOk = true
						end
						
						if(bOk)
							parent_doc.acl_set_and_merge(@oAcl_parent)
							@has_access_view = parent_doc.has_access?([:pay])
						end
					end
				end
			end
			
			if(!@has_access_view)
				redirect_to controller: 'welcome', action: 'error_access_denied'
				return
			end
			
			if(doc[:doc_client_id].present? && (doc[:doc_client_id] != 0))
				if(doc_info[:doc_rs] == DOC_RELATIONSHIP_CUSTOMER)
					@customer = Customer.where(id: doc[:doc_client_id]).first
				elsif(doc_info[:doc_rs] == DOC_RELATIONSHIP_PARTNER)
					@partner = Partner.where(id: doc[:doc_client_id]).first
				end
			end
			
			@contract = ContractCustomer.where(id: doc[:contract_id]).first if(doc[:doc_client_contract_id].present? && (doc[:doc_client_contract_id] != 0))
			
			@rekvizit = GenSetting.where("setgroup = 'rekvizit'").first
			@rekvizit = (((@rekvizit.present?) && (@rekvizit[:setts].present?)) ? @rekvizit[:setts] : nil)
		
		else
			redirect_to controller: 'welcome', action: 'error_404'
			return
		end
		
		@pay_invoice_pub_id = @pay_invoice.pub_visible_safe_id(DOC_TYPE_PAY_INVOICE, nil, nil, false, (@is_partner_rs.present? && @is_partner_rs))
		@pay_invoice_pub_date = @pay_invoice.created_at.to_formatted_s(:rus_normal_date)
		
		if(pparams[:print_ver].present?) && (pparams[:print_ver] == true)
			@isPrint = true

			respond_to do |format|
				format.html {
					render '_show', layout: false
				}
				format.pdf {  
					@isPdf = true
					render pdf: (@pay_invoice_pub_id + '_' + @pay_invoice_pub_date), layout: false, template: 'pay_invoices/_show.html'
				}
			end
		else
			@isPrint = false
			
			if(doc[:doc_parent_type] == DOC_TYPE_ORDER)
				set_cabinet_breadcrumbs({:name => I18n.t(:orders, scope: [:dt_ishop, :cabinet, :menu_crumb]), :url => orders_cabinet_index_path})
				doc_parent_year = doc[:created_at].utc.year.to_s
				@order = Order.where("(id = ?) and (to_char(created_at, 'YYYY') = ?)", doc[:doc_parent_id], doc_parent_year).first if(@order.nil?)
				if(@order.present?)
					@order_pub_visible_safe_id = @order.pub_visible_safe_id(false, false, false)
					set_cabinet_breadcrumbs({:name => @order_pub_visible_safe_id.to_s, :url => ('/orders/show' + '?' + URI.encode_www_form('order_uid' => Order.pub_safe_uid(nil,doc[:doc_parent_id],true)))})
				end
				set_cabinet_breadcrumbs({:name => I18n.t(:payinv_id, scope: [:dt_ishop, :cabinet, :menu_crumb]) + @pay_invoice_pub_id, :active => true})
			end
			
			render '_show'
		end
	end

	
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	private
	
	
	def authenticate_and_authorize_user_action
		authenticate_user! # Devise authentication. It must be called after protect_from_forgery to CSRF-token work properly.
		authorize Document # Pundit authorization.
	end
	
end
