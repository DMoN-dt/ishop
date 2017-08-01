# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# СПОСОБЫ ПЛАТЕЖЕЙ
PaymentMethod.create(id: 0, parent_id: 0, name: nil, logo_name: nil, is_enabled: false)
PaymentMethod.create(id: 1, parent_id: 0, name: "Наличными", logo_name: 'paym_cash', is_enabled: false, sort_order: 1)

PaymentMethod.create(id: 2, parent_id: 0, name: "Электронный кошелёк", logo_name: 'paym_ewallet', is_enabled: true, sort_order: 3)
	PaymentMethod.create(id: 9,  parent_id: 2, name: "Яндекс.Деньги", logo_name: 'paym_ewallet_yamon', is_enabled: true, min_limit: 1, onetime_max_limit: 15000)
	PaymentMethod.create(id: 10, parent_id: 2, name: "QIWI Кошелёк", logo_name: 'paym_ewallet_qiwi', is_enabled: true)
	PaymentMethod.create(id: 11, parent_id: 2, name: "WebMoney", logo_name: 'paym_ewallet_wm', is_enabled: true)
	PaymentMethod.create(id: 12, parent_id: 2, name: "Кошелёк Элекснет", logo_name: 'paym_ewallet_elecsnet', is_enabled: false)
	
PaymentMethod.create(id: 3, parent_id: 0, name: "Интернет-банкинг", logo_name: 'paym_ibank', is_enabled: true, sort_order: 4)
	PaymentMethod.create(id: 14, parent_id: 3, name: "Сбербанк Онлайн", logo_name: 'paym_ibank_sbonline', is_enabled: true)
	PaymentMethod.create(id: 15, parent_id: 3, name: "Альфа-Клик", logo_name: 'paym_ibank_alfaclick', is_enabled: true)
	PaymentMethod.create(id: 16, parent_id: 3, name: "Банк Русский Стандарт", logo_name: 'paym_ibank_rustd', is_enabled: false)
	PaymentMethod.create(id: 17, parent_id: 3, name: "ВТБ24", logo_name: 'paym_ibank_vtb24', is_enabled: false)
	PaymentMethod.create(id: 18, parent_id: 3, name: "БИНБАНК", logo_name: 'paym_ibank_binbank', is_enabled: false)
	PaymentMethod.create(id: 19, parent_id: 3, name: "ФБ Инноваций и Развития", logo_name: 'paym_ibank_fbir', is_enabled: false) # BSS
	PaymentMethod.create(id: 20, parent_id: 3, name: "Совкомбанк", logo_name: 'paym_ibank_sovcom', is_enabled: false)
	PaymentMethod.create(id: 21, parent_id: 3, name: "Национальный банк ТРАСТ", logo_name: 'paym_ibank_nbtrust', is_enabled: false)
	PaymentMethod.create(id: 22, parent_id: 3, name: "HandyBank", logo_name: 'paym_ibank_handyb', is_enabled: false)
	PaymentMethod.create(id: 23, parent_id: 3, name: "Промсвязьбанк", logo_name: 'paym_ibank_promsvyaz', is_enabled: true)
	
PaymentMethod.create(id: 4, parent_id: 0, name: "Банковская карта", logo_name: 'paym_bcard', is_enabled: true, sort_order: 2)
	PaymentMethod.create(id: 24, parent_id: 4, name: "Visa", logo_name: 'paym_bcard_visa', is_enabled: true, min_limit: 1, onetime_max_limit: 250000, sort_order: 1)
	PaymentMethod.create(id: 25, parent_id: 4, name: "MasterCard", logo_name: 'paym_bcard_mastercard', is_enabled: true, min_limit: 1, onetime_max_limit: 250000, sort_order: 2)
	PaymentMethod.create(id: 26, parent_id: 4, name: "Maestro", logo_name: 'paym_bcard_maestro', is_enabled: true, min_limit: 1, onetime_max_limit: 250000, sort_order: 3)
	PaymentMethod.create(id: 27, parent_id: 4, name: "МИР", logo_name: 'paym_bcard_mir', is_enabled: true, min_limit: 1, onetime_max_limit: 15000, sort_order: 4)
	
PaymentMethod.create(id: 5, parent_id: 0, name: "Баланс мобильного телефона", logo_name: 'paym_mpbalance', is_enabled: true, sort_order: 5) # Mixplat
	PaymentMethod.create(id: 28, parent_id: 5, name: "Билайн", logo_name: 'paym_mpbalance_beeline', is_enabled: true, min_limit: 10)
	PaymentMethod.create(id: 29, parent_id: 5, name: "Мегафон", logo_name: 'paym_mpbalance_mega', is_enabled: true, min_limit: 1)
	PaymentMethod.create(id: 30, parent_id: 5, name: "МТС", logo_name: 'paym_mpbalance_mts', is_enabled: true, min_limit: 10, onetime_max_limit: 15000)
	PaymentMethod.create(id: 31, parent_id: 5, name: "Tele2", logo_name: 'paym_mpbalance_tele2', is_enabled: true, min_limit: 10)
	
