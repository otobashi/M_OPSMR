ALTER PROCEDURE [dbo].[m_opsmr_sp_prod_sub_qty_sum]
(
  @opsmr_type    VARCHAR(5)
 ,@start_yyyymm  VARCHAR(6)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_prod_sub_qty_sum
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_prod_sub_qty_sum

--   EXEC m_opsmr_sp_prod_sub_qty_sum 'STD', '201602'  -- ���ذ�����
--   EXEC m_opsmr_sp_prod_sub_qty_sum 'PROD', '201602' -- �������
             
4. �� �� ȭ �� :

����  �� �� ��   ��      ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.05  �����ۼ�
1.1   shlee      2016.04.20  ��¥����
***************************************************************************/

DECLARE @vc_pre_13  AS VARCHAR(6);
DECLARE @vc_post_1  AS VARCHAR(6);
DECLARE @vc_post_3  AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13 = CONVERT(VARCHAR(6), DATEADD(m, -12, CONVERT(DATETIME,@base_yyyymm+'01')), 112);    -- ����13������
SET @vc_post_1 = CONVERT(VARCHAR(6), DATEADD(m,   1, CONVERT(DATETIME,@base_yyyymm+'01')), 112);    -- ����1����
SET @vc_post_3 = CONVERT(VARCHAR(6), DATEADD(m,   3, CONVERT(DATETIME,@base_yyyymm+'01')), 112);    -- ����3����

BEGIN

SELECT *
FROM  (
-- ��������	
SELECT '01.��������' AS cat_cd
      ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,kpi_period_code
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
AND    sub.sheet03_yn = 'Y'
AND    prod.sheet03_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name
	      ,kpi_period_code

UNION ALL
-- ������� �������
SELECT '02.������� ���' AS cat_cd
      ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'�������' AS kpi_period_code
	    ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet03_yn = 'Y'
AND    prod.sheet03_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name

UNION ALL
-- ������� ��������
SELECT '021.������� ����' AS cat_cd
      ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'��������' AS kpi_period_code
	    ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @vc_post_1
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet03_yn = 'Y'
AND    prod.sheet03_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name

UNION ALL
-- ������� ����13����
SELECT '022.������� ����13����' AS cat_cd
      ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'����13����' AS kpi_period_code
	    ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet03_yn = 'Y'
AND    prod.sheet03_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name

UNION ALL
SELECT '03.�������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'�������' AS kpi_period_code
      ,CASE WHEN SUM(b.qty) = 0 THEN 0
          ELSE SUM(a.qty)/SUM(b.qty) END AS val
FROM  ( SELECT prod.display_name AS prod
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
        AND    sub.sheet03_yn = 'Y'
        AND    prod.sheet03_yn = 'Y'
        GROUP BY prod.display_name
          	    ,sub.display_name
       ) A
       LEFT JOIN
      ( SELECT prod.display_name AS prod
       	      ,SUM(a.production_quantity) as qty
        FROM   m_opsmr_tb_op_rate(nolock) a
              ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
        WHERE  a.opsmr_type = @opsmr_type
        AND    target_code = 'PD_002'
        AND    a.base_yyyymm = @base_yyyymm
        AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
        AND    a.factory_region1 = sub.mapping_code
        AND    a.gbu_code = prod.mapping_code
        AND    sub.sheet03_yn = 'Y'
        AND    prod.sheet03_yn = 'Y'
        GROUP BY prod.display_name
       ) B
       ON A.prod = B.prod
GROUP BY a.prod
        ,a.sub

UNION ALL
SELECT '04.��ǰTOTAL' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'�������' AS kpi_period_code
      ,SUM(b.qty) AS val
FROM  ( SELECT prod.display_name AS prod
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
        AND    sub.sheet03_yn = 'Y'
        AND    prod.sheet03_yn = 'Y'
        GROUP BY prod.display_name
          	    ,sub.display_name

       ) A
       LEFT JOIN
      ( SELECT prod.display_name AS prod
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
        AND    sub.sheet03_yn = 'Y'
        AND    prod.sheet03_yn = 'Y'
        GROUP BY prod.display_name
       ) B
       ON A.prod = B.prod
GROUP BY a.prod
        ,a.sub
) A
WHERE a.prod+a.sub NOT IN ('BdMSLGEKR'
,'CACLGEVH'
,'CommercialWaterLGEKR'
,'LTV����KR'
,'MGTLGEKR'
,'MotorLGEIL(Noida)'
,'MWOLGEIL(Noida)'
,'PhotoPrinterLGEHZ'
,'PhotoPrinterLGEKR'
,'PTVLGEAK'
,'PTVLGEAZ'
,'PTVLGEMA'
,'PTVLGESA'
,'RAC����KR'
)        

;

END