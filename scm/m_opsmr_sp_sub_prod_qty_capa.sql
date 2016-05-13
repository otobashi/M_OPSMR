ALTER PROCEDURE [dbo].[m_opsmr_sp_sub_prod_qty_capa]
(
  @opsmr_type    VARCHAR(5)
 ,@start_yyyymm  VARCHAR(6)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_sub_prod_qty_capa
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_sub_prod_qty_capa

--   EXEC m_opsmr_sp_sub_prod_qty_capa 'STD', '201602', '201602'  -- 기준가동율
--   EXEC m_opsmr_sp_sub_prod_qty_capa 'PROD', '201602', '201602' -- 운영가동율

4. 관 련 화 면 :

버전  작 성 자   일      자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.05  최초작성
1.1   shlee      2016.04.20  날짜조정
1.2   shlee      2016.04.20  당월/2.차월 날짜조정
***************************************************************************/

DECLARE @vc_pre_13      AS VARCHAR(6);
DECLARE @vc_pre_yyyy    AS VARCHAR(4);
DECLARE @vc_pre_py_yyyy AS VARCHAR(4);

DECLARE @vc_pre_yyyymm  AS VARCHAR(4);
DECLARE @vc_pre_yyyy13  AS VARCHAR(4);

DECLARE @vc_pre_1       AS VARCHAR(6);
DECLARE @vc_post_1      AS VARCHAR(6);
DECLARE @vc_post_3      AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13      = CONVERT(VARCHAR(6), DATEADD(m, -12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직전13개월전
SET @vc_pre_yyyy    = CONVERT(VARCHAR(4), DATEADD(yy, -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전년
SET @vc_pre_py_yyyy = CONVERT(VARCHAR(4), DATEADD(yy, -2, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전전년
SET @vc_pre_yyyymm  = CONVERT(VARCHAR(4), DATEADD(yy, -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112) + SUBSTRING(@base_yyyymm,5,2);    -- 전년
SET @vc_pre_yyyy13  = CONVERT(VARCHAR(6), DATEADD(m, -12, CONVERT(DATETIME,CONVERT(VARCHAR(4), DATEADD(yy,  -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112) + SUBSTRING(@base_yyyymm,5,2) + '01')), 112);  -- 전년

SET @vc_pre_1       = CONVERT(VARCHAR(6), DATEADD(m,  -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직전1개월
SET @vc_post_1      = CONVERT(VARCHAR(6), DATEADD(m,   1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직후1개월
SET @vc_post_3      = CONVERT(VARCHAR(6), DATEADD(m,   3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직후3개월

BEGIN

SELECT *
FROM   (
-- 01.기준CAPA
SELECT '01.기준CAPA' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,a.kpi_period_code
      ,SUM(a.production_capa) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet04_yn = 'Y'
AND    prod.sheet04_yn = 'Y'
GROUP BY prod.display_name
        ,sub.display_name
        ,kpi_period_code
UNION ALL
-- 02.생산수량
SELECT '02.생산수량' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,a.kpi_period_code
      ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet04_yn = 'Y'
AND    prod.sheet04_yn = 'Y'
GROUP BY prod.display_name
        ,sub.display_name
        ,a.kpi_period_code
UNION ALL
-- 03.가동율
SELECT '03.가동율' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,a.kpi_period_code
      ,SUM(a.standard_operation_rate) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet04_yn = 'Y'
AND    prod.sheet04_yn = 'Y'
GROUP BY prod.display_name
        ,sub.display_name
        ,a.kpi_period_code
UNION ALL
-- 04.가동율요약
SELECT '04.가동율요약' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.당월누적' AS kpi_period_code
      ,CASE WHEN SUM(b.val) = 0 THEN 0
            ELSE SUM(a.val) / SUM(b.val) END AS val
FROM  (SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name) A
       LEFT JOIN
      (SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_capa) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name) B
       ON  a.prod = b.prod
       AND a.sub  = b.sub
GROUP BY a.prod
        ,a.sub

UNION ALL
-- 04.가동율요약
SELECT '04.가동율요약' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'2.차월누적' AS kpi_period_code
      ,CASE WHEN SUM(b.val) = 0 THEN 0
            ELSE SUM(a.val) / SUM(b.val) END AS val
FROM  (SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @vc_post_1
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name) A
       LEFT JOIN
      (SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_capa) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @vc_post_1
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name) B
       ON  a.prod = b.prod
       AND a.sub  = b.sub
GROUP BY a.prod
        ,a.sub

UNION ALL
-- 04.가동율요약
SELECT '04.가동율요약' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'직전13개월' AS kpi_period_code
      ,CASE WHEN SUM(b.val) = 0 THEN 0
            ELSE SUM(a.val) / SUM(b.val) END AS val
FROM  (SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name) A
       LEFT JOIN
      (SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_capa) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name) B
       ON  a.prod = b.prod
       AND a.sub  = b.sub
GROUP BY a.prod
        ,a.sub

UNION ALL
-- 05.생산수량
SELECT '05.생산수량' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'1.당월누적' AS kpi_period_code
      ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type  = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet04_yn = 'Y'
AND    prod.sheet04_yn = 'Y'
GROUP BY prod.display_name
        ,sub.display_name

UNION ALL
-- 05.생산수량
SELECT '05.생산수량' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'2.차월누적' AS kpi_period_code
      ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type  = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @vc_post_1
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet04_yn = 'Y'
AND    prod.sheet04_yn = 'Y'
GROUP BY prod.display_name
        ,sub.display_name

UNION ALL
-- 05.생산수량
SELECT '05.생산수량' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'직전13개월' AS kpi_period_code
      ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type  = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet04_yn = 'Y'
AND    prod.sheet04_yn = 'Y'
GROUP BY prod.display_name
        ,sub.display_name

UNION ALL
-- 06.기준CAPA
SELECT '06.기준CAPA' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'1.당월누적' AS kpi_period_code
      ,SUM(a.production_capa) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type  = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet04_yn = 'Y'
AND    prod.sheet04_yn = 'Y'
GROUP BY prod.display_name
        ,sub.display_name

UNION ALL
-- 06.기준CAPA
SELECT '06.기준CAPA' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'2.차월누적' AS kpi_period_code
      ,SUM(a.production_capa) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type  = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @vc_post_1
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet04_yn = 'Y'
AND    prod.sheet04_yn = 'Y'
GROUP BY prod.display_name
        ,sub.display_name

UNION ALL
-- 06.기준CAPA
SELECT '06.기준CAPA' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'직전13개월' AS kpi_period_code
      ,SUM(a.production_capa) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type  = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet04_yn = 'Y'
AND    prod.sheet04_yn = 'Y'
GROUP BY prod.display_name
        ,sub.display_name

UNION ALL
-- 07.전년대비수량
SELECT '07.전년대비수량' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.당월누적' AS kpi_period_code
      ,SUM(a.val) - SUM(b.val) AS val
FROM ( SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name ) A
      LEFT JOIN
     ( SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_yyyy+'01' AND @vc_pre_yyyy+substring(@base_yyyymm,5,2)
--       AND    a.scenario_type_code = 'AC0'
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name) B
      ON  a.prod = b.prod
      AND a.sub  = b.sub
GROUP BY a.prod
        ,a.sub

UNION ALL
-- 07.전년대비수량
SELECT '07.전년대비수량' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'2.차월누적' AS kpi_period_code
      ,SUM(a.val) - SUM(b.val) AS val
FROM ( SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @vc_post_1
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name ) A
       LEFT JOIN
     ( SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_yyyy+'01' AND @vc_pre_yyyy+substring(@vc_post_1,5,2)
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name) B
      ON  a.prod = b.prod
      AND a.sub  = b.sub
GROUP BY a.prod
        ,a.sub

UNION ALL
-- 07.전년대비수량
SELECT '07.전년대비수량' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'직전13개월' AS kpi_period_code
      ,SUM(a.val) - SUM(b.val) AS val
FROM ( SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name) A
       LEFT JOIN
     ( SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type  = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_py_yyyy+substring(@vc_pre_13,5,2) AND @vc_pre_13
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name ) B
      ON  a.prod = b.prod
      AND a.sub  = b.sub
GROUP BY a.prod
        ,a.sub

UNION ALL
-- 08.생산비중
SELECT '08.생산비중' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.당월누적' AS kpi_period_code
      ,CASE WHEN SUM(b.qty) = 0 THEN 0
          ELSE SUM(a.qty)/SUM(b.qty) END AS val
FROM ( SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) as qty
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name
      ) A
      LEFT JOIN
     ( SELECT prod.display_name AS prod
             ,SUM(a.production_quantity) as qty
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
      ) B
       ON A.prod = B.prod
GROUP BY a.prod
        ,a.sub

UNION ALL
-- 09.제품TOTAL
SELECT '09.제품TOTAL' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.당월누적' AS kpi_period_code
      ,SUM(b.qty) AS val
FROM ( SELECT prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) as qty
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name
      ) A
      LEFT JOIN
     ( SELECT prod.display_name AS prod
             ,SUM(a.production_quantity) as qty
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
      ) B
      ON A.prod = B.prod
GROUP BY a.prod
        ,a.sub

UNION ALL
-- 10.변동율
SELECT '10.변동율' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.당월변동' AS kpi_period_code
      ,SUM(a.val) - SUM(b.val) AS val
FROM  (
       SELECT '03.가동율' AS cat_cd
             ,prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,a.kpi_period_code
             ,SUM(a.standard_operation_rate) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name
               ,a.kpi_period_code ) a
     ,(
       SELECT '03.가동율' AS cat_cd
             ,prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,a.kpi_period_code
             ,SUM(a.standard_operation_rate) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @vc_pre_1
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name
               ,a.kpi_period_code ) b               
WHERE  a.prod = b.prod  
AND    a.sub  = b.sub
GROUP BY a.prod
        ,a.sub
UNION ALL
SELECT '10.변동율' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'2.차월변동' AS kpi_period_code
      ,SUM(b.val) - SUM(a.val) AS val
FROM  (
       SELECT '03.가동율' AS cat_cd
             ,prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,a.kpi_period_code
             ,SUM(a.standard_operation_rate) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @base_yyyymm
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name
               ,a.kpi_period_code ) a
     ,(
       SELECT '03.가동율' AS cat_cd
             ,prod.display_name AS prod
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,a.kpi_period_code
             ,SUM(a.standard_operation_rate) AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.target_code = 'PD_002'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @vc_post_1
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet04_yn = 'Y'
       AND    prod.sheet04_yn = 'Y'
       GROUP BY prod.display_name
               ,sub.display_name
               ,a.kpi_period_code ) b               
WHERE  a.prod = b.prod  
AND    a.sub  = b.sub
GROUP BY a.prod
        ,a.sub                     
) A
WHERE a.sub+a.prod NOT IN ('LGEAKPTV'
,'LGEAZPTV'
,'LGEHZPhotoPrinter'
,'LGEIL(Noida)Motor'
,'LGEIL(Noida)MWO'
,'LGEMAPTV'
,'LGESAPTV'
,'LGEVHCAC'
,'LGEKRBdMS'
,'LGEKRCommercialWater'
,'LGEKRMGT'
,'LGEKRPhotoPrinter'
,'교차KRLTV'
,'교차KRRAC'
)
;

END