ALTER PROCEDURE [dbo].[m_opsmr_sp_graph_location]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
 ,@location      VARCHAR(30)
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_graph_location
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_graph_location

--   EXEC m_opsmr_sp_graph_location 'STD', '201603', 'LOCAL'
--   EXEC m_opsmr_sp_graph_location 'STD', '201603', 'OVERSEA'
             
4. 관 련 화 면 :

버전    작 성 자     일        자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.12  최초작성
1.1   shlee      2016.04.15  KPI_TYPE 엑셀개발자 요청에 의해 추가
1.2   shlee      2016.04.21  날짜와 subsidiary/ Product Master적용
1.3   shlee      2016.04.22  계획포함
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
	    ,sum(standard_operation_rate) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
--AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    kpi_period_code BETWEEN @vc_pre_13 AND @vc_post_3
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name
		    ,kpi_period_code

UNION ALL
-- 13개월최고
SELECT '02.13개월최고' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'13개월최고' AS kpi
	    ,MAX(standard_operation_rate) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
--AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    kpi_period_code BETWEEN @vc_pre_13 AND @vc_post_3
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 01월부터 기준월까지
SELECT '03.01월부터 기준월까지' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2) AS kpi
	    ,CASE WHEN sum(production_capa) = 0 THEN 0
	          ELSE sum(production_quantity) / sum(production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
AND    kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 13개월누적
SELECT '04.13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'13개월누적' AS kpi
	    ,CASE WHEN sum(production_capa) = 0 THEN 0
	          ELSE sum(production_quantity) / sum(production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
--AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    kpi_period_code BETWEEN @vc_pre_13 AND @vc_post_3
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 전년대비 현재월까지 생산수량
SELECT '05.전년대비 현재월까지 생산수량' AS kpi_type
      ,prod
      ,prod_enm
      ,prod_knm
	    ,'전년대비 현재월까지 생산수량' AS kpi
	    ,sum(val1) - sum(val2) AS val
FROM (	  
      -- 01월부터 기준월까지
      SELECT prod.display_name AS prod
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
      	    ,sum(production_quantity) AS val1
            ,0 AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  opsmr_type = @opsmr_type
      AND    kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
      AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
      AND    a.gbu_code = prod.mapping_code
      AND    prod.use_flag = 'Y'
      GROUP BY prod.display_name
      
      UNION ALL
      -- 전년01월부터 기준월까지
      SELECT prod.display_name AS prod
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
      	    ,0 AS val1
      	    ,sum(production_quantity) AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  opsmr_type = @opsmr_type
      AND    kpi_period_code BETWEEN @vc_py_start_yyyymm AND @vc_pre_13
      AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
      AND    a.gbu_code = prod.mapping_code
      AND    prod.use_flag = 'Y'
      GROUP BY prod.display_name
     ) a
GROUP BY prod
        ,prod_enm
        ,prod_knm

UNION ALL
-- 전년13개월누적
SELECT '051.전년기준월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'전년기준월누적' AS kpi
	    ,CASE WHEN sum(production_capa) = 0 THEN 0
	          ELSE sum(production_quantity) / sum(production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
AND    kpi_period_code BETWEEN @vc_py_start_yyyymm AND @vc_pre_13
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 전년13개월누적
SELECT '06.전년13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'전년13개월' AS kpi
	    ,CASE WHEN sum(production_capa) = 0 THEN 0
	          ELSE sum(production_quantity) / sum(production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
AND    kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 13개월 전년대비 rate
SELECT '07.13개월 전년대비 rate' AS kpi_type
      ,prod
      ,prod_enm
      ,prod_knm
      ,'전년대비 13개월' AS kpi
      ,sum(val1) - sum(val2) AS val
FROM  (      
       -- 13개월누적
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
       	     ,'13개월누적' AS kpi
       	     ,CASE WHEN sum(production_capa) = 0 THEN 0
       	           ELSE sum(production_quantity) / sum(production_capa) END AS val1
       	     ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  opsmr_type = @opsmr_type
       --AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    kpi_period_code BETWEEN @vc_pre_13 AND @vc_post_3
       AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
       AND    a.gbu_code = prod.mapping_code
       AND    prod.use_flag = 'Y'
       GROUP BY prod.display_name

       UNION ALL
       -- 전년13개월누적
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
       	     ,'전년13개월' AS kpi
       	     ,0 AS val1
       	     ,CASE WHEN sum(production_capa) = 0 THEN 0
       	           ELSE sum(production_quantity) / sum(production_capa) END AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  opsmr_type = @opsmr_type
       AND    kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
       AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
       AND    a.gbu_code = prod.mapping_code
       AND    prod.use_flag = 'Y'
       GROUP BY prod.display_name
      ) a
GROUP BY prod
        ,prod_enm
        ,prod_knm

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
WHERE  opsmr_type = @opsmr_type
AND    kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 01월부터 기준월까지 수량 전년대비
SELECT '09.01월부터 기준월까지 수량 전년대비' AS kpi_type
      ,prod
      ,prod_enm
      ,prod_knm
      ,'현재월까지 전년대비수량' AS kpi
      ,CASE WHEN sum(val1)-sum(val2) = 0 THEN 0
            ELSE sum(val2) / sum(val1)-sum(val2) END AS val
FROM  (            
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
        	    ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'수량' AS kpi
        	    ,sum(production_quantity) AS val1
        	    ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  opsmr_type = @opsmr_type
       AND    kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
       AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
       AND    a.gbu_code = prod.mapping_code
       AND    prod.use_flag = 'Y'
       GROUP BY prod.display_name

       UNION ALL
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
       	     ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'수량' AS kpi
       	     ,0 AS val1
       	     ,sum(production_quantity) AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  opsmr_type = @opsmr_type
       AND    kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
       AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
       AND    a.gbu_code = prod.mapping_code
       AND    prod.use_flag = 'Y'
       GROUP BY prod.display_name
      ) a
GROUP BY prod
        ,prod_enm
        ,prod_knm

UNION ALL
-- 13개월누적
SELECT '10.13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'13개월수량' AS kpi
	    ,sum(production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
--AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    kpi_period_code BETWEEN @vc_pre_13 AND @vc_post_3
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 전년13개월누적
SELECT '11.전년13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'전년13개월수량' AS kpi
	    ,sum(production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
AND    kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
SELECT '12.전년13개월수량' AS kpi_type
      ,prod
      ,prod_enm
      ,prod_knm
      ,'전년대비 13개월수량' AS kpi
      ,sum(val1) - sum(val2) AS val
FROM  (
       -- 13개월누적
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
        	   ,sum(production_quantity) AS val1
       	     ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  opsmr_type = @opsmr_type
       --AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    kpi_period_code BETWEEN @vc_pre_13 AND @vc_post_3
       AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
       AND    a.gbu_code = prod.mapping_code
       AND    prod.use_flag = 'Y'
       GROUP BY prod.display_name
       
       UNION ALL
       -- 전년13개월누적
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
       	     ,0 AS val1
       	     ,sum(production_quantity) AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  opsmr_type = @opsmr_type
       AND    kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
       AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
       AND    a.gbu_code = prod.mapping_code
       AND    prod.use_flag = 'Y'
       GROUP BY prod.display_name
      ) a
GROUP BY prod
        ,prod_enm
        ,prod_knm

UNION ALL
-- 주요제품 기준월 기준가동율
SELECT '13.주요제품 기준월 기준가동율' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'주요제품 기준월 기준가동율' AS kpi
	    ,sum(standard_operation_rate) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
AND    kpi_period_code = @base_yyyymm
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 주요제품 기준월 기준가동율
SELECT '14.주요제품 기준월 운영가동율' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'주요제품 기준월 운영가동율' AS kpi
	    ,sum(actual_operation_rate) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
AND    kpi_period_code = @base_yyyymm
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 교차생산 기준가동율
SELECT '15.교차생산 기준가동율' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'교차생산 당월' AS kpi
	    ,sum(standard_operation_rate) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
AND    kpi_period_code = @base_yyyymm
AND    factory_region1 = 'CROSS(KR)'
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

UNION ALL
-- 13개월누적
SELECT '16.교차생산 13개월누적' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'교차생산 13개월누적' AS kpi
	    ,CASE WHEN sum(production_capa) = 0 THEN 0
	          ELSE sum(production_quantity) / sum(production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  opsmr_type = @opsmr_type
--AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    kpi_period_code BETWEEN @vc_pre_13 AND @vc_post_3
AND    factory_region1 = 'CROSS(KR)'
AND    factory_region1 IN (SELECT factory_region1 FROM M_OPSMR_TB_DISPLAY_MASTER(nolock) WHERE LOCATION = @location)
AND    a.gbu_code = prod.mapping_code
AND    prod.use_flag = 'Y'
GROUP BY prod.display_name

;



END