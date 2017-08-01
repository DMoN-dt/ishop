class SearchController < ApplicationController
	
	def index
		@pparams = params.permit(:text, :page)

		if(@pparams[:text].present?)
			@pparams[:text] = @pparams[:text][0,400]
			@pparams[:text].strip!
			@pparams[:page] = (((@pparams[:page].present?) && (@pparams[:page].numeric?)) ? @pparams[:page].to_i : 1)
			
			@search_result = GenSearchProduct.joins(:seller_product => :seller_products_group).select('gen_search_products.id, gen_search_products.seller_prod_id')
			.fast_search(@pparams[:text]).with_pg_search_rank.where(seller_products: {bactive: true}, seller_products_groups: {bactive: true}).paginate(:page => @pparams[:page], :per_page => 10)
			
			if(@search_result.present?)
				@search_success = true
			else
				@search_success = false
				
				@new_query_text = @pparams[:text]
				(1..10).each do
					last_space_idx = @new_query_text.rindex(' ')
					break if(last_space_idx.nil?)
					
					@new_query_text = @new_query_text[0...last_space_idx]
					
					@search_result = GenSearchProduct.joins(:seller_product => :seller_products_group).select('gen_search_products.id, gen_search_products.seller_prod_id')
					.fast_search(@new_query_text).with_pg_search_rank.where(seller_products: {bactive: true}, seller_products_groups: {bactive: true}).paginate(:page => @pparams[:page], :per_page => 10)
					
					break if(@search_result.present?)
				end
			end
			
			@products = SellerProduct.eager_load(:seller_products_group, :seller)
			.where(id: @search_result.collect{|x| x.seller_prod_id}, bactive: true, seller_products_groups: {bactive: true}).find_all if(@search_result.present?)
			
			if(@products.present?)
				prod_img_ids = []
				@parent_groups = SellerProduct.parent_nodes_list(@products)
				@products.each{|prod| prod_img_ids += prod[:photo_ids] if(prod[:photo_ids].present?)}
				@prod_imgs = ProductsImage.where(id: prod_img_ids, b_allowed: true).find_all
			else
				@prod_imgs = [] # it should be blank, not nil.
			end

			@safeid_params = SellerProduct.prepare_make_safe_id
		end
	end
end
