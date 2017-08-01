class Balance < ApplicationRecord
	belongs_to :customer, :foreign_key => :balance_id, :primary_key => :id
	# not yet ready  belongs_to :user, :foreign_key => :balance_id, :primary_key => :id
	has_many   :balance_transactions, :foreign_key => :balance_id, :primary_key => :id
	
	
	def self.list_history (balance_id, page, per_page)
		find = BalanceTransaction.where(balance_id: balance_id).order('created_at desc')
		history = find.paginate(:page => page, :per_page => per_page)
		if(history.blank? or (history.size == 0))
			history = find.paginate(:page => 1, :per_page => per_page) if(page != 1)
			history = nil if(history.blank? or (history.size == 0))
		end
		return history
	end
end
