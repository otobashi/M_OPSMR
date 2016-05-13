ALTER PROCEDURE [dbo].[m_opsmr_sp_graph]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_graph
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_graph

--   EXEC m_opsmr_sp_graph 'STD', '201602'

4. 관 련 화 면 :

버전    작 성 자     일        자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.12  최초작성
1.1   shlee      2016.04.15  KPI_TYPE 엑셀개발자 요청에 의해 추가
1.2   shlee      2016.04.21  날짜와 subsidiary/ Product Master적용
1.3   shlee      2016.04.22  계획포함
1.4   shlee      2016.04.25  교차생산 제거
***************************************************************************/

DECLARE @vc_pre_13          AS VARCHAR(6);
DECLARE @vc_py_pre_13       AS VARCHAR(6);
DECLARE @vc_start_yyyymm    AS VARCHAR(6);
DECLARE @vc_py_start_yyyymm AS VARCHAR(6);

DECLARE @vc_post_3          AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13           = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전13월
SET @vc_py_pre_13        = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@vc_pre_13 + '01')), 112);    -- 전13월
SET @vc_start_yyyymm     = SUBSTRING(@base_yyyymm,1,4)+'01';    -- 누적년시작월 @vc_start_yyyymm
SET @vc_py_start_yyyymm  = SUBSTRING(@vc_pre_13,1,4)+'01';    -- 누적년시작월 @vc_start_yyyymm

SET @vc_post_3           = CONVERT(VARCHAR(6), DATEADD(m,3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전13월

BEGIN

-- 각 월별 실적구간
SELECT '01.월별실적구간' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,kpi_period_code
      ,CASE WHEN isnull(SUM(a.production_capa),0) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) end AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @vc_post_3
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    prod.graph_yn = 'Y'
GROUP BY prod.display_name
        ,kpi_period_code

UNION ALL
-- 13개월최고
SELECT '02.13개월최고' AS kpi_type
      ,a.prod AS prod
      ,MIN(a.prod_enm) AS prod_enm
      ,MIN(a.prod_knm) AS prod_knm
      ,'13개월최고' AS kpi
      ,MAX(a.val) AS val
FROM  (
       SELECT '01.월별실적구간' AS kpi_type
             ,prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,kpi_period_code
             ,CASE WHEN isnull(SUM(a.production_capa),0) = 0 THEN 0
                   ELSE SUM(a.production_quantity) / SUM(a.production_capa) end AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet15_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    prod.graph_yn = 'Y'
       GROUP BY prod.display_name
               ,kpi_period_code
      ) a
GROUP BY a.prod

UNION ALL
-- 01월부터 기준월까지
SELECT '03.01월부터 기준월까지' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2) AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    prod.graph_yn = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 13개월누적
SELECT '04.13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'13개월누적' AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    prod.graph_yn = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 전년대비 현재월까지 생산수량
SELECT '05.전년대비 현재월까지 생산수량' AS kpi_type
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'전년대비 현재월까지 생산수량' AS kpi
      ,sum(a.val1) - sum(a.val2) AS val
FROM (
      -- 01월부터 기준월까지
      SELECT prod.display_name AS prod
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
            ,sum(a.production_quantity) AS val1
            ,0 AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  a.opsmr_type = @opsmr_type
      AND    a.base_yyyymm = @base_yyyymm
      AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
      AND    a.gbu_code = prod.mapping_code
      AND    prod.sheet15_yn = 'Y'
      AND    a.factory_region1 <> 'CROSS(KR)'
      AND    prod.graph_yn = 'Y'
      GROUP BY prod.display_name

      UNION ALL
      -- 전년01월부터 기준월까지
      SELECT prod.display_name AS prod
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
            ,0 AS val1
            ,sum(a.production_quantity) AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  a.opsmr_type = @opsmr_type
      AND    a.base_yyyymm = @base_yyyymm
      AND    a.kpi_period_code BETWEEN @vc_py_start_yyyymm AND @vc_pre_13
      AND    a.gbu_code = prod.mapping_code
      AND    prod.sheet15_yn = 'Y'
      AND    a.factory_region1 <> 'CROSS(KR)'
      AND    prod.graph_yn = 'Y'
      GROUP BY prod.display_name

     ) a
GROUP BY a.prod
        ,a.prod_enm
        ,a.prod_knm

UNION ALL
-- 전년13개월누적
SELECT '051.전년기준월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'전년기준월누적' AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_py_start_yyyymm AND @vc_pre_13
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    prod.graph_yn = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 전년13개월누적
SELECT '06.전년13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'전년13개월' AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    prod.graph_yn = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 13개월 전년대비 rate
SELECT '07.13개월 전년대비 rate' AS kpi_type
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'전년대비 13개월' AS kpi
      ,sum(a.val1) - sum(a.val2) AS val
FROM  (
       -- 13개월누적
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,'13개월누적' AS kpi
             ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
                   ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val1
             ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet15_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    prod.graph_yn = 'Y'
       GROUP BY prod.display_name
       UNION ALL
       -- 전년13개월누적
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,'전년13개월' AS kpi
             ,0 AS val1
             ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
                   ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet15_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    prod.graph_yn = 'Y'
       GROUP BY prod.display_name
      ) a
GROUP BY a.prod
        ,a.prod_enm
        ,a.prod_knm

