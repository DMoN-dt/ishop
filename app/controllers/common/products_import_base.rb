require 'roo'

class ProductsImportModule
	
	### GENERAL METHODS
	
	def self.import_file_XLS (filename)
		filepath = './tmp/uploads/'
		if(filename.present?)
			if(Dir.exist?(filepath))
				filepath += filename
				if(File.exist?(filepath))
					ofile = Roo::Spreadsheet.open(filepath, extension: :xls) # expand_merged_ranges: true
					return ofile
				else
					abort("file doesn't exist")
				end
			else
				abort("temp uploads path doesn't exist")
			end	
		end
		return nil
	end
	
	
	def self.XLS_Read_Value (xls, sheet, sheet_name, row, column, result, go_to_link, through_row_until_null, check_right_null)
		if(result.nil?)
			result = {cell_empty: true, cell_data: nil, null_around: nil, sheet2: nil, sheet2_name: '', bad_link: nil}
		else
			result[:cell_empty] = true
			result[:cell_data] = nil
			result[:null_around] = nil
			result[:sheet2_name] = '' if(result[:sheet2_name].nil?)
			result[:bad_link] = nil
		end
		
		scell = sheet.cell(row, column, sheet_name)
		if(scell.present?)
			sheet_link = nil
			sheet2 = nil
			sheet2_name = nil
			
			if(!go_to_link)
				result[:cell_data] = scell
				result[:cell_empty] = false
				
			elsif(scell =~ /\A#(.*)!R([0-9]*)C([0-9]*)\z/)
				scell.gsub(/\A#(.*)!R([0-9]*)C([0-9]*)\z/){sheet_link = $1, $2, $3}
				if(sheet_link[0].present?)
					
					
				else #битая ссылка на ячейку
					result[:bad_link] = true
				end
				
			elsif(scell =~ /\A#(.*)!(.*)\z/) #ячейка содержит непонятную ссылку на другой лист
				result[:bad_link] = true
				
			else #ячейка содержит не ссылку на другой лист
				result[:cell_data] = scell
				result[:cell_empty] = false
			end
		end
		
		return result
	end
	
	
	def self.import_is_row_table_header? (xls, sheet, sheet_name, nrow, col, last_col, need_price_meets_num, need_avail_meets_num, read_res, go_to_link, through_row_until_null, check_right_null)
		found_header = 0
		price_meets_num = 0
		avail_meets_num = 0
		price_col_found = false
		first_cell = true
		null_before = true
		null_after = false
		null_after_full = false
		first_cell_col = 0
		
		until(col > last_col)
			read_res = XLS_Read_Value(xls, sheet, sheet_name, nrow, col, read_res, true, true, true)
			
			if(!read_res[:cell_empty] && read_res[:cell_data].is_a?(String))
				is_hdr = true
				type = nil
				null_after_full = false
				case (read_res[:cell_data].strip! || read_res[:cell_data])
					when 'Код'
						type = :code
					when 'Марка'
						type = :make_brand
					
					else
						is_hdr = false
						if(first_cell)
							first_cell = false
							first_cell_col = col
							read_res[:row_first_data] = read_res[:cell_data]
							read_res[:row_first_data_col] = col
							if(col == last_col)
								null_after = true
								null_after_full = true
							end
						end
				end
				
				if(is_hdr)
					
				end
			else
				if(first_cell_col != 0)
					if(col == (first_cell_col + 1))
						null_after = true
						null_after_full = true
					end
				end
			end
			
			col += 1
		end
		
		if(!read_res.nil?)
			
		end
		
		return read_res
	end
	
	
	def self.convert_value_to_type (value, info)
		if((!info.nil?) && (info.is_a?(Hash)))
			if(info[:type].nil?)
				
			else
				if(info[:type] == :int)
					if(value.is_a?(Float) or value.is_a?(Integer) or value.numeric?)
						
					else
						value = nil
					end
				elsif(info[:type] == :float)
					value.gsub!(',','.') if(value.is_a?(String))
					if(value.is_a?(Float) or value.is_a?(Integer) or value.numeric?)
						
					else
						value = nil
					end
				end
			end
		else
			if(value.is_a?(Float))
				
			end
		end
		
		return value
	end
	
	
	def self.seller_group_get_global_id (seller_group_id)
		grp = SellerProductsGroup.select('id, prod_group_id').where(id: seller_group_id).first
		return grp[:prod_group_id] if(grp.present?)
		return nil
	end
	
	
	def self.tree_detect_level (tree_levels, cur_column, cur_row, cur_level)
		largest_smallest_row = 0
		largest_smallest_col = 0
		largest_smallest_col_diff = 0
		largest_smallest_lvl_col_diff = 0
		largest_smallest_lvl = nil
		largest_smallest_lvl_match = 0
		largest_smallest_lv = nil
		
		smallest_largest_col = 0
		smallest_largest_col_diff = 0
		smallest_largest_lvl_col_diff = 0
		smallest_largest_lvl = nil
		smallest_largest_lvl_match = 0
		smallest_largest_lv = nil
		
		main_id = nil
		n = cur_level + 1
		until(n < 1)
			if(tree_levels[n].present?)
				tree_levels[n].reverse_each do |lvl|
					if(lvl[:row] < cur_row)
						if(lvl[:col] <= cur_column)
							if(lvl[:col] > largest_smallest_col)
								
								
							elsif((n < largest_smallest_lvl) && (lvl[:row] > largest_smallest_row) && (largest_smallest_row != 0))
								
							end
							
						else
							if(lvl[:col] < smallest_largest_col)
								
							end
						end
					end
				end
			end
			n -= 1
		end
		
		if(largest_smallest_lvl.nil?)
			
		elsif(smallest_largest_lvl.nil?)
			
		else
			
			
		end
	end
	
	
	def self.import_price_store_tmp_group(group_name, seller_id, dealer_id, result, new_groups, column, tree_start_col)
		global_grp_id = nil
		global_main_id = 0
		seller_grp_id = nil
		seller_grp_main_id = nil
		exist_grp = nil
		new_global = false
		new_import = false
		
		prev_group_id = result[:prev_group_id]
		dealer_first_import = result[:dealer_first_import]
		main_id = result[:main_id]
		groups_not_found_sellerimport_cnt = result[:groups_not_found_sellerimport_cnt]
		groups_exists_cnt = result[:groups_exists_cnt]
		
		result[:new_group_id] = 0
		
		# Find already exisiting groups
		if(!dealer_first_import)
			
			
		end
			
		if(exist_grp.blank?)
			new_import = true
			groups_not_found_sellerimport_cnt += 1
			
			
			if(exist_grp.present?)
				
			end
			
			if(!global_grp_id.nil? && (global_grp_id != 0))
				
				
			else
				
			end
		
		else # Found in seller's import list
			if(exist_grp.is_a?(ActiveRecord::Base))
				groups_exists_cnt += 1
				seller_grp_id = exist_grp[:group_id]
				seller_grp_main_id = exist_grp[:main_group_id]
			
			elsif(exist_grp.is_a?(Enumerator))
				tmp_1 = 0
				tmp_2 = 0
				enum_cnt = 0
				
				exist_grp.each do |egrp|
					enum_cnt += 1
					break if(enum_cnt > 1)
					tmp_1 = egrp[:group_id]
					tmp_2 = egrp[:main_group_id]
				end
				if(enum_cnt == 1)
					groups_exists_cnt += 1
					seller_grp_id = tmp_1
					seller_grp_main_id = tmp_2
				end
			end
		end
		
		group = TmpImportGroup.new(seller_id: seller_id, dealer_id: dealer_id,
									gr_name: group_name, main_id: main_id, tree_level: (column - tree_start_col),
									exist_id: seller_grp_id, exist_main_id: seller_grp_main_id, new_global: new_global, new_import: new_import
									)
		if(group.nil? == false)
			if(group.save)
				prev_group_id = group.id
				result[:new_group_id] = prev_group_id
				result[:new_seller_grp_id] = seller_grp_id
				result[:seller_grp_main_id] = seller_grp_main_id
				new_groups[prev_group_id] = {exist_seller_id: seller_grp_id, exist_seller_main_id: seller_grp_main_id, exist_global_id: global_grp_id}
			end
		end

	end

end