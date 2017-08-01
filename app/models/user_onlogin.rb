class UserOnlogin < ActiveRecord::Base
	
	def self.find_recent (user_id, visitor_hash, interval = '1 hour')
		return UserOnlogin.where("(user_id = ?) AND (updated_at BETWEEN (CURRENT_TIMESTAMP AT TIME ZONE 'UTC' - interval '" + interval + "') AND (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')) AND (visit_hash = ?)", user_id, visitor_hash).order("updated_at desc").first
	end
	
	def self.new_or_update_recent (user_id, visitor_hash, ip_addr, to_do)
		
	end
	
	
	private
end
