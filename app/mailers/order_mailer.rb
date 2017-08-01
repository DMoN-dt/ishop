class OrderMailer < ApplicationMailer

	def order_placed (order)
		send_mails_to_recipients(order, I18n.t(:order_subj_placed, scope: @@ts_mail, tnum: @order_id), get_recipients_list(order.subscribed_to_purchase, true))
	end
	
	
	def order_agreed (order)
		if(order.agreed_at.present?)
			send_mails_to_recipients(order, I18n.t(:order_subj_agreed, scope: @@ts_mail, tnum: @order_id), get_recipients_list(order.subscribed_to_purchase, true))
		end
	end
	
	
	def order_accepted (order)
		if(order.accepted_at.present?)
			send_mails_to_recipients(order, I18n.t(:order_subj_accepted, scope: @@ts_mail, tnum: @order_id), get_recipients_list(order.subscribed_to_purchase, true))
		end
	end
	
	def accept_payment (order)
		send_mails_to_recipients(order, I18n.t(:order_subj_paid, scope: @@ts_mail, tnum: @order_id), get_recipients_list(order.subscribed_to_purchase, true))
	end
	
	
	def operator_new_order (order)
		send_mails_to_recipients(order, I18n.t(:order_opsubj_new, scope: @@ts_mail, tnum: @order_id), get_recipients_list(GenSetting.Moderators_List_new_orders, false))
	end
	
	
	private
	
	def send_mails_to_recipients (order, mail_subject, recipients_list)
		recipients_list.each_value do |recipient|
			@recipient = recipient
			@order = order
			@order_id = order.pub_visible_safe_id(false, false)
			@order_uid = Order.pub_safe_uid(nil, order.id, true)
			mail(to: recipient[:email], subject: mail_subject) {|format| format.html}
		end
	end
end
