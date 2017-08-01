class ProductsGroup < ActiveRecord::Base
	def pub_id
		return self.id
	end
	
	def pub_id_link
		return pub_id
	end
	
	
	def self.update_nodes_trees (upd_params)
	
		# Update Parent nodes list
		sql = "WITH RECURSIVE category_tree(id, def_main_id, path, cycle) AS (
   SELECT spg.id, spg.def_main_id, ARRAY[spg.id], false
   FROM products_groups AS spg
   WHERE (spg.def_main_id = 0)
     UNION ALL
   SELECT spg.id, spg.def_main_id, path || spg.id, spg.id = ANY(path)
   FROM category_tree ctree
   JOIN products_groups AS spg ON (spg.def_main_id = ctree.id)
   WHERE (spg.def_main_id != 0) AND (NOT cycle)
 )
 UPDATE products_groups AS spg SET parent_nodes = array_remove(ctree.path, ctree.id)
 FROM category_tree ctree WHERE (ctree.id = spg.id)"
 
		upd_params[:updated_products_groups_pnode] = ActiveRecord::Base.connection.update(sql)
	end
end
