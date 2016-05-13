ALTER PROCEDURE [dbo].[m_opsmr_sp_rate_section_plan]
(
  @opsmr_type    VARCHAR(5)
 ,@start_yyyymm  VARCHAR(6)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_rate_section_plan
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_rate_section_plan

--   EXEC m_opsmr_sp_rate_section_plan 'STD', '201602'  -- 기준가동율
--   EXEC m_opsmr_sp_rate_section_plan 'PROD', '201602' -- 운영가동율
             
4. 관 련 화 면 :

버전  작 성 자   일      자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.05  최초작성
1.1   shlee      2016.04.21  날짜와 subsidiary/ Product Master적용
1.2   shlee      2016.04.22  기준년월추가 시나리오코드삭제
***************************************************************************/
DECLARE @vc_post_1      AS VARCHAR(6);
DECLARE @vc_post_2      AS VARCHAR(6);
DECLARE @vc_post_3      AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_post_1     = CONVERT(VARCHAR(6), DATEADD(m,  1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직전13개월전
SET @vc_post_2     = CONVERT(VARCHAR(6), DATEADD(m,  2, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직전13개월전
SET @vc_post_3     = CONVERT(VARCHAR(6), DATEADD(m,  3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직전13개월전

BEGIN

-- 01.구간합계	
SELECT '01.구간합계' AS cat_cd
	    ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,MIN(a.kpi_period_code)+'~'+MAX(a.kpi_period_code) AS kpi_period_code
	    ,CASE WHEN SUM(a.PRODUCTION_CAPA) = 0 THEN 0
	          ELSE SUM(a.PRODUCTION_QUANTITY) / SUM(a.PRODUCTION_CAPA) END AS val
      ,'' AS dummy1
      ,'' AS dummy2
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_post_1 AND @vc_post_3
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet07_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
GROUP BY prod.display_name

UNION ALL
-- 02.M+1예상	
SELECT '02.M+1예상' AS cat_cd
	    ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,a.kpi_period_code
	    ,CASE WHEN SUM(a.PRODUCTION_CAPA) = 0 THEN 0
	          ELSE SUM(a.PRODUCTION_QUANTITY) / SUM(a.PRODUCTION_CAPA) END AS val
      ,'' AS dummy1
      ,'' AS dummy2
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code = @vc_post_1
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet07_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
GROUP BY prod.display_name
  	    ,a.kpi_period_code

UNION ALL
-- 03.M+2예상	
SELECT '03.M+2예상' AS cat_cd
	    ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,a.kpi_period_code
	    ,CASE WHEN SUM(a.PRODUCTION_CAPA) = 0 THEN 0
	          ELSE SUM(a.PRODUCTION_QUANTITY) / SUM(a.PRODUCTION_CAPA) END AS val
      ,'' AS dummy1
      ,'' AS dummy2
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code = @vc_post_2
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet07_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
GROUP BY prod.display_name
  	    ,a.kpi_period_code

UNION ALL
-- 04.M+3예상
SELECT '04.M+3예상' AS cat_cd
	    ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,a.kpi_period_code
	    ,CASE WHEN SUM(a.PRODUCTION_CAPA) = 0 THEN 0
	          ELSE SUM(a.PRODUCTION_QUANTITY) / SUM(a.PRODUCTION_CAPA) END AS val
      ,'' AS dummy1
      ,'' AS dummy2
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code = @vc_post_3
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet07_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
GROUP BY prod.display_name
  	    ,a.kpi_period_code
;

END