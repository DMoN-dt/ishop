class CreateFunctionTsProductsMakeTextB < ActiveRecord::Migration[5.1]
  def up
	connection.execute(%q{
	CREATE OR REPLACE FUNCTION ts_products_make_text_b(IN arg_sprod_id bigint, IN arg_seller_brand_id bigint, IN arg_global_brand_id bigint)
	RETURNS void LANGUAGE plpgsql
    AS $$
		BEGIN

		WITH RECURSIVE w_seller_model(id, main_model_id, path, pnames, cycle) AS (
  SELECT sbm_r.id, sbm_r.main_model_id, ARRAY[sbm_r.id], 
   CASE WHEN (sbm_r.name != gbm.name) THEN (ARRAY[sbm_r.name] || ARRAY[gbm.name]) ELSE ARRAY[COALESCE(sbm_r.name, gbm.name)] END || (
    CASE WHEN (COALESCE(sbm_r.model_year_first, gbm.model_year_first) IS NOT NULL) OR (COALESCE(sbm_r.model_year_last, gbm.model_year_last) IS NOT NULL) THEN
      ARRAY[COALESCE(sbm_r.model_year_first, gbm.model_year_first, 0) || ' - ' || COALESCE(sbm_r.model_year_last, gbm.model_year_last, 0)]::character varying[]
    ELSE ARRAY[]::character varying[] END
   )
   , false
  FROM seller_brand_models AS sbm_r
  LEFT OUTER JOIN gen_brand_models AS gbm ON (gbm.id = sbm_r.global_model_id)
  WHERE (sbm_r.seller_id = 0) AND (sbm_r.main_model_id = 0)
    UNION ALL
  SELECT sbm_r.id, sbm_r.main_model_id, path || sbm_r.id, CASE WHEN (pnames <@ ARRAY[sbm_r.name]) THEN pnames ELSE pnames || sbm_r.name END , sbm_r.id = ANY(path)
  FROM w_seller_model ctree
  JOIN seller_brand_models AS sbm_r ON (sbm_r.main_model_id = ctree.id)
  WHERE (sbm_r.seller_id = 0) AND (sbm_r.main_model_id != 0) AND (NOT cycle)
)
		UPDATE gen_search_products AS tsp SET updated_at = CURRENT_TIMESTAMP AT TIME ZONE 'UTC', text_rank_b = (
COALESCE(sbd.name || ' ','') || COALESCE(gbd.name || ' ','') ||
CASE WHEN (sp.prod_info IS NOT NULL) THEN 
  COALESCE(sp.prod_info->>'appfor' || ' ','') || COALESCE(sp.prod_info->>'pvars' || ' ','') ELSE ''
END || array_to_string((SELECT array(
 SELECT COALESCE(gbd.name || ' ','') || COALESCE(sbr.name || ' ','') || array_to_string(array_remove(wsm.pnames, NULL), ' ')
 FROM seller_brand_models AS sbm
 LEFT OUTER JOIN w_seller_model AS wsm ON (wsm.id = sbm.id)
 LEFT OUTER JOIN seller_brands AS sbr ON (sbr.id = sbm.brand_id) AND (sbr.seller_id = sbm.seller_id)
 LEFT OUTER JOIN gen_brands AS gbd ON (gbd.id = sbr.global_brand_id)
 WHERE sbm.id = ANY((('{' || trim(both '[]{}' from sp.prod_info->>'formodel') || '}')::int[])) AND ((sbm.name IS NOT NULL) OR (sbr.name IS NOT NULL) OR (gbd.name IS NOT NULL))
)), ''))
		FROM gen_search_products AS tsp2
INNER JOIN seller_products AS sp ON (sp.id = tsp2.seller_prod_id)
LEFT OUTER JOIN seller_brands AS sbd ON (sbd.id = sp.seller_brand_id)
LEFT OUTER JOIN gen_brands AS gbd ON (gbd.id = sbd.global_brand_id)
WHERE  (((arg_sprod_id IS NOT NULL) AND (tsp2.seller_prod_id = arg_sprod_id)) OR ((arg_seller_brand_id IS NOT NULL) AND (sbd.id = arg_seller_brand_id)) OR ((arg_global_brand_id IS NOT NULL) AND (gbd.id = arg_global_brand_id)))
AND (tsp2.id = tsp.id);



			WITH RECURSIVE w_seller_model(id, main_model_id, path, pnames, cycle) AS (
  SELECT sbm_r.id, sbm_r.main_model_id, ARRAY[sbm_r.id], 
   CASE WHEN (sbm_r.name != gbm.name) THEN (ARRAY[sbm_r.name] || ARRAY[gbm.name]) ELSE ARRAY[COALESCE(sbm_r.name, gbm.name)] END || (
    CASE WHEN (COALESCE(sbm_r.model_year_first, gbm.model_year_first) IS NOT NULL) OR (COALESCE(sbm_r.model_year_last, gbm.model_year_last) IS NOT NULL) THEN
      ARRAY[COALESCE(sbm_r.model_year_first, gbm.model_year_first, 0) || ' - ' || COALESCE(sbm_r.model_year_last, gbm.model_year_last, 0)]::character varying[]
    ELSE ARRAY[]::character varying[] END
   )
   , false
  FROM seller_brand_models AS sbm_r
  LEFT OUTER JOIN gen_brand_models AS gbm ON (gbm.id = sbm_r.global_model_id)
  WHERE (sbm_r.seller_id = 0) AND (sbm_r.main_model_id = 0)
    UNION ALL
  SELECT sbm_r.id, sbm_r.main_model_id, path || sbm_r.id, CASE WHEN (pnames <@ ARRAY[sbm_r.name]) THEN pnames ELSE pnames || sbm_r.name END , sbm_r.id = ANY(path)
  FROM w_seller_model ctree
  JOIN seller_brand_models AS sbm_r ON (sbm_r.main_model_id = ctree.id)
  WHERE (sbm_r.seller_id = 0) AND (sbm_r.main_model_id != 0) AND (NOT cycle)
)
			INSERT INTO gen_search_products AS tsp (created_at, updated_at, seller_prod_id, text_rank_b)  
			(SELECT CURRENT_TIMESTAMP AT TIME ZONE 'UTC', CURRENT_TIMESTAMP AT TIME ZONE 'UTC', sp.id, (
COALESCE(sbd.name || ' ','') || COALESCE(gbd.name || ' ','') ||
CASE WHEN (sp.prod_info IS NOT NULL) THEN 
  COALESCE(sp.prod_info->>'appfor' || ' ','') || COALESCE(sp.prod_info->>'pvars' || ' ','') ELSE ''
END || array_to_string((SELECT array(
 SELECT COALESCE(gbd.name || ' ','') || COALESCE(sbr.name || ' ','') || array_to_string(array_remove(wsm.pnames, NULL), ' ')
 FROM seller_brand_models AS sbm
 LEFT OUTER JOIN w_seller_model AS wsm ON (wsm.id = sbm.id)
 LEFT OUTER JOIN seller_brands AS sbr ON (sbr.id = sbm.brand_id) AND (sbr.seller_id = sbm.seller_id)
 LEFT OUTER JOIN gen_brands AS gbd ON (gbd.id = sbr.global_brand_id)
 WHERE sbm.id = ANY((('{' || trim(both '[]{}' from sp.prod_info->>'formodel') || '}')::int[])) AND ((sbm.name IS NOT NULL) OR (sbr.name IS NOT NULL) OR (gbd.name IS NOT NULL))
)), ''))
			FROM seller_products AS sp
LEFT OUTER JOIN seller_brands AS sbd ON (sbd.id = sp.seller_brand_id)
LEFT OUTER JOIN gen_brands AS gbd ON (gbd.id = sbd.global_brand_id)
WHERE  (((arg_sprod_id IS NOT NULL) AND (sp.id = arg_sprod_id)) OR ((arg_seller_brand_id IS NOT NULL) AND (sbd.id = arg_seller_brand_id)) OR ((arg_global_brand_id IS NOT NULL) AND (gbd.id = arg_global_brand_id)))
AND NOT EXISTS(SELECT id FROM gen_search_products WHERE seller_prod_id = sp.id LIMIT 1)
);
		
		return;

		END
		$$;
	})
  end
  
  def down
	connection.execute(%q{
    DROP FUNCTION ts_products_make_text_b(bigint, bigint, bigint);
	})
  end
end
