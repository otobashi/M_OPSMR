ALTER PROCEDURE [dbo].[m_opsmr_sp_subsidiary_rate]
(
  @opsmr_type      VARCHAR(5)
 ,@base_yyyymm     VARCHAR(6)
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_subsidiary_rate
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_subsidiary_rate

--   EXEC m_opsmr_sp_subsidiary_rate @opsmr_type, @base_yyyymm

4. 관 련 화 면 :

버전    작 성 자     일        자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.14  최초작성
1.1   shlee      2016.04.15  KPI_TYPE 엑셀개발자 요청에 의해 추가
***************************************************************************/

DECLARE @vc_pre_13          AS VARCHAR(6);
DECLARE @vc_start_yyyymm    AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13           = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전13월
SET @vc_start_yyyymm     = SUBSTRING(@base_yyyymm,1,4)+'01';    -- 누적년시작월 @vc_start_yyyymm

BEGIN

-- 월별가동률
SELECT '02.월별가동률' AS kpi_type
      ,sub.display_name AS sub
      ,prod.display_name AS prod
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,kpi_period_code AS kpi
      ,CASE WHEN SUM(production_capa) = 0 THEN 0
            ELSE SUM(production_quantity) / SUM(production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.use_flag = 'Y'
AND    prod.use_flag = 'Y'
AND    a.kpi_period_code NOT LIKE '%TOT%'
GROUP BY sub.display_name
        ,prod.display_name
        ,kpi_period_code
UNION ALL
-- 년별가동률
--SELECT '02.년별가동률' AS kpi_type
SELECT '02.월별가동률' AS kpi_type
      ,sub.display_name AS sub
      ,prod.display_name AS prod
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,SUBSTRING(kpi_period_code,1,4)+'TOT' AS kpi
      ,CASE WHEN SUM(production_capa) = 0 THEN 0
            ELSE SUM(production_quantity) / SUM(production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.use_flag = 'Y'
AND    prod.use_flag = 'Y'
AND    a.kpi_period_code NOT LIKE '%TOT%'
GROUP BY sub.display_name
        ,prod.display_name
        ,SUBSTRING(kpi_period_code,1,4)
UNION ALL
-- 전년대비
SELECT '03.전년대비' AS kpi_type
      ,a.sub
      ,a.prod
      ,MIN(a.sub_enm ) as sub_enm 
      ,MIN(a.sub_knm ) as sub_knm 
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
      ,'전년대비' AS kpi
      ,ROUND(SUM(a.val1),2) - ROUND(SUM(a.val2),2) AS val
FROM (      
      SELECT sub.display_name AS sub
            ,prod.display_name AS prod
            ,MIN(sub.display_enm) as sub_enm
            ,MIN(sub.display_knm) as sub_knm
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
            ,CASE WHEN SUM(production_capa) = 0 THEN 0
                  ELSE SUM(production_quantity) / SUM(production_capa) END AS val1
            ,0 AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  opsmr_type = @opsmr_type
      AND    kpi_period_code = @base_yyyymm
      AND    a.factory_region1 = sub.mapping_code
      AND    a.gbu_code = prod.mapping_code
      AND    sub.use_flag = 'Y'
      AND    prod.use_flag = 'Y'
      AND    a.kpi_period_code NOT LIKE '%TOT%'
      GROUP BY sub.display_name
              ,prod.display_name
      UNION ALL
      SELECT sub.display_name AS sub
            ,prod.display_name AS prod
            ,MIN(sub.display_enm) as sub_enm
            ,MIN(sub.display_knm) as sub_knm
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
            ,0 AS val1
            ,CASE WHEN SUM(production_capa) = 0 THEN 0
                  ELSE SUM(production_quantity) / SUM(production_capa) END AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  opsmr_type = @opsmr_type
      AND    kpi_period_code = @vc_pre_13
      AND    a.factory_region1 = sub.mapping_code
      AND    a.gbu_code = prod.mapping_code
      AND    sub.use_flag = 'Y'
      AND    prod.use_flag = 'Y'
      AND    a.kpi_period_code NOT LIKE '%TOT%'
      GROUP BY sub.display_name
              ,prod.display_name
     ) a
GROUP BY a.sub
      ,a.prod
UNION ALL
SELECT '01.생산비중' AS kpi_type
      ,a.sub
      ,a.prod
      ,min(a.sub_enm ) AS sub_enm  
      ,min(a.sub_knm ) AS sub_knm  
      ,min(a.prod_enm) AS prod_enm 
      ,min(a.prod_knm) AS prod_knm 
  	  ,'생산비중' AS kpi
  	  ,CASE WHEN SUM(b.qty) = 0 THEN 0
  	        ELSE SUM(a.qty) / SUM(b.qty) END AS val
FROM (SELECT sub.display_name AS sub
            ,prod.display_name AS prod
            ,MIN(sub.display_enm) as sub_enm
            ,MIN(sub.display_knm) as sub_knm
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
            ,SUM(production_quantity) AS qty
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  opsmr_type = @opsmr_type
      AND    a.factory_region1 = sub.mapping_code
      AND    a.gbu_code = prod.mapping_code
      AND    sub.use_flag = 'Y'
      AND    prod.use_flag = 'Y'
      AND    a.kpi_period_code NOT LIKE '%TOT%'
      AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
      GROUP BY sub.display_name
              ,prod.display_name
      ) a
    ,(SELECT prod.display_name AS prod
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
            ,SUM(production_quantity) AS qty
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  a.opsmr_type = @opsmr_type
      AND    a.base_yyyymm = @base_yyyymm
      AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
      AND    a.gbu_code = prod.mapping_code
      AND    prod.use_flag = 'Y'
      AND    a.kpi_period_code NOT LIKE '%TOT%'
      GROUP BY prod.display_name
      ) b
WHERE  a.prod = b.prod
GROUP BY a.sub
      ,a.prod
;



END