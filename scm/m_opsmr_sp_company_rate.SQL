ALTER PROCEDURE [dbo].[m_opsmr_sp_company_rate]
(
  @base_yyyymm     VARCHAR(6)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_company_rate
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_company_rate

--   EXEC m_opsmr_sp_company_rate 'STD','201603'

4. �� �� ȭ �� :

����    �� �� ��     ��        ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.15  �����ۼ�
1.1   shlee      2016.04.21  ��¥�� subsidiary/ Product Master����
***************************************************************************/

DECLARE @vc_pre_13          AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13           = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ��13��

BEGIN

SELECT *
FROM   (
-- ����������
SELECT '01.����������' AS kpi_type
      ,prod.company_code AS company_code
      ,prod.display_name AS prod
      ,MAX(prod.display_enm) AS prod_enm
      ,MAX(prod.display_knm) AS prod_knm
      ,'����' AS TP
      ,a.kpi_period_code AS kpi
      ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = 'STD'
AND    a.base_yyyymm = @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet20_yn = 'Y'
GROUP BY prod.company_code
        ,prod.display_name
        ,a.kpi_period_code
UNION ALL
-- ������
SELECT '02.������' AS kpi_type
      ,a.company_code
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'����' AS TP
      ,'������' AS kpi
      ,ROUND(SUM(a.val1),2) - ROUND(SUM(a.val2),2) AS val
FROM (
      SELECT prod.company_code AS company_code
            ,prod.display_name AS prod
            ,MAX(prod.display_enm) AS prod_enm
            ,MAX(prod.display_knm) AS prod_knm
            ,a.kpi_period_code AS kpi
            ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
                  ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val1
            ,0 AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  a.opsmr_type = 'STD'
      AND    a.base_yyyymm = @base_yyyymm
      AND    a.kpi_period_code = @base_yyyymm
      AND    a.gbu_code = prod.mapping_code
      AND    prod.sheet20_yn = 'Y'
      GROUP BY prod.company_code
              ,prod.display_name
              ,a.kpi_period_code

      UNION ALL
      SELECT prod.company_code AS company_code
            ,prod.display_name AS prod
            ,MAX(prod.display_enm) AS prod_enm
            ,MAX(prod.display_knm) AS prod_knm
            ,a.kpi_period_code AS kpi
            ,0 AS val1
            ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
                  ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  a.opsmr_type = 'STD'
      AND    a.base_yyyymm = @base_yyyymm
      AND    a.kpi_period_code = @vc_pre_13
      AND    a.gbu_code = prod.mapping_code
      AND    prod.sheet20_yn = 'Y'
      GROUP BY prod.company_code
              ,prod.display_name
              ,a.kpi_period_code
     ) a
GROUP BY a.company_code
        ,a.prod
        ,a.prod_enm
        ,a.prod_knm

UNION ALL
-- �
-- ����������
SELECT '01.����������' AS kpi_type
      ,prod.company_code AS company_code
      ,prod.display_name AS prod
      ,MAX(prod.display_enm) AS prod_enm
      ,MAX(prod.display_knm) AS prod_knm
      ,'�' AS TP
      ,a.kpi_period_code AS kpi
      ,CASE WHEN SUM(CASE WHEN a.opsmr_type = 'PROD' THEN a.actual_production_capa END ) = 0 THEN 0
            ELSE SUM(CASE WHEN a.opsmr_type = 'STD' THEN a.production_quantity END) / SUM(CASE WHEN a.opsmr_type = 'PROD' THEN a.actual_production_capa END ) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.base_yyyymm = @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet20_yn = 'Y'
GROUP BY prod.company_code
        ,prod.display_name
        ,a.kpi_period_code
) A
WHERE A.company_code+A.prod_knm NOT IN ('AEĥ��'
,'BdMSSRT'
,'C&M���������'
,'C&M����'
,'C&M�ֹ�'
,'CEMLCD����'
,'CommercialWaterCST'
,'HA���׳�Ʈ��'
,'HECTV'
,'HEDS'
,'HEPC'
,'HEPTV'
,'HESecurity'
,'PhotoPrinterPHT'
)        
/*        
UNION ALL
-- ������
SELECT '02.������' AS kpi_type
      ,a.company_code
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'�' AS TP
      ,'������' AS kpi
      ,SUM(a.val1) - SUM(a.val2) AS val
FROM (
      SELECT prod.company_code AS company_code
            ,prod.display_name AS prod
            ,MAX(prod.display_enm) AS prod_enm
            ,MAX(prod.display_knm) AS prod_knm
            ,a.kpi_period_code AS kpi
--            ,CASE WHEN SUM(a.actual_production_capa) = 0 THEN 0
--                  ELSE SUM(a.production_quantity) / SUM(a.actual_production_capa) END AS val1
            ,CASE WHEN SUM(CASE WHEN a.opsmr_type = 'PROD' THEN a.actual_production_capa END ) = 0 THEN 0
                  ELSE SUM(CASE WHEN a.opsmr_type = 'STD' THEN a.production_quantity END) / SUM(CASE WHEN a.opsmr_type = 'PROD' THEN a.actual_production_capa END ) END AS val1
            ,0 AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  a.base_yyyymm = @base_yyyymm
      AND    a.kpi_period_code = @base_yyyymm
      AND    a.gbu_code = prod.mapping_code
      AND    prod.sheet20_yn = 'Y'
      GROUP BY prod.company_code
              ,prod.display_name
              ,a.kpi_period_code
      UNION ALL
      SELECT prod.company_code AS company_code
            ,prod.display_name AS prod
            ,MAX(prod.display_enm) AS prod_enm
            ,MAX(prod.display_knm) AS prod_knm
            ,a.kpi_period_code AS kpi
            ,0 AS val1
--            ,CASE WHEN SUM(a.actual_production_capa) = 0 THEN 0
--                  ELSE SUM(a.production_quantity) / SUM(a.actual_production_capa) END AS val2
            ,CASE WHEN SUM(CASE WHEN a.opsmr_type = 'PROD' THEN a.actual_production_capa END ) = 0 THEN 0
                  ELSE SUM(CASE WHEN a.opsmr_type = 'STD' THEN a.production_quantity END) / SUM(CASE WHEN a.opsmr_type = 'PROD' THEN a.actual_production_capa END ) END AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  a.kpi_period_code = @vc_pre_13
      AND    a.base_yyyymm = @base_yyyymm
      AND    a.gbu_code = prod.mapping_code
      AND    prod.sheet20_yn = 'Y'
      GROUP BY prod.company_code
              ,prod.display_name
              ,a.kpi_period_code
     ) a
GROUP BY a.company_code
        ,a.prod
        ,a.prod_enm
        ,a.prod_knm
*/
;



END