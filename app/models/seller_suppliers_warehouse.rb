class SellerSuppliersWarehouse < ApplicationRecord
	#belongs_to :seller_supplier, :foreign_key => [:seller_id, :seller_supplier_id], :primary_key => [:seller_id, :seller_supplier_id]
	#has_many   :seller_suppliers_products, :foreign_key => [:seller_id, :seller_supplier_id, :seller_supplier_wrh_id], :primary_key => [:seller_id, :seller_supplier_id, :seller_supplier_wrh_id]
end
