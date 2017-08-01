class GenSearchProduct < ApplicationRecord
	belongs_to   :seller_product, :foreign_key => :seller_prod_id, :primary_key => :id
	
	include PgSearch
	pg_search_scope	:fast_search,
					:against => {:text_rank_a => 'A', :text_rank_b => 'B', :text_rank_c => 'C'}, # actually it is not used with tsvectors
					:using => {
						tsearch: {
							dictionary: 'russian',
							tsvector_column: 'ts_vector'
						}
					}
end
