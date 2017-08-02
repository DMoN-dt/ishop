class CreateSellerPricingRules < ActiveRecord::Migration[5.1]
  def change
    create_table :seller_pricing_rules do |t| # Правила применения коэффициентов к ценам на товары поставщиков и товары в наличии на складах продавца
	  t.timestamps
	  t.integer    :seller_id, limit: 8 # ID продавца
	  t.string     :rule_name, limit: 128 # Наименование правила
	  
	  t.boolean    :use_fixed_prices_first, null: false, default: false # В первую очередь использовать загруженные фиксированные цены товаров из seller_products_fixed_prices
	  
	  t.float      :k_multiplier, null: false, default: 1.0 # Коэффициент умножения для цены
	  t.float      :k_plus, null: false, default: 0.0 # Коэффициент добавления к умноженной цене (в валюте цены)
	  
	  t.boolean    :on_all_products, null: false, default: false # На все товары из любой группы
	  
	  t.boolean    :on_product, null: false, default: false # На конкретный товар (что-то из id, own_id, code должно быть указано)
	  t.integer    :product_id, limit: 8 # ID товара на площадке
	  t.integer    :seller_own_prod_id, limit: 8 # Собственный ID товара в базе продавца
	  t.string     :product_code, limit: 70 # Код товара (модель, маркировка) - меньшая уникальность фильтрации (разные бренды, однотипные товары)
	  
	  t.integer    :only_prod_group_ids, limit: 8, array: true # Применимо только на эти группы товаров (включая дочерние группы)
	  t.integer    :except_prod_group_ids, limit: 8, array: true # Применимо на всё, кроме этих групп товаров (включая дочерние группы)
	  
	  t.float      :price_min # Минимальная начальная цена, к которой применяется правило (включительно)
	  t.float      :price_max # Максимальная начальная цена, к которой применяется правило (включительно)
	  
	  # Округление итоговых цен товаров
	  t.boolean    :round_prices, null: false, default: true # Округлять цены
	  t.integer    :round_to_num, limit: 2 # Округлять до количества цифр после запятой
	  t.boolean    :round_to_10, null: false, default: true # Округлять до целой части вплоть до 10
	  t.boolean    :round_to_50, null: false, default: true # Округлять до целой части вплоть до 50
	  t.boolean    :round_to_100, null: false, default: true # Округлять до целой части вплоть до 100
	  t.boolean    :round_to_largest, null: false, default: true # Округлять всегда в большую сторону
	  
	  t.integer    :schedule_id, limit: 8 # ID расписания
	  t.integer    :order_index, null: false, default: 0 # Порядок расположения правил (применяются от 0 к последнему). Используется последний найденный коэффициент.
	  
	  t.boolean    :for_base_price, null: false, default: false # Для формирования базовой публичной цены, иначе - правило применяется в заказе.
	  
	  t.boolean    :for_supplier_price, null: false, default: false # Применяется к цене поставщика
	  t.boolean    :for_instock_price, null: false, default: false # Применяется к цене наличия на складах продавца
	  
	  t.boolean    :stop_at_this_if_applied, null: false, default: false # Остановиться на этом правиле, если оно применимо к товару. Не используется пока.
	  t.boolean    :bactive, null: false, default: true # Правило активно
    end
  end
end
