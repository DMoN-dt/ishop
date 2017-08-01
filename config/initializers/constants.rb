VALID_EMAIL_REGEX = /\A([\w+\-]\.?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

RESTRICTED_NAMES = ['Главный','главный','Админ','админ','Аноним','аноним','Модератор','модератор','Тайный','тайный','Доверенный','доверенный','Довереный','довереный','Представитель','представитель','Загруз','загруз','ЗАГРУЗ']

TXT_MSG_NOTHING_DONE='Операция завершилась безрезультатно.'
TXT_MSG_SAME_REQ_EXIST_WAIT_MODER='Вы уже подали аналогичный запрос.<br/>Требуется подождать ответа модератора до 3 дней.'


RUS_TIMEZONES = {'USZ1' => {:msk_offset => 'MSK-1', :name => 'Калининградское время (UTC+2)', :cities => 'Калининград', :wtz => 'Europe/Kaliningrad'},
'MSK'  => {:msk_offset => 'MSK',   :name => 'Московское время (UTC+3)', :cities => 'Москва, Санкт-Петербург, Севастополь, Волгоград, Мурманск, Краснодар', :wtz => 'Europe/Moscow', :name_short => 'мск'},
'SAMT' => {:msk_offset => 'MSK+1', :name => 'Самарское время (UTC+4)', :cities => 'Самара, Ижевск', :wtz => 'Europe/Samara'},
'YEKT' => {:msk_offset => 'MSK+2', :name => 'Екатеринбургское время (UTC+5)', :cities => 'Екатеринбург, Челябинск, Пермь, Уфа, Оренбург, Тюмень, Курган', :wtz => 'Asia/Yekaterinburg', :name_short => 'екб'},
'OMST' => {:msk_offset => 'MSK+3', :name => 'Омское время (UTC+6)', :cities => 'Омск, Новосибирск, Томск, Барнаул, Горно-Алтайск', :wtz => 'Asia/Omsk'},
'KRAT' => {:msk_offset => 'MSK+4', :name => 'Красноярское время (UTC+7)', :cities => 'Красноярск, Кемерово , Абакан, Кызыл', :wtz => 'Asia/Krasnoyarsk'},
'IRKT' => {:msk_offset => 'MSK+5', :name => 'Иркутское время (UTC+8)', :cities => 'Иркутск, Улан-Удэ, Чита', :wtz => 'Asia/Irkutsk'},
'YAKT' => {:msk_offset => 'MSK+6', :name => 'Якутское время (UTC+9)', :cities => 'Якутск, Благовещенск', :wtz => 'Asia/Yakutsk'},
'VLAT' => {:msk_offset => 'MSK+7', :name => 'Владивостокское время (UTC+10)', :cities => 'Владивосток, Хабаровск, Магадан , Биробиджан, Южно-Сахалинск', :wtz => 'Asia/Vladivostok'},
'SRET' => {:msk_offset => 'MSK+8', :name => 'Среднеколымское время (UTC+11)', :cities => 'Среднеколымск, Черский, Северо-Курильск', :wtz => 'Asia/Srednekolymsk'},
'PETT' => {:msk_offset => 'MSK+9', :name => 'Камчатское время (UTC+12)', :cities => 'Петропавловск-Камчатский, Анадырь', :wtz => 'Asia/Kamchatka'}
}

PAYMENT_SERVICE_YANDEX_KASSA = 1

# Способы оплаты PAY_TYPE
PAY_TYPE_CASH               = 1
PAY_TYPE_BANK_CARD          = 2
PAY_TYPE_NFC                = 4
PAY_TYPE_ONLINE             = 8
PAY_TYPE_BANK_PAY_INVOICE   = 16
PAY_TYPE_COD_AT_PICKPOINT   = 32
PAY_TYPE_MUTUAL             = 64
PAY_TYPE_COD                = 128
PAY_TYPE_BANK_CARD_COD      = 256
PAY_TYPE_NFC_COD            = 512
PAY_TYPE_BALANCE            = 1024

PAY_TYPES = {
	'cash' => PAY_TYPE_CASH,
	'bank_card' => PAY_TYPE_BANK_CARD,
	'nfc' => PAY_TYPE_NFC,
	'online' => PAY_TYPE_ONLINE,
	'bank' => PAY_TYPE_BANK_PAY_INVOICE, # Оплата по счёту через банк
	'at_pickpoint' => PAY_TYPE_COD_AT_PICKPOINT, # Cash-on-delivery at pickpoint - оплата в ТК при получении, наложный платёж через почту
	'mutual' => PAY_TYPE_MUTUAL, # Взаиморасчёт
	'cod' => PAY_TYPE_COD, # Cash-on-delivery
	'bcdod' => PAY_TYPE_BANK_CARD_COD, # BankCard-on-delivery
	'nfcod' => PAY_TYPE_NFC_COD, # NFC-on-delivery
	'customer_balans' => PAY_TYPE_BALANCE, # С баланса личного счёта покупателя
}

# Способы онлайн-оплаты PAY_METHOD
PAY_METHOD_CASH                  =  1 # Наличными
PAY_METHOD_ELECTRONIC_WALLET     =  2 # Электронным кошельком
PAY_METHOD_ONLINE_BANK           =  3 # Через интернет-банк
PAY_METHOD_BANK_CARD             =  4 # Банковской картой
PAY_METHOD_MOBILE_PHONE_BALANCE  =  5 # Баланс мобильного
PAY_METHOD_ONLINE_LOAN           =  6 # Online-Кредит
PAY_METHOD_NFC                   =  7 # Мобильный платёж NFC
PAY_METHOD_OTHERS                =  8 # Другие способы
PAY_METHOD_RETAIL                = 34 # Торговые сети

BALANCE_CHANGE_MONEY_RECEIPTS      = 1
BALANCE_CHANGE_SALARY              = 2
BALANCE_CHANGE_PURCHASE            = 3
BALANCE_CHANGE_REFUND_TO_BALANCE   = 4
BALANCE_CHANGE_REFUND_TO_PAYER     = 5
BALANCE_CHANGE_MONEY_WITHDRAWAL    = 6
BALANCE_CHANGE_TAXES_PAYMENT       = 7
BALANCE_CHANGE_TARIFF_PAYMENT      = 8
BALANCE_CHANGE_MONTHLY_PAYMENT     = 9
BALANCE_CHANGE_MONEY_TRANSFER      = 10

DOCUMENT_TYPE__ACT_REFUND_TOBALANS = 4
DOCUMENT_TYPE__ACT_REFUND_PAYMENT = 6
DOCUMENT_TYPE__ACT_MONEY_COME = 8


PRODUCT_MEASURE_TYPE = {
1 => {:f_sg => 'штука', :f_pl => 'штук', :lite_sg => 'шт.', :is_integer => true},
2 => {:f_sg => 'грамм', :f_pl => 'грамм', :lite_sg => 'г', :is_integer => false},
3 => {:f_sg => 'килограмм', :f_pl => 'килограмм', :lite_sg => 'кг', :is_integer => false},
4 => {:f_sg => 'тонна', :f_pl => 'тонн', :lite_sg => 'т', :is_integer => false},
5 => {:f_sg => 'упаковка', :f_pl => 'упаковок', :lite_sg => 'уп.', :is_integer => true},
6 => {:f_sg => 'порция', :f_pl => 'порций', :lite_sg => 'порция', :is_integer => true},
7 => {:f_sg => 'коробка', :f_pl => 'коробок', :lite_sg => 'кор.', :is_integer => true},
8 => {:f_sg => 'комплект', :f_pl => 'комплектов', :lite_sg => 'комплект', :is_integer => true}
}

DEFAULT_PRODUCT_MEASURE_INVISIBLE = 1

PRODUCT_COST_TYPE_WHOLE_LOT = 0
PRODUCT_COST_TYPE_PER_UNIT  = 1

CUSTOMER_TYPE_FIZ_LICO = 0
CUSTOMER_TYPE_LEGAL = 1

DELIVERY_CHARGES_AFTER_ORDER_AGREE              = 1
DELIVERY_CHARGES_TO_CUSTOMER_ORDER_NOT_INCLUDE  = 2

DELIVERY_COST_ADD_TO_PROD_PRICES = 0
DELIVERY_COST_ALONE_PRICE = 1

DELIVERY_METHOD_TO_TRANSPORT_COMPANY = 1
DELIVERY_METHOD_TO_SHOP = 2
DELIVERY_METHOD_TO_PICKPOINT = 3
DELIVERY_METHOD_TO_POST_OFFICE = 4

DELIVERY_METHODS = {
	DELIVERY_METHOD_TO_TRANSPORT_COMPANY => {:tid => "to_tk"},
	DELIVERY_METHOD_TO_SHOP => {:tid => "to_shop"},
	DELIVERY_METHOD_TO_PICKPOINT => {:tid => "to_pickpoint"},
	DELIVERY_METHOD_TO_POST_OFFICE => {:tid => "to_rupost"}
}


CANCEL_OREASON_SPONTANEOUS_NOT_NEEDED   = 1
CANCEL_OREASON_ERROR_ON_SELECT          = 2
CANCEL_OREASON_DUPLICATE                = 3
CANCEL_OREASON_NOT_NEED_ANYMORE         = 4
CANCEL_OREASON_INCREASED_PRICE          = 5
CANCEL_OREASON_FOUND_CHEAPER            = 6
CANCEL_OREASON_NOT_AVAILABLE            = 7
CANCEL_OREASON_NOT_SEND_ON_TIME         = 8
CANCEL_OREASON_SELLER_CANT_SHIP         = 9
CANCEL_OREASON_SELLER_DISAPPEARED       = 10
CANCEL_OREASON_INCORRECT_DESCRIPTION    = 11
CANCEL_OREASON_OTHER                    = 12


SEX_FEMALE = 1
SEX_MALE = 2

ORGANIZATION_TYPE_IND_PREDP = 1
ORGANIZATION_TYPE_FIZ_LICO  = 9
ORGANIZATION_TYPES = {
	9  => {:lite => "", :full => "Физическое лицо", :full_dn => "физическое лицо"},
	1  => {:lite => "ИП", :full => "Индивидуальный предприниматель", :full_dn => "индивидуальный предприниматель"},
	2  => {:lite => "ООО", :full => "Общество с ограниченной ответственностью", :full_dn => "общество с ограниченной ответственностью"},
	3  => {:lite => "АО", :full => "Акционерное общество", :full_dn => "акционерное общество"},
	4  => {:lite => "ПАО", :full => "Публичное акционерное общество", :full_dn => "публичное акционерное общество"},
	5  => {:lite => "МУП", :full => "Муниципальное унитарное предприятие", :full_dn => "муниципальное унитарное предприятие"},
	10 => {:lite => "МБУ", :full => "Муниципальное бюджетное учреждение", :full_dn => "муниципальное бюджетное учреждение"},
	11 => {:lite => "МКУ", :full => "Муниципальное казенное учреждение", :full_dn => "муниципальное казенное учреждение"},
	12 => {:lite => "МАУ", :full => "Муниципальное автономное учреждение", :full_dn => "муниципальное автономное учреждение"},
	14 => {:lite => "ФКП", :full => "Федеральное казенное предприятие", :full_dn => "федеральное казенное предприятие"}
	#8 => {:lite => "КФХ", :full => "Крестьянское (фермерское) хозяйство"}, #действуют как ИП
	#6 => "НАО",
	#7 => "ОАО"
}

ORGANIZATION_CHIEF_TYPES = {
	1 => {:title => "Директор", :genitive => "Директора"},
	2 => {:title => "Генеральный директор", :genitive => "Генерального директора"},
	3 => {:title => "Глава КФХ", :genitive => "Главы КФХ"}
}

ORGANIZATION_CHIEF_BASIS_TYPES = {
	1 => {:title => "Устава"},
	2 => {:title => "Свидетельства"},
	3 => {:title => "Доверенности"}
}

DOC_RELATIONSHIP_CUSTOMER  = 0
DOC_RELATIONSHIP_PARTNER   = 1

DOCS_LIST_DOCNAME_PAYMENT = 'pay'
DOCS_LIST_DOCNAME_RECALC  = 'recalc'

CURRENCY_CODE_NUM_RUB = 643
CURRENCY_CODE_NUM_USD = 840
CURRENCY_CODE_NUM_EUR = 978
CURRENCY_CODE_NUM_JPY = 392
CURRENCY_CODE_NUM_GBP = 826

COST_TEXT_CURRENCY_LITE  = 0 # руб. / USD
COST_TEXT_CURRENCY_SHORT = 1 # р. / USD
COST_TEXT_CURRENCY_SIGN  = 2 # P / $

TZ_UTC_OFFSET_MOSCOW  = 3

URL_ACCESS_ONLY_USER  = 1
URL_ACCESS_USERS      = 2
URL_ACCESS_ANYBODY    = 3

SID_URL_MAX_LENGTH    = 150 # Max length of SID in URL-string
SAFE_UID_MAX_LENGTH   = 50 # Max length of Safe UID string