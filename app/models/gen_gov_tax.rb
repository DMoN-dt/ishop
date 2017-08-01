class GenGovTax < ApplicationRecord
	def self.get_by_id (tax_id, gov_taxes_arr = nil)
		return nil if(tax_id.nil? or (tax_id == 0))
		return gov_taxes_arr[tax_id] if(!gov_taxes_arr.nil? && gov_taxes_arr[tax_id].present?)

		prod_tax = GenGovTax.where(id: tax_id).first
		gov_taxes_arr[tax_id] = prod_tax if(!gov_taxes_arr.nil?)
		return prod_tax
	end
end