PaymentMethod.create(id: 6, parent_id: 0, name: "Online-Кредит", logo_name: 'paym_onlineloan', is_enabled: false)

PaymentMethod.create(id: 7, parent_id: 0, name: "Мобильный платёж", logo_name: 'paym_mnfc', is_enabled: false, sort_order: 6)
	PaymentMethod.create(id: 32, parent_id: 7, name: "Apple Pay", logo_name: 'paym_mnfc_applepay', is_enabled: false)
	PaymentMethod.create(id: 33, parent_id: 7, name: "Samsung Pay", logo_name: 'paym_mnfc_samspay', is_enabled: false)
	
PaymentMethod.create(id: 34, parent_id: 0, name: "Торговые сети", logo_name: 'paym_retail', is_enabled: false, sort_order: 7) # rapida.ru
	PaymentMethod.create(id: 35, parent_id: 34, name: "Связной", logo_name: 'paym_retail_svyaznoi', is_enabled: true, onetime_max_limit: 15000)
	PaymentMethod.create(id: 36, parent_id: 34, name: "Евросеть", logo_name: 'paym_retail_evroset', is_enabled: true, onetime_max_limit: 15000)
	
PaymentMethod.create(id: 8, parent_id: 0, name: "Другие способы", logo_name: 'paym_others', is_enabled: true, sort_order: 8)
	PaymentMethod.create(id: 37, parent_id: 8, name: "MasterPass", logo_name: 'paym_others_masterpass', is_enabled: true, min_limit: 1, onetime_max_limit: 250000)
	PaymentMethod.create(id: 38, parent_id: 8, name: "ЕРИП (Беларусь)", logo_name: 'paym_others_erip_by', is_enabled: true)

# ПЛАТЁЖНЫЕ СИСТЕМЫ
PaymentService.create(id: 1, name: "Яндекс.Касса", logo_name: 'pay_svc_yakassa', is_enabled: true, priority: 10, use_sdk: false,
	params: {demo_pay_form_action: 'https://demomoney.yandex.ru/eshop.xml', demo_scid: nil, shop_id: nil, scid: nil, pay_form_action: ''}
)

# СПОСОБЫ ПЛАТЕЖЕЙ В ПЛАТЁЖНЫХ СИСТЕМАХ
## Яндекс.Касса
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "PC", method_id: 9,  min_limit: nil, onetime_max_limit: nil, prohibit_max_limit: false, is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "AC", method_id: 24,  min_limit: nil, onetime_max_limit: nil, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "AC", method_id: 25,  min_limit: nil, onetime_max_limit: nil, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "AC", method_id: 26,  min_limit: nil, onetime_max_limit: nil, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "AC", method_id: 27,  min_limit: nil, onetime_max_limit: nil, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "MC", method_id: 28, min_limit: nil, onetime_max_limit: 14000, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "MC", method_id: 29, min_limit: nil, onetime_max_limit: 14000, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "MC", method_id: 30, min_limit: nil, onetime_max_limit: nil, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "MC", method_id: 31, min_limit: nil, onetime_max_limit: 5000, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "WM", method_id: 11, min_limit: 1, onetime_max_limit: 60000, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "SB", method_id: 14, min_limit: 1, onetime_max_limit: 150000, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "AB", method_id: 15, min_limit: 1, onetime_max_limit: 60000, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "MA", method_id: 37, min_limit: nil, onetime_max_limit: nil, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "PB", method_id: 23, min_limit: 1, onetime_max_limit: 60000, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "QW", method_id: 10, min_limit: 1, onetime_max_limit: 250000, prohibit_max_limit: true,  is_enabled: true)
PaymentSvcMethod.create(pay_svc_id: 1, method_code: "EP", method_id: 38, min_limit: 1, onetime_max_limit: 15000, prohibit_max_limit: true,  is_enabled: true)

# ПОЧТОВЫЕ КОМПАНИИ
DeliveryPartner.create(name: 'Кит')
DeliveryPartner.create(name: 'Деловые линии')
DeliveryPartner.create(name: 'ПЭК')
DeliveryPartner.create(name: 'ЖелДорЭкспедиция')
DeliveryPartner.create(name: 'Энергия')
DeliveryPartner.create(name: 'ГлавДоставка')
DeliveryPartner.create(name: 'Экспресс-Авто')
DeliveryPartner.create(name: 'СДЭК')
DeliveryPartner.create(name: 'DPD')
DeliveryPartner.create(name: 'DHL Express')
DeliveryPartner.create(name: 'PONY EXPRESS')
DeliveryPartner.create(name: 'Ратэк')
DeliveryPartner.create(name: 'SPSR Express')
DeliveryPartner.create(name: 'Байкал Сервис')
DeliveryPartner.create(name: 'УралЭкспедиция')
DeliveryPartner.create(name: 'Первая Грузовая Компания')
DeliveryPartner.create(name: 'Easy Way') # Дочка ПЭК для ИМ
DeliveryPartner.create(name: 'PickPoint', is_pickpoint: true)
DeliveryPartner.create(name: 'Boxberry', is_pickpoint: true)
DeliveryPartner.create(name: 'Pulse Express', is_pickpoint: true)
