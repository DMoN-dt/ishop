class UsersManipulationsLog < ActiveRecord::Base
	
	def self.event_log (procedure, log_text, obj_type, obj_id, user_id, is_sys_internal = false, is_cron = false)
		user_log = UsersManipulationsLog.create({
			
		})
		return ((user_log.present?) ? user_log.id : nil)
	end
end
