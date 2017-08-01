class BalanceTransaction < ApplicationRecord
	belongs_to :balance, :foreign_key => :id, :primary_key => :balance_id
	
	
end
