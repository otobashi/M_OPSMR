ALTER PROCEDURE [dbo].[m_opsmr_sp_rate_section_plan]
(
  @opsmr_type    VARCHAR(5)
 ,@start_yyyymm  VARCHAR(6)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_rate_section_plan
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_rate_section_plan

--   EXEC m_opsmr_sp_rate_section_plan 'STD', '201602'  -- ���ذ�����
--   EXEC m_opsmr_sp_rate_section_plan 'PROD', '201602' -- �������
             
4. �� �� ȭ �� :

����  �� �� ��   ��      ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.05  �����ۼ�
1.1   shlee      2016.04.21  ��¥�� subsidiary/ Product Master����
1.2   shlee      2016.04.22  ���س���߰� �ó������ڵ����
***************************************************************************/
DECLARE @vc_post_1      AS VARCHAR(6);
DECLARE @vc_post_2      AS VARCHAR(6);
DECLARE @vc_post_3      AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_post_1     = CONVERT(VARCHAR(6), DATEADD(m,  1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����13������
SET @vc_post_2     = CONVERT(VARCHAR(6), DATEADD(m,  2, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����13������
SET @vc_post_3     = CONVERT(VARCHAR(6), DATEADD(m,  3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����13������

BEGIN

-- 01.�����հ�	
SELECT '01.�����հ�' AS cat_cd
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
-- 02.M+1����	
SELECT '02.M+1����' AS cat_cd
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
-- 03.M+2����	
SELECT '03.M+2����' AS cat_cd
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
-- 04.M+3����
SELECT '04.M+3����' AS cat_cd
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