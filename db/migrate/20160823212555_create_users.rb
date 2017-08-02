class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.timestamps null: false
	  t.string     "name",                      limit: 50
	  t.string     "lastname",                  limit: 50
      t.string     "middlename",                limit: 50
      t.string     "email",                                 default: "",    null: false
      t.string     "encrypted_password",                    default: "",    null: false
      t.integer    "sex",                       limit: 2
      t.date       "last_activity"
      t.string     "login_history",             limit: 255 # последние 3 захода - IP и устройства
      t.date       "password_date"
      t.boolean    "notsecurepsw" # пароль нужно сменить
      t.date       "join_date" # время первого входа, регистрации
      t.string     "timezone",                  limit: 4
      t.integer    "warnings",                  limit: 2,   default: 0,     null: false
      t.boolean    "b_banned_full",                         default: false, null: false
      t.boolean    "b_banned_write",                        default: false, null: false
      t.date       "ban_full_dateto"
      t.date       "ban_write_dateto"
      t.boolean    "b_premoderated",                        default: true,  null: false
      t.integer    "sign_in_count",                         default: 0,     null: false
      t.datetime   "current_sign_in_at"
      t.string     "current_sign_in_ip"
      t.datetime   "last_sign_in_at"
      t.string     "last_sign_in_ip"
      t.boolean    "b_send_portalnews",                     default: true,  null: false
      t.integer    "sent_mails_count",                      default: 0,     null: false
      t.integer    "sent_mails_viewed",                     default: 0,     null: false
      t.integer    "sent_mails_reacted",                    default: 0,     null: false
      t.string     "reset_password_token"
      t.datetime   "reset_password_sent_at"
      t.datetime   "remember_created_at"
      t.integer    "failed_attempts",                       default: 0,     null: false
      t.date       "locked_at"
      t.string     "unlock_token"
      t.datetime   "blocked_at"
      t.string     "invitation_token"
      t.datetime   "invitation_created_at"
      t.datetime   "invitation_sent_at"
      t.datetime   "invitation_accepted_at"
      t.integer    "invitation_limit"
      t.integer    "invited_by_id"
      t.string     "invited_by_type"
      t.integer    "invitations_count",                     default: 0
      t.integer    "roles_mask",                limit: 8,   default: 0,     null: false
      t.string     "unconfirmed_email"
      t.datetime   "confirmation_sent_at"
      t.string     "confirmation_token"
      t.datetime   "confirmed_at"
      t.string     "avatar_file_name"
      t.string     "avatar_content_type"
      t.integer    "avatar_file_size"
      t.datetime   "avatar_updated_at"
      t.boolean    "terms_of_use_agree_status"
      t.boolean    "created_by_oauth",                      default: false, null: false
      t.boolean    "b_allow_login_by_passw"
      t.boolean    "b_passw_rnd"
      t.jsonb      "customers_list" # Покупатели, которых представляет этот User. {customer_id1: {use_count: xx, last_usage: xxx_time}, customer_id2: {use_count: xx, last_usage: xxx_time}, ...}. Покупателя могут представлять множество Users.
      t.integer    "customer_default_id" # Покупатель по-умолчанию
    end
  end
end
