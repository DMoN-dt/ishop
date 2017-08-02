class CreateGenCurrencyConversions < ActiveRecord::Migration[5.1]
  def change
    create_table :gen_currency_conversions do |t|
      t.timestamps
	  t.integer    :from_cn_iso_id, null: false # Из какой валюты (по международному коду)
	  t.integer    :to_cn_iso_id, null: false # В какую валюту (по международному коду)
	  
	  t.float      :ratio_live # Соотношение на биржах
	  t.column     :ratio_live_at, "timestamp with time zone" # Время, в которое было зафиксировано соотношение на биржах
	  
	  t.float      :ratio_cb_cur # Курс Центрбанка на текущие сутки
	  t.column     :ratio_cb_cur_at, "timestamp with time zone" # Время, в которое был зафиксирован курс ЦБ на текущие сутки
	  
	  t.float      :ratio_cb_next # Курс Центрбанка на следующие сутки
	  t.column     :ratio_cb_next_since, "timestamp with time zone" # Время, с которого будет действовать курс ЦБ на следующие сутки
    end
  end
end
