class ExceptionsLog < ApplicationRecord

	def self.log_to_db(exception, action_name, request, is_critical, variables = nil)
		db = {
			class_name: exception.class.to_s[0,100],
			action_name: action_name,
			exception_msg: exception.to_s[0,512],
			trace: exception.backtrace.join("\n")[0,512],
			is_critical: true,
		}
		
		if(!request.nil?)
			db[:target_url] = request.url.to_s[0,512]
			db[:referer_url] = request.referer.to_s[0,512]
			db[:params] = request.params.inspect[0,1024]
			db[:user_agent] = request.user_agent.to_s[0,512]
		end
		
		if(variables.present?)
			db[:variables] = variables
		end
		
		ExceptionsLog.create(db)
	end
end
