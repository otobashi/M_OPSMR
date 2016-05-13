CREATE PROCEDURE [dbo].[m_opsmr_sp_major_hr_03]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
 ,@subsidiary    VARCHAR(30)
 ,@product       VARCHAR(30)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_major_hr_03
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_major_hr_03

--   EXEC m_opsmr_sp_major_hr_03 'STD', '201603', 'LGEAT', 'RAC'
--   EXEC m_opsmr_sp_major_hr_03 'STD', '201603', 'Total(AT����)', 'Total'

4. �� �� ȭ �� :

����    �� �� ��     ��        ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.18  �����ۼ�
***************************************************************************/

DECLARE @vc_pre_13          AS VARCHAR(6);
DECLARE @vc_py_pre_13       AS VARCHAR(6);
--DECLARE @vc_start_yyyymm    AS VARCHAR(6);
--DECLARE @vc_py_start_yyyymm AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13           = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ��13��
SET @vc_py_pre_13        = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@vc_pre_13 + '01')), 112);    -- ��13��
--SET @vc_start_yyyymm     = SUBSTRING(@base_yyyymm,1,4)+'01';    -- ��������ۿ� @vc_start_yyyymm
--SET @vc_py_start_yyyymm  = SUBSTRING(@vc_pre_13,1,4)+'01';    -- ��������ۿ� @vc_start_yyyymm

BEGIN

-- 01.�����(�鸸��)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'01.�����(�鸸��)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
      ,SUM(a.value) AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '1. Production Amount(K$)'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.use_flag = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END

UNION ALL

-- 02.���ο�(�系��������)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'02.���ο�(�系��������)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
      ,SUM(CASE WHEN INDEX1 = '3. H/C' AND INDEX2 = 'Total - Exclude O/S' THEN 0
                WHEN INDEX1 = '3. H/C' AND INDEX2 = 'Sub-Total' AND INDEX3 = 'FSE (R&D)'  THEN 0
                WHEN INDEX1 = '3. H/C' AND INDEX2 = 'Sub-Total' AND INDEX3 = 'R&D' THEN 0
                WHEN INDEX1 = '3. H/C' AND INDEX2 = 'Sub-Total' AND INDEX3 = 'SW' THEN 0
                ELSE a.value END) AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.subsidiary NOT IN ('Total(AT����)','Total(AT����)')
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.use_flag = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END
UNION ALL
-- 03.���ο�(�系��������)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'03.���ο�(�系��������)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
      ,SUM(a.value) AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.subsidiary NOT IN ('Total(AT����)','Total(AT����)')
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.use_flag = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END
UNION ALL
-- 04.�ΰǺ�(�系��������)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'04.�ΰǺ�(�系��������)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
      ,SUM(CASE WHEN INDEX1 = '4. L/C (K$)' AND INDEX2 = 'Total - Exclude O/S' THEN 0
                WHEN INDEX1 = '4. L/C (K$)' AND INDEX2 = 'Labor Cost' AND INDEX3 = 'FSE (R&D)'  THEN 0
                WHEN INDEX1 = '4. L/C (K$)' AND INDEX2 = 'Labor Cost' AND INDEX3 = 'R&D SW Labor Cost' THEN 0
                ELSE a.value END) AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '4. L/C (K$)'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.use_flag = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END
UNION ALL
-- 05.�ΰǺ�(�系��������)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'05.�ΰǺ�(�系��������)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
      ,SUM(a.value) AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '4. L/C (K$)'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.use_flag = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END

UNION ALL
-- 06.�δ�����(õ��)
SELECT a.display_name as display_name
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
      ,'06.�δ�����(õ��)' AS kpi_type
      ,a.kpi_code
      ,CASE WHEN SUM(val2) = 0 THEN 0
            ELSE SUM(val1) / SUM(val2) END AS val
FROM  (SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN b.col = '1' THEN a.yyyymm
                   WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,(SELECT '1' AS col
               UNION ALL
               SELECT '2') b
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '1. Production Amount(K$)'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary = @subsidiary
       AND    a.product    = @product
       AND    a.product = hr.org_code
       AND    prod.use_flag = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN b.col = '1' THEN a.yyyymm
                   WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,(SELECT '1' AS col
               UNION ALL
               SELECT '2') b
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.subsidiary NOT IN ('Total(AT����)','Total(AT����)')
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary = @subsidiary
       AND    a.product    = @product
       AND    a.product = hr.org_code
       AND    prod.use_flag = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END) a
GROUP BY a.display_name
        ,a.kpi_code             

UNION ALL
-- 07.��������(��)
SELECT a.display_name as display_name
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
      ,'07.��������(��)' AS kpi_type
      ,a.kpi_code
      ,CASE WHEN SUM(val2) = 0 THEN 0
            ELSE SUM(val1) / SUM(val2) END AS val
FROM  (SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN b.col = '1' THEN a.yyyymm
                   WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,(SELECT '1' AS col
               UNION ALL
               SELECT '2') b
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '1. Production Amount(K$)'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary = @subsidiary
       AND    a.product    = @product
       AND    a.product = hr.org_code
       AND    prod.use_flag = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN b.col = '1' THEN a.yyyymm
                   WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,(SELECT '1' AS col
               UNION ALL
               SELECT '2') b
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '4. L/C (K$)'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary = @subsidiary
       AND    a.product    = @product
       AND    a.product = hr.org_code
       AND    prod.use_flag = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END) a
GROUP BY a.display_name
        ,a.kpi_code             
UNION ALL
-- 08.�����(�鸸��)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'05.�ΰǺ�(�系��������)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
      ,SUM(a.value) AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '4. L/C (K$)'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.use_flag = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END


;



END