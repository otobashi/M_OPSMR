SELECT a.sub
      ,a.prod
      ,a.sub_enm
      ,a.sub_knm
      ,a.prod_enm
      ,a.prod_knm
      ,a.pre_rate
      ,a.cur_rate
      ,a.post_rate
      ,a.pre_rate_gap
      ,a.post_rate_gap
      ,a.abs_pre_rate_gap
      ,a.abs_post_rate_gap
      ,a.pre_qty
      ,a.cur_qty
      ,a.post_qty
      ,a.pre_qty_gap
      ,a.post_qty_gap
      ,a.abs_pre_qty_gap
      ,a.abs_post_qty_gap
      ,a.rate_mon13
      ,a.qty_mon13
      ,a.qty_rate_mon13
      ,CASE WHEN a.post_rate_gap >= 0 THEN 1
            ELSE -1 END AS signal 
FROM  ( SELECT sub.display_name AS sub
              ,prod.display_name AS prod
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,MIN(prod.display_enm) as prod_enm
              ,MIN(prod.display_knm) as prod_knm
              ,isnull(sum(case when kpi_period_code = '201602' and scenario_type_code = 'AC0' then standard_operation_rate end),0) * 100 as pre_rate
              ,isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then standard_operation_rate end),0) * 100 as cur_rate
              ,isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'PR1' then standard_operation_rate end),0) * 100 as post_rate
              ,(isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then standard_operation_rate end),0) * 100) - (isnull(sum(case when kpi_period_code = '201602' and scenario_type_code = 'AC0' then standard_operation_rate end),0) * 100) AS pre_rate_gap
              ,(isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'PR1' then standard_operation_rate end),0) * 100) - (isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then standard_operation_rate end),0) * 100) AS post_rate_gap
              ,abs((isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then standard_operation_rate end),0) * 100) - (isnull(sum(case when kpi_period_code = '201602' and scenario_type_code = 'AC0' then standard_operation_rate end),0) * 100)) AS abs_pre_rate_gap
              ,abs((isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'PR1' then standard_operation_rate end),0) * 100) - (isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then standard_operation_rate end),0) * 100)) AS abs_post_rate_gap
              ,isnull(sum(case when kpi_period_code = '201602' and scenario_type_code = 'AC0' then production_quantity end),0) as pre_qty
              ,isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then production_quantity end),0) as cur_qty
              ,isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'PR1' then production_quantity end),0) as post_qty
              ,(isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then production_quantity end),0)) - (isnull(sum(case when kpi_period_code = '201602' and scenario_type_code = 'AC0' then production_quantity end),0)) AS pre_qty_gap
              ,(isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'PR1' then production_quantity end),0)) - (isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then production_quantity end),0)) AS post_qty_gap
              ,abs((isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then production_quantity end),0)) - (isnull(sum(case when kpi_period_code = '201602' and scenario_type_code = 'AC0' then production_quantity end),0))) AS abs_pre_qty_gap
              ,abs((isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'PR1' then production_quantity end),0)) - (isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then production_quantity end),0))) AS abs_post_qty_gap
              ,case when isnull(sum(case when kpi_period_code between '201503' and '201603' then production_capa end),0) = 0 then 0
                    else isnull(sum(case when kpi_period_code between '201503' and '201603' then production_quantity end),0) / isnull(sum(case when kpi_period_code between '201503' and '201603' then production_capa end),0) end AS rate_mon13
                ,isnull(sum(case when kpi_period_code between '201503' and '201603' then production_quantity end),0) AS qty_mon13
              ,case when isnull(sum(case when kpi_period_code between '201503' and '201603' then production_quantity end),0) = 0 then 0
                    else isnull(sum(case when kpi_period_code = '201603' and scenario_type_code = 'AC0' then production_quantity end),0) / isnull(sum(case when kpi_period_code between '201503' and '201603' then production_quantity end),0) end AS qty_rate_mon13
        FROM   m_opsmr_tb_op_rate(nolock) a
              ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
        WHERE  a.opsmr_type = 'STD'
        AND    a.base_yyyymm = '201603'
        AND    a.kpi_period_code between '201503' and '201604'
        AND    a.factory_region1 = sub.mapping_code
        AND    a.gbu_code = prod.mapping_code
        AND    sub.use_flag = 'Y'
        AND    prod.use_flag = 'Y'
        GROUP BY sub.display_name
                ,prod.display_name
      ) a
where  a.cur_rate  < (85/100)
and    a.post_rate < (85/100)
and    a.abs_post_rate_gap >= 10
;