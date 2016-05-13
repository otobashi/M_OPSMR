ALTER PROCEDURE [dbo].[m_opsmr_sp_sub_prod_qty_capa]
(
  @opsmr_type    VARCHAR(5)
 ,@start_yyyymm  VARCHAR(6)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_sub_prod_qty_capa
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_sub_prod_qty_capa

--   EXEC m_opsmr_sp_sub_prod_qty_capa 'STD', '201602', '201602'  -- ���ذ�����
--   EXEC m_opsmr_sp_sub_prod_qty_capa 'PROD', '201602', '201602' -- �������

4. �� �� ȭ �� :

����  �� �� ��   ��      ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.05  �����ۼ�
1.1   shlee      2016.04.20  ��¥����
1.2   shlee      2016.04.20  ���/2.���� ��¥����
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

SET @vc_pre_13      = CONVERT(VARCHAR(6), DATEADD(m, -12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����13������
SET @vc_pre_yyyy    = CONVERT(VARCHAR(4), DATEADD(yy, -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����
SET @vc_pre_py_yyyy = CONVERT(VARCHAR(4), DATEADD(yy, -2, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ������
SET @vc_pre_yyyymm  = CONVERT(VARCHAR(4), DATEADD(yy, -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112) + SUBSTRING(@base_yyyymm,5,2);    -- ����
SET @vc_pre_yyyy13  = CONVERT(VARCHAR(6), DATEADD(m, -12, CONVERT(DATETIME,CONVERT(VARCHAR(4), DATEADD(yy,  -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112) + SUBSTRING(@base_yyyymm,5,2) + '01')), 112);  -- ����

SET @vc_pre_1       = CONVERT(VARCHAR(6), DATEADD(m,  -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����1����
SET @vc_post_1      = CONVERT(VARCHAR(6), DATEADD(m,   1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����1����
SET @vc_post_3      = CONVERT(VARCHAR(6), DATEADD(m,   3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����3����

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
-- 02.�������
SELECT '02.�������' AS cat_cd
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
-- 03.������
SELECT '03.������' AS cat_cd
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
-- 04.���������
SELECT '04.���������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.�������' AS kpi_period_code
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
-- 04.���������
SELECT '04.���������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'2.��������' AS kpi_period_code
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
-- 04.���������
SELECT '04.���������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'����13����' AS kpi_period_code
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
-- 05.�������
SELECT '05.�������' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'1.�������' AS kpi_period_code
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
-- 05.�������
SELECT '05.�������' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'2.��������' AS kpi_period_code
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
-- 05.�������
SELECT '05.�������' AS cat_cd
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
-- 06.����CAPA
SELECT '06.����CAPA' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'1.�������' AS kpi_period_code
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
-- 06.����CAPA
SELECT '06.����CAPA' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'2.��������' AS kpi_period_code
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
-- 06.����CAPA
SELECT '06.����CAPA' AS cat_cd
      ,prod.display_name AS prod
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'����13����' AS kpi_period_code
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
-- 07.���������
SELECT '07.���������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.�������' AS kpi_period_code
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
-- 07.���������
SELECT '07.���������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'2.��������' AS kpi_period_code
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
-- 07.���������
SELECT '07.���������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'����13����' AS kpi_period_code
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
-- 08.�������
SELECT '08.�������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.�������' AS kpi_period_code
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
-- 09.��ǰTOTAL
SELECT '09.��ǰTOTAL' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.�������' AS kpi_period_code
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
-- 10.������
SELECT '10.������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'1.�������' AS kpi_period_code
      ,SUM(a.val) - SUM(b.val) AS val
FROM  (
       SELECT '03.������' AS cat_cd
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
       SELECT '03.������' AS cat_cd
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
SELECT '10.������' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'2.��������' AS kpi_period_code
      ,SUM(b.val) - SUM(a.val) AS val
FROM  (
       SELECT '03.������' AS cat_cd
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
       SELECT '03.������' AS cat_cd
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
,'����KRLTV'
,'����KRRAC'
)
;

END