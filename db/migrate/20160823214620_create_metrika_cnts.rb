class CreateMetrikaCnts < ActiveRecord::Migration
  def change
    create_table :metrika_cnts do |t|
      t.timestamps null: false
	  t.string   "metrika_cnt_archive"
      t.string   "metrika_cnt_story"
      t.string   "metrika_item"
      t.string   "metrika_log"
      t.string   "metrika_visit"
      t.integer  "total_visits",         default: 0,       null: false
      t.integer  "total_from_se",        default: 0
      t.integer  "total_from_se_ya",     default: 0
      t.integer  "total_from_se_gg",     default: 0
      t.date     "today_date",           default: "now()", null: false
      t.integer  "today_total",          default: 0,       null: false
      t.integer  "today_unique",         default: 0,       null: false
      t.integer  "today_from_se",        default: 0
      t.integer  "month_from_se",        default: 0
    end
  end
end
