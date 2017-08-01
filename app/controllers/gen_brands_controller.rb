class GenBrandsController < ApplicationController
	
	def get_submodels
		pparams = params.permit(:brand_name, :id, :ajax, :bcarmaker)
		ret_json = {'status' => 'error', 'status_text' => 'Неправильный запрос'}
		
		if(pparams[:ajax]=='Y')
			if(pparams[:id].present? && pparams[:id].numeric?)
				pparams[:id] = pparams[:id].to_i
				if(pparams[:brand_name].present?)
					pparams[:brand_name] = pparams[:brand_name][0,20]
					pparams[:brand_name].gsub!(' ','_')
					
					if(pparams[:bcarmaker].present? && pparams[:bcarmaker])
						brand = GenBrand.select('id').where("(id = ?) and (bcarmaker is TRUE) and (name ilike ?)", pparams[:id], pparams[:brand_name]).first
					else
						brand = GenBrand.select('id').where("(id = ?) and (name ilike ?)", pparams[:id], pparams[:brand_name]).first
					end
					
					if(brand.present?)
						brand_id = brand[:id]
						brand_models = GenBrandModel.select('id, name').where("(((brand_id = ?) and (sub_brand_id is NULL)) OR (sub_brand_id = ?)) and (main_model_id = 0)", brand_id, brand_id).order("name asc").find_all
						if(brand_models.present?)
							ret_json = {'status' => 'ok', 'status_text' => '', 'result' => {'cnt' => brand_models.count, 'list' => brand_models.to_json}}
						else
							ret_json = {'status' => 'ok', 'status_text' => '', 'result' => {'cnt' => 0}}
						end
					else
						ret_json = {'status' => 'error', 'status_text' => 'Марка не найдена'}
					end
				end
			end
		end
		
		respond_to do |format|
			format.json { render json: ret_json }
		end
	end
	
	def get_submodel_years
		pparams = params.permit(:brand_name, :id, :model_name, :ajax, :bcarmaker)
		ret_json = {'status' => 'error', 'status_text' => 'Неправильный запрос'}
		
		if(pparams[:ajax]=='Y')
			if(pparams[:id].present? && pparams[:id].numeric?)
				pparams[:id] = pparams[:id].to_i
				if(pparams[:brand_name].present?) && (pparams[:model_name].present?)
					pparams[:brand_name] = pparams[:brand_name][0,20]
					pparams[:brand_name].gsub!(' ','_')
					pparams[:model_name] = pparams[:model_name][0,100]
					pparams[:model_name].gsub!(' ','_')

					brand_model = GenBrandModel.select('id').joins("INNER JOIN gen_brands ON ((gen_brand_models.brand_id = gen_brands.id) OR ((gen_brand_models.sub_brand_id IS NOT NULL) AND (gen_brand_models.sub_brand_id = gen_brands.id)))").where("(gen_brand_models.id = ?) and (gen_brand_models.main_model_id = 0) and (gen_brand_models.name ilike ?) and (gen_brands.name ilike ?)", pparams[:id], pparams[:model_name], pparams[:brand_name]).first
					if(brand_model.present?)
						brand_models = GenBrandModel.select("gen_brand_models.id, (gen_brand_models.name || ' ' || gen_brand_models.model_year_first || '-' || gen_brand_models.model_year_last) AS name").where("(gen_brand_models.main_model_id = ?)", pparams[:id]).order("name asc").find_all
						if(brand_models.present?)
							ret_json = {'status' => 'ok', 'status_text' => '', 'result' => {'cnt' => brand_models.count, 'list' => brand_models.to_json}}
						else
							ret_json = {'status' => 'ok', 'status_text' => '', 'result' => {'cnt' => 0}}
						end
					else
						ret_json = {'status' => 'error', 'status_text' => 'Марка/модель не найдена'}
					end
				end
			end
		end
	
		respond_to do |format|
			format.json { render json: ret_json }
		end
	end
end