UNION ALL
-- 01월부터 기준월까지 수량
SELECT '08.01월부터 기준월까지 수량' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'수량' AS kpi
      ,sum(production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    prod.graph_yn = 'Y'
GROUP BY prod.display_name

UNION ALL

--
SELECT '09.01월부터 기준월까지 수량 전년대비' AS kpi_type
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'현재월까지 전년대비수량' AS kpi
      ,CASE WHEN isnull( sum(a.val2),0) - ISNULL(sum(a.val1),0 ) = 0 THEN 0
            ELSE sum(a.val1) / (isnull( sum(a.val2),0) - ISNULL(sum(a.val1),0 )) END AS val
FROM  (
        SELECT '05.전년대비 현재월까지 생산수량' AS kpi_type
              ,a.prod
              ,a.prod_enm
              ,a.prod_knm
              ,'전년대비 현재월까지 생산수량' AS kpi
              ,sum(a.val1) - sum(a.val2) AS val1
              ,0 AS val2
        FROM (
              -- 01월부터 기준월까지
              SELECT prod.display_name AS prod
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,sum(a.production_quantity) AS val1
                    ,0 AS val2
              FROM   m_opsmr_tb_op_rate(nolock) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
              WHERE  a.opsmr_type = @opsmr_type
              AND    a.base_yyyymm = @base_yyyymm
              AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
              AND    a.gbu_code = prod.mapping_code
              AND    prod.sheet15_yn = 'Y'
              AND    a.factory_region1 <> 'CROSS(KR)'
              AND    prod.graph_yn = 'Y'
              GROUP BY prod.display_name
        
              UNION ALL
              -- 전년01월부터 기준월까지
              SELECT prod.display_name AS prod
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,sum(a.production_quantity) AS val2
              FROM   m_opsmr_tb_op_rate(nolock) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
              WHERE  a.opsmr_type = @opsmr_type
              AND    a.base_yyyymm = @base_yyyymm
              AND    a.kpi_period_code BETWEEN @vc_py_start_yyyymm AND @vc_pre_13
              AND    a.gbu_code = prod.mapping_code
              AND    prod.sheet15_yn = 'Y'
              AND    a.factory_region1 <> 'CROSS(KR)'
              AND    prod.graph_yn = 'Y'
              GROUP BY prod.display_name
        
             ) a
        GROUP BY a.prod
                ,a.prod_enm
                ,a.prod_knm
        UNION ALL
        -- 01월부터 기준월까지 수량
        SELECT '08.01월부터 기준월까지 수량' AS kpi_type
              ,prod.display_name AS prod
              ,MIN(prod.display_enm) as prod_enm
              ,MIN(prod.display_knm) as prod_knm
              ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'수량' AS kpi
              ,0 AS val1
              ,sum(production_quantity) AS val2
        FROM   m_opsmr_tb_op_rate(nolock) a
              ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
        WHERE  a.opsmr_type = @opsmr_type
        AND    a.base_yyyymm = @base_yyyymm
        AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
        AND    a.gbu_code = prod.mapping_code
        AND    prod.sheet15_yn = 'Y'
        AND    a.factory_region1 <> 'CROSS(KR)'
        AND    prod.graph_yn = 'Y'
        GROUP BY prod.display_name
      ) a
GROUP BY a.prod
        ,a.prod_enm
        ,a.prod_knm

UNION ALL
-- 13개월누적
SELECT '10.13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'13개월수량' AS kpi
      ,sum(a.production_quantity)/1000 AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    prod.graph_yn = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 전년13개월누적
SELECT '11.전년13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'전년13개월수량' AS kpi
      ,sum(production_quantity)/1000 AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    prod.graph_yn = 'Y'
GROUP BY prod.display_name

UNION ALL
SELECT '12.전년13개월수량' AS kpi_type
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'전년대비 13개월수량' AS kpi
      ,sum(a.val1) - sum(a.val2) AS val
FROM  (
       -- 13개월누적
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,sum(a.production_quantity)/1000 AS val1
             ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet15_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    prod.graph_yn = 'Y'
       GROUP BY prod.display_name

       UNION ALL
       -- 전년13개월누적
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
             ,sum(A.production_quantity)/1000 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet15_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    prod.graph_yn = 'Y'
       GROUP BY prod.display_name
      ) a
GROUP BY a.prod
        ,a.prod_enm
        ,a.prod_knm

UNION ALL
-- 주요제품 기준월 기준가동율
SELECT '13.주요제품 기준월 기준가동율' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'주요제품 기준월 기준가동율' AS kpi
      ,CASE WHEN isnull(SUM(a.production_capa),0) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) end AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code = @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    prod.graph_yn = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 주요제품 기준월 운영가동율
SELECT '14.주요제품 기준월 운영가동율' AS kpi_type
      ,prod AS prod
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
      ,'주요제품 기준월 운영가동율' AS kpi
      ,CASE WHEN isnull(SUM(a.val2),0) = 0 THEN 0
            ELSE SUM(a.val1) / SUM(a.val2) end AS val
FROM  (
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val1
             ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = 'STD'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet15_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    prod.graph_yn = 'Y'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
             ,SUM(a.actual_production_capa) AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = 'PROD'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet15_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    prod.graph_yn = 'Y'
       GROUP BY prod.display_name
      ) A
GROUP BY prod
/*
UNION ALL
-- 13개월누적
SELECT '15.교차생산 13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'교차생산 13개월누적' AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
--AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.factory_region1 = 'CROSS(KR)'
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 교차생산 기준가동율
SELECT '16.교차생산 기준가동율' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'교차생산 당월' AS kpi
--      ,sum(a.standard_operation_rate) AS val
      ,CASE WHEN isnull(SUM(a.production_capa),0) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) end AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code = @base_yyyymm
AND    a.factory_region1 = 'CROSS(KR)'
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet15_yn = 'Y'
GROUP BY prod.display_name
*/
;



END