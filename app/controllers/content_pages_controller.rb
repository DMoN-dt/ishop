class ContentPagesController < ApplicationController
	def show
		pparams = params.permit(:text_id)
		available_ids = ['contacts', 'howto_order', 'delivery', 'howto_pay', 'replace_refund', 'for_business', 'terms_sale', 'privacy_policy']
		
		if(pparams[:text_id].present?)
			text_id = pparams[:text_id][0,50]
			if(available_ids.include?(text_id))
				render text_id
			end
		end
	end
end
