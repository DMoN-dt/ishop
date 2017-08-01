
if(Rails.env.production? || Rails.env.staging?)
	SITE_PATH_ADDRESS='загруз.рф'
	SITE_PATH_ADDRESS_ROOT_CANONICAL='//загруз.рф'
	SITE_PATH_ADDRESS_WITH_PROTOCOL='http://загруз.рф'
	SITE_PATH_ADDRESS_WITH_SSL_PROTOCOL='https://загруз.рф'
	ENABLE_METRIKA = true
else
	SITE_PATH_ADDRESS='ishop.vmtest.lan'
	SITE_PATH_ADDRESS_ROOT_CANONICAL='//ishop.vmtest.lan'
	SITE_PATH_ADDRESS_WITH_PROTOCOL='http://ishop.vmtest.lan'
	SITE_PATH_ADDRESS_WITH_SSL_PROTOCOL='http://ishop.vmtest.lan'
	ENABLE_METRIKA = false
end

SITE_EMAIL_DOMAIN = 'zagruz-nt.ru'
SITE_EMAIL_SUPPORT_TEAM = 'support@zagruz-nt.ru'

SAFE_UID_PAYDOCUMENT_SHOP_ID = 'MPT' # Shop ID for Documents

MARKETPLACE_MODE_ONLINE_SHOP = true

NEW_ORDER_EXPRESS_MODE_ENABLED = true
NEW_ORDER_EXPRESS_MODE_PRICE_INC_PERCENT = 10 #percents of products cost
NEW_ORDER_EXPRESS_MODE_PRICE_INC_MAXSUMM = 5000 #rubles

NEW_ORDER_RESERVE_PRODUCTS_TIME_ON_AGREE = 4.days # время бронирования товара на период ожидания оплаты заказа

NO_CONFIRMATION_GRACE_PERIOD = 2.days # период, когда действует не подтверждённый аккаунт (email)
NO_CONFIRMATION_GRACE_POSTS_LIMIT = 3
NO_CONFIRMATION_SKIP_TIME_SHIFT = 20.seconds

## =================================================================

PRODUCT_IMAGE_MAX_FILE_COUNT = 5
PRODUCT_IMAGE_UPLOAD_MAX_FILE_SIZE = 500.kilobytes

AVATAR_UPLOAD_MAX_FILE_SIZE = 170.kilobytes #20.kilobytes

OBJECT_PHOTOS_MAX_NUMBER = 5
OBJECT_PHOTO_UPLOAD_MAX_FILE_SIZE = 500.kilobytes

COMMENTS_PHOTOS_MAX_NUMBER = 5
COMMENTS_PHOTO_UPLOAD_MAX_FILE_SIZE = 2.megabytes

OBJECT_NAME_MAX_LENGTH = 50
OBJECT_NAME_MAX_LENGTH_TILL = 49
OBJECT_URL_NAME_MAX_LENGTH = 30
OBJECT_EMAIL_MAX_LENGTH = 40


# DOCUMENT_TYPES are in site_secrets.rb