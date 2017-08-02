class CreateMetrikaItems < ActiveRecord::Migration
  def change
    create_table :metrika_items do |t|
      t.timestamps null: false
	  t.string   "metrika_log"
      t.string   "metrika_visit"
      t.integer  "obj_id"
      t.integer  "obj_type",      limit: 2
      t.integer  "city_id"
      t.string   "str_id",        limit: 20
    end
  end
end
