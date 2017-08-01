class WelcomeController < ApplicationController
  before_action :set_footer_offer_info , :only => [:index]
  
  def index
	@carmakers = GenBrand.CarMakersList
  end
  
  
  def error_403 # для прямых заходов по URL
	render_error_403
  end
  
  
  def error_404
  end
  
  
  def error_access_denied # для перенаправлений посетителей при их действиях
	render_error_403
  end
  
  
  def error_nothing_found
  end
  
  
  def error_RobotTryLogin
	return head(444)
	#return head(:forbidden)
  end
  
  
  def select_car_model
	pparams = params.permit(:brand_name)
	
	@brand_name = nil
	
	if(pparams[:brand_name].present?)#
		pparams[:brand_name] = pparams[:brand_name][0,20]
		pparams[:brand_name].gsub!(' ','_')
		
		brand = GenBrand.where("(bcarmaker is TRUE) and (name ilike ?)", pparams[:brand_name]).first
		if(brand.present?)
			@brand_name = brand[:name]
			@brand_models = GenBrandModel.where("(((brand_id = ?) and (sub_brand_id is NULL)) OR (sub_brand_id = ?)) and (main_model_id = 0)", brand[:id], brand[:id]).order("name asc").find_all
		end
	end
	
  
  end
  
	### ======================================================================== PRIVATE ===============================================================================
	### ================================================================================================================================================================
	
	private
	
	def render_error_403
		if(flash[:alert])
			ie = flash[:alert].index(/(password|passw|created_at|datetime|jsonb)/)
			if(ie.nil?)
				flash[:alert_show] = flash[:alert]
			else
				ii = flash[:alert].index(/[(:'"`]/)
				ii = ie if(ii.nil? or (ii > ie))
				flash[:alert_show] = flash[:alert][0,ii]
			end
			flash[:alert] = nil
		end
		
		render 'error_403'
	end
end
