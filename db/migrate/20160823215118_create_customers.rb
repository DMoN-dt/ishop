class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.timestamps   null: false
	  t.integer      :user_id, null: false, default: 0 # Создатель первых сведений о покупателе
	  t.integer      :partner_id, null: false, default: 0 # Контрагент площадки
	  t.integer      :customer_type, limit: 2, null: false, default: 0 # физ.лицо = 0, юр.лицо/ИП = 1
	  t.jsonb        :customer_contacts # контакты покупателя: персона1(телефон, имя, email), персона2(...)
	  t.jsonb        :customer_legal_info # вся информация о покупателе-юр.лице
	  t.integer      :use_count, null: false, default: 0 # количество использований (для статистики)
	  t.jsonb        :acl # Права доступа пользователей Access List {user_id1: int_mask, user_id2: int_mask, ...}
	  t.boolean      :is_erased, null: false, default: false # контакты и адреса удалены (для не бесплатных экспресс-покупок или по запросу пдн)
	  t.boolean      :is_deleted, null: false, default: false
    end
  end
end
