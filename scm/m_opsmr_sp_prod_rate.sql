ALTER PROCEDURE [dbo].[m_opsmr_sp_prod_rate]
(
  @opsmr_type    VARCHAR(5)
 ,@start_yyyymm  VARCHAR(6)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_prod_rate
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_prod_rate

--   EXEC m_opsmr_sp_prod_rate 'STD', '201602'  -- ���ذ�����
--   EXEC m_opsmr_sp_prod_rate 'PROD', '201602' -- �������
             
4. �� �� ȭ �� :

����  �� �� ��   ��      ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.05  �����ۼ�
***************************************************************************/
DECLARE @vc_post_3      AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_post_3     = CONVERT(VARCHAR(6), DATEADD(m,   3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 3������

BEGIN

SELECT *
FROM   (
-- 01.����CAPA	
SELECT '01.����CAPA' AS cat_cd
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
WHERE  a.opsmr_type = 'STD'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet05_yn = 'Y'
AND    prod.sheet05_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name
  	    ,a.kpi_period_code

UNION ALL
-- 02.����ε��	
SELECT '02.����ε��' AS cat_cd
	    ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,a.kpi_period_code
	    ,SUM(a.actual_production_capa) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = 'PROD'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet05_yn = 'Y'
AND    prod.sheet05_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name
  	    ,a.kpi_period_code

UNION ALL
-- 03.�CAPA	
SELECT '03.�CAPA' AS cat_cd
	    ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,a.kpi_period_code
	    ,SUM(a.actual_production_capa) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = 'PROD'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet05_yn = 'Y'
AND    prod.sheet05_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name
  	    ,a.kpi_period_code

UNION ALL
-- 04.�������
SELECT '04.�������' AS cat_cd
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
WHERE  a.opsmr_type = 'STD'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet05_yn = 'Y'
AND    prod.sheet05_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name
  	    ,a.kpi_period_code

UNION ALL
-- 05.������
SELECT '05.������' AS cat_cd
	    ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,a.kpi_period_code
	    ,CASE WHEN ISNULL(SUM(a.production_capa),0) = 0 THEN 0
	          ELSE SUM(a.production_quantity)/SUM(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = 'STD'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet05_yn = 'Y'
AND    prod.sheet05_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name
  	    ,a.kpi_period_code
UNION ALL
-- 06.�������
SELECT '06.�������' AS cat_cd
	    ,a.prod AS prod
	    ,a.sub  AS sub
	    ,MIN(a.sub_enm) AS sub_enm
      ,MIN(a.sub_knm) as sub_knm
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
	    ,a.kpi_period_code
	    ,CASE WHEN ISNULL(SUM(a.val2),0) = 0 THEN 0
	          ELSE SUM(a.val1)/SUM(a.val2) END AS val
FROM  (
       SELECT prod.display_name AS prod
       	    ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
       	    ,a.kpi_period_code
       	    ,SUM(a.production_quantity) AS val1
       	    ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = 'STD'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet05_yn = 'Y'
       AND    prod.sheet05_yn = 'Y'
       GROUP BY prod.display_name
         	    ,sub.display_name
         	    ,a.kpi_period_code
       UNION ALL
       SELECT prod.display_name AS prod
       	    ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
       	    ,a.kpi_period_code
       	    ,0 AS val1
       	    ,SUM(a.actual_production_capa) AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = 'PROD'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
       AND    a.factory_region1 = sub.mapping_code
       AND    a.gbu_code = prod.mapping_code
       AND    sub.sheet05_yn = 'Y'
       AND    prod.sheet05_yn = 'Y'
       GROUP BY prod.display_name
         	    ,sub.display_name
         	    ,a.kpi_period_code
     ) A
GROUP BY a.prod
        ,a.sub
        ,a.kpi_period_code     
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
,'����KRLTV'
,'����KRRAC'
)
;

END