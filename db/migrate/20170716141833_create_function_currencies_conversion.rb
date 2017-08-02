class CreateFunctionCurrenciesConversion < ActiveRecord::Migration[5.1]
  def up
	connection.execute(%q{
	CREATE OR REPLACE FUNCTION get_currency_conversion_ratio(IN from_iso_id integer, IN to_iso_id integer, IN seller_id bigint)
	RETURNS double precision
    AS
	'
	WITH c_conv (ratio, from_cn, force_reverse, def_ratio) AS (
	SELECT 
	CASE WHEN (scc.use_seller_ratio AND (scc.ratio IS NOT NULL)) THEN
	scc.ratio
	ELSE
	CASE WHEN scc.use_ratio_live AND (gcc.ratio_live IS NOT NULL) AND (gcc.ratio_live_at IS NOT NULL) AND (
	((EXTRACT(MINUTE FROM (CURRENT_TIMESTAMP - gcc.ratio_live_at)) <= 10) AND ((gcc.ratio_cb_cur IS NULL) OR ((ABS(gcc.ratio_live - gcc.ratio_cb_cur) / gcc.ratio_cb_cur) <= 0.02)))
	OR
	((EXTRACT(MINUTE FROM (CURRENT_TIMESTAMP - gcc.ratio_live_at)) <= 20) AND ((gcc.ratio_cb_cur IS NULL) OR ((ABS(gcc.ratio_live - gcc.ratio_cb_cur) / gcc.ratio_cb_cur) <= 0.01)))
	) THEN
	gcc.ratio_live
	ELSE
	CASE WHEN (scc.use_ratio_cb IS FALSE) THEN
		CASE WHEN scc.use_ratio_live AND (gcc.ratio_live IS NOT NULL) AND (gcc.ratio_live_at IS NOT NULL) THEN
		CASE WHEN scc.use_seller_ratio_on_old_data THEN scc.ratio ELSE gcc.ratio_live END
		ELSE
		NULL
		END
	ELSE
		CASE WHEN (gcc.ratio_cb_next IS NOT NULL) AND (gcc.ratio_cb_next_since IS NOT NULL) AND (gcc.ratio_cb_next_since <= CURRENT_TIMESTAMP) AND ((gcc.ratio_cb_cur_at IS NULL) OR (gcc.ratio_cb_cur IS NULL) OR (gcc.ratio_cb_cur_at < gcc.ratio_cb_next_since)) THEN
		CASE WHEN scc.use_seller_ratio_on_old_data AND (EXTRACT(DAY FROM (CURRENT_TIMESTAMP - gcc.ratio_cb_next_since)) > 3) THEN scc.ratio ELSE gcc.ratio_cb_next END
		ELSE
		CASE WHEN (gcc.ratio_cb_cur IS NULL) THEN NULL  WHEN (scc.use_seller_ratio_on_old_data AND ((gcc.ratio_cb_cur_at IS NULL) OR (EXTRACT(DAY FROM (CURRENT_TIMESTAMP - gcc.ratio_cb_cur_at)) > 3))) THEN scc.ratio ELSE gcc.ratio_cb_cur END
		END
	END
	END
	END AS ratio, gcc.from_cn_iso_id, (scc.force_use_reverse_ratio IS TRUE) AND (scc.use_seller_ratio IS NOT TRUE), scc.ratio
	FROM gen_currency_conversions AS gcc
	FULL OUTER JOIN seller_currency_conversions AS scc ON ((scc.seller_id = $3) AND (scc.from_cn_iso_id = gcc.from_cn_iso_id) AND (scc.to_cn_iso_id = gcc.to_cn_iso_id))
	WHERE ((gcc.from_cn_iso_id = $1) AND (gcc.to_cn_iso_id = $2)) OR ((gcc.from_cn_iso_id = $2) AND (gcc.to_cn_iso_id = $1))
	),
	c_conv_norm AS (SELECT ratio, force_reverse, def_ratio FROM c_conv WHERE from_cn = $1),
	c_conv_rev  AS (SELECT (CASE WHEN (ratio != 0) THEN 1/ratio ELSE NULL END) AS ratio, force_reverse, (CASE WHEN (def_ratio != 0) THEN 1/def_ratio ELSE NULL END) AS def_ratio FROM c_conv WHERE from_cn = $2)
	
	SELECT CASE WHEN c_norm.force_reverse THEN (SELECT COALESCE(crev.ratio, c_norm.ratio, crev.def_ratio, c_norm.def_ratio) FROM c_conv_rev crev FULL OUTER JOIN c_conv_norm c_norm ON true)
	ELSE (SELECT COALESCE(c_norm.ratio, crev.ratio, c_norm.def_ratio, crev.def_ratio) FROM c_conv_rev crev FULL OUTER JOIN c_conv_norm c_norm ON true) END AS ratio FROM c_conv_norm c_norm
	'
	
	LANGUAGE sql
	})
  end
  
  def down
	connection.execute(%q{
    DROP FUNCTION IF EXISTS get_currency_conversion_ratio (from_iso_id integer, to_iso_id integer, seller_id bigint);
	})
  end
end
