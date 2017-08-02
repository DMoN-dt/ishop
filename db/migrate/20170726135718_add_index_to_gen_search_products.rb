class AddIndexToGenSearchProducts < ActiveRecord::Migration[5.1]
  def up
	connection.execute(%q{CREATE INDEX gsp_ts_gin_idx ON gen_search_products USING GIN (ts_vector);})
  end
  
  def down
	connection.execute(%q{DROP INDEX IF EXISTS gsp_ts_gin_idx})
  end
end
