class SellerProductsGroup < ActiveRecord::Base
	has_one    :products_group, :foreign_key => :id, :primary_key => :prod_group_id
	has_one    :seller, :foreign_key => :id, :primary_key => :seller_id
	has_many   :seller_products, :foreign_key => :seller_group_id, :primary_key => :id
	
	
	def self.update_nodes_trees (upd_params, seller_id)
		seller_id_s = seller_id.to_s
		
		# Update Parent nodes list
		sql = "WITH RECURSIVE category_tree(id, main_group_id, path, cycle) AS (
   SELECT spg.id, spg.main_group_id, ARRAY[spg.id], false
   FROM seller_products_groups AS spg
   WHERE (spg.seller_id = " + seller_id_s + ") AND (spg.main_group_id = 0)
     UNION ALL
   SELECT spg.id, spg.main_group_id, path || spg.id, spg.id = ANY(path)
   FROM category_tree ctree
   JOIN seller_products_groups AS spg ON (spg.main_group_id = ctree.id)
   WHERE (spg.seller_id = " + seller_id_s + ") AND (spg.main_group_id != 0) AND (NOT cycle)
 )
 UPDATE seller_products_groups AS spg SET parent_nodes = array_remove(ctree.path, ctree.id)
 FROM category_tree ctree WHERE (ctree.id = spg.id)"
 
		upd_params[:updated_seller_products_groups_pnode] = ActiveRecord::Base.connection.update(sql)
		
		# Update Child nodes list
		sql = "UPDATE seller_products_groups AS spg SET child_nodes = (
  SELECT array_agg(spg2.id) AS ids FROM seller_products_groups AS spg2 WHERE (spg2.seller_id = " + seller_id_s + ") AND (spg2.parent_nodes @> ARRAY[spg.id])
 ) WHERE (spg.seller_id = " + seller_id_s + ")"
		
		upd_params[:updated_seller_products_groups_cnode] = ActiveRecord::Base.connection.update(sql)
	end
end
