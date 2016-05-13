ALTER PROCEDURE [dbo].[m_opsmr_sp_major_hr_01]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_major_hr_01
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_major_hr_01

--   EXEC m_opsmr_sp_major_hr_01 'STD', '201603'

4. �� �� ȭ �� :

����    �� �� ��     ��        ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.18  �����ۼ�
***************************************************************************/

DECLARE @vc_pre_13          AS VARCHAR(6);
DECLARE @vc_py_pre_13       AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13           = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ��13��
SET @vc_py_pre_13        = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@vc_pre_13 + '01')), 112);    -- ��13��

BEGIN

-- 01.������
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'01.������' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.kpi_period_code
            WHEN b.col = '2' THEN SUBSTRING(a.kpi_period_code,3,2)+' ����' END AS kpi_code
      ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
     ,(SELECT '1' AS col
       UNION ALL
       SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.factory_region1 <> 'LGEKR'
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet19_yn = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
AND    a.kpi_period_code not like '%TOT'
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.kpi_period_code
              WHEN b.col = '2' THEN SUBSTRING(a.kpi_period_code,3,2)+' ����' END

UNION ALL
-- 02.�ο�(��)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'02.�ο�(��)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
      ,CASE WHEN MIN(b.col) = '1' THEN SUM(a.value)
            WHEN MIN(b.col) = '2' THEN SUM(a.value)/12 END AS val
--      ,SUM(a.value) AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.std_yyyymm = @base_yyyymm
AND    a.product = hr.org_code
AND    prod.sheet19_yn = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
AND    a.product <> 'Total'
GROUP BY prod.display_name
        ,b.col
        ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END

UNION ALL
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'02.�ο�(��)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END AS kpi_code
      ,CASE WHEN MIN(b.col) = '1' THEN SUM(a.value)
            WHEN MIN(b.col) = '2' THEN SUM(a.value)/12 END AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.std_yyyymm = @base_yyyymm
AND    a.product = hr.org_code
AND    prod.sheet19_yn = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
AND    a.product = 'Total'
AND    a.subsidiary = 'Total(AT����)'
GROUP BY prod.display_name
        ,b.col
        ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END

UNION ALL
-- 03.�δ�����(õ��)
SELECT a.display_name as display_name
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
      ,'03.�δ�����(õ��)' AS kpi_type
      ,a.kpi_code
      ,CASE WHEN SUM(val2) = 0 THEN 0
            ELSE SUM(val1) / SUM(val2) END AS val
FROM  (
       SELECT prod.display_name as display_name
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
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END
       UNION ALL
       SELECT prod.display_name as display_name
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
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product = 'Total'
       AND    a.subsidiary = 'Total(AT����)'
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
             ,CASE WHEN MIN(b.col) = '1' THEN SUM(a.value)
                   WHEN MIN(b.col) = '2' THEN SUM(a.value)/12 END AS val2
--             ,SUM(a.value) AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,(SELECT '1' AS col
               UNION ALL
               SELECT '2') b
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
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
--             ,SUM(a.value) AS val2
             ,CASE WHEN MIN(b.col) = '1' THEN SUM(a.value)
                   WHEN MIN(b.col) = '2' THEN SUM(a.value)/12 END AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,(SELECT '1' AS col
               UNION ALL
               SELECT '2') b
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product = 'Total'
       AND    a.subsidiary = 'Total(AT����)'
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END
       ) a
GROUP BY a.display_name
        ,a.kpi_code
		             

UNION ALL
-- 04.��������(��)
SELECT a.display_name as display_name
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
      ,'04.��������(��)' AS kpi_type
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
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END
       UNION ALL
       SELECT prod.display_name as display_name
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
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product = 'Total'
       AND    a.subsidiary = 'Total(AT����)'
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
       AND    a.index2 = 'Total - Include O/S' 
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
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
       AND    a.index2 = 'Total - Include O/S' 
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product = 'Total'
       AND    a.subsidiary = 'Total(AT����)'
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' ����' END
       ) a
GROUP BY a.display_name
        ,a.kpi_code             

UNION ALL
-- ������ 01.������
SELECT py.display_name as display_name
      ,MIN(py.prod_enm) as prod_enm
      ,MIN(py.prod_knm) as prod_knm
      ,'01.������' AS kpi_type
      ,'������' AS kpi_code
      ,ROUND(sum(py.val1),2) - ROUND(sum(py.val2),2) AS val
FROM  (
       -- 01.������
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
                   ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val1
             ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.factory_region1 <> 'LGEKR'
       AND    a.kpi_period_code not like '%TOT'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
             ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
                   ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @vc_pre_13
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.factory_region1 <> 'LGEKR'
       AND    a.kpi_period_code not like '%TOT'
       GROUP BY prod.display_name
      ) py
GROUP BY py.display_name

UNION ALL
-- 02.�ο�(��)
SELECT py.display_name as display_name
      ,MIN(py.prod_enm) as prod_enm
      ,MIN(py.prod_knm) as prod_knm
      ,'02.�ο�(��)' AS kpi_type
      ,'������' AS kpi_code
      ,ROUND(sum(py.val1),2) - ROUND(sum(py.val2),2) AS val
FROM  (
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.yyyymm = @base_yyyymm
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.yyyymm = @base_yyyymm
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product = 'Total'
       AND    a.subsidiary = 'Total(AT����)'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm    
       AND    a.yyyymm = @vc_pre_13
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm    
       AND    a.yyyymm = @vc_pre_13
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product = 'Total'
       AND    a.subsidiary = 'Total(AT����)'
       GROUP BY prod.display_name
      ) py
GROUP BY py.display_name
UNION ALL
-- 03.�δ�����(õ��)
SELECT py.display_name as display_name
      ,MIN(py.prod_enm) as prod_enm
      ,MIN(py.prod_knm) as prod_knm
      ,'03.�δ�����(õ��)' AS kpi_type
      ,'������' AS kpi_code
      ,ROUND(sum(py.val1),2) - ROUND(sum(py.val2),2) AS val
FROM  (
       SELECT a.display_name as display_name
             ,MIN(a.prod_enm) as prod_enm
             ,MIN(a.prod_knm) as prod_knm
             ,CASE WHEN SUM(val2) = 0 THEN 0
                   ELSE SUM(val1) / SUM(val2) END AS val1
             ,0 AS val2
       FROM  (SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @base_yyyymm
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @base_yyyymm
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '3. H/C'
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @base_yyyymm
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '3. H/C'
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @base_yyyymm
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'
              GROUP BY prod.display_name
             ) a
       GROUP BY a.display_name
       UNION ALL
       SELECT a.display_name as display_name
             ,MIN(a.prod_enm) as prod_enm
             ,MIN(a.prod_knm) as prod_knm
             ,0 AS val1
             ,CASE WHEN SUM(val2) = 0 THEN 0
                   ELSE SUM(val1) / SUM(val2) END AS val2
       FROM  (SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @vc_pre_13
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @vc_pre_13
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '3. H/C'
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @vc_pre_13
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '3. H/C'
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @vc_pre_13
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'
              GROUP BY prod.display_name
             ) a
       GROUP BY a.display_name
      ) py
GROUP BY py.display_name

UNION ALL

-- 04.��������(��)
SELECT py.display_name as display_name
      ,MIN(py.prod_enm) as prod_enm
      ,MIN(py.prod_knm) as prod_knm
      ,'04.��������(��)' AS kpi_type
      ,'������' AS kpi_code
      ,ROUND(sum(py.val1),2) - ROUND(sum(py.val2),2) AS val
FROM  (
       SELECT a.display_name as display_name
             ,MIN(a.prod_enm) as prod_enm
             ,MIN(a.prod_knm) as prod_knm
             ,CASE WHEN SUM(val2) = 0 THEN 0
                   ELSE SUM(val1) / SUM(val2) END AS val1
             ,0 AS val2
       FROM  (SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @base_yyyymm
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @base_yyyymm
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'              
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '4. L/C (K$)' 
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @base_yyyymm
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '4. L/C (K$)' 
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @base_yyyymm
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'
              GROUP BY prod.display_name
             ) a
       GROUP BY a.display_name
       UNION ALL
       SELECT a.display_name as display_name
             ,MIN(a.prod_enm) as prod_enm
             ,MIN(a.prod_knm) as prod_knm
             ,0 AS val1
             ,CASE WHEN SUM(val2) = 0 THEN 0
                   ELSE SUM(val1) / SUM(val2) END AS val2
       FROM  (SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @vc_pre_13
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @vc_pre_13
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'              
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '4. L/C (K$)' 
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @vc_pre_13
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '4. L/C (K$)' 
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm = @vc_pre_13
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'
              GROUP BY prod.display_name
             ) a
       GROUP BY a.display_name
      ) py
GROUP BY py.display_name

UNION ALL
-- �������� 01.������
SELECT ppy.display_name as display_name
      ,MIN(ppy.prod_enm) as prod_enm
      ,MIN(ppy.prod_knm) as prod_knm
      ,'01.������' AS kpi_type
      ,'��������' AS kpi_code
      ,ROUND(sum(ppy.val1),2) - ROUND(sum(ppy.val2),2) AS val
FROM  (
       -- 01.������
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
                   ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val1
             ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.factory_region1 <> 'LGEKR'
       AND    a.kpi_period_code not like '%TOT'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
             ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
                   ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.factory_region1 <> 'LGEKR'
       AND    a.kpi_period_code not like '%TOT'
       GROUP BY prod.display_name
      ) ppy
GROUP BY ppy.display_name      

UNION ALL
-- 02.�ο�(��)
SELECT ppy.display_name as display_name
      ,MIN(ppy.prod_enm) as prod_enm
      ,MIN(ppy.prod_knm) as prod_knm
      ,'02.�ο�(��)' AS kpi_type
      ,'��������' AS kpi_code
      ,sum(ppy.val1) - sum(ppy.val2) AS val
FROM  (
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.value)/12 AS val1
             ,0 AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.value)/12 AS val1
--             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product = 'Total'
       AND    a.subsidiary = 'Total(AT����)'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
             ,SUM(a.value)/12 AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm    
       AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
--             ,SUM(a.value) AS val2
             ,SUM(a.value)/12 AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '3. H/C'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.std_yyyymm = @base_yyyymm    
       AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product = 'Total'
       AND    a.subsidiary = 'Total(AT����)'
       GROUP BY prod.display_name
      ) ppy
GROUP BY ppy.display_name      
UNION ALL
-- 03.�δ�����(õ��)
SELECT ppy.display_name as display_name
      ,MIN(ppy.prod_enm) as prod_enm
      ,MIN(ppy.prod_knm) as prod_knm
      ,'03.�δ�����(õ��)' AS kpi_type
      ,'��������' AS kpi_code
      ,sum(ppy.val1) - sum(ppy.val2) AS val
FROM  (
       SELECT a.display_name as display_name
             ,MIN(a.prod_enm) as prod_enm
             ,MIN(a.prod_knm) as prod_knm
             ,CASE WHEN SUM(val2) = 0 THEN 0
                   ELSE SUM(val1) / SUM(val2) END AS val1
             ,0 AS val2
       FROM  (SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value)/12 AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value)/12 AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'              
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value)/12 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '3. H/C'
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
--                    ,SUM(a.value) AS val2
                    ,SUM(a.value)/12 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '3. H/C'
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'
              GROUP BY prod.display_name
             ) a
       GROUP BY a.display_name
       UNION ALL
       SELECT a.display_name as display_name
             ,MIN(a.prod_enm) as prod_enm
             ,MIN(a.prod_knm) as prod_knm
             ,0 AS val1
             ,CASE WHEN SUM(val2) = 0 THEN 0
                   ELSE SUM(val1) / SUM(val2) END AS val2
       FROM  (SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value)/12 AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value)/12 AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'              
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value)/12 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '3. H/C'
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value)/12 AS val2
--                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '3. H/C'
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'
              GROUP BY prod.display_name
             ) a
       GROUP BY a.display_name
      ) ppy
GROUP BY ppy.display_name

UNION ALL

-- 04.��������(��)
SELECT ppy.display_name as display_name
      ,MIN(ppy.prod_enm) as prod_enm
      ,MIN(ppy.prod_knm) as prod_knm
      ,'04.��������(��)' AS kpi_type
      ,'��������' AS kpi_code
      ,sum(ppy.val1) - sum(ppy.val2) AS val
FROM  (
       SELECT a.display_name as display_name
             ,MIN(a.prod_enm) as prod_enm
             ,MIN(a.prod_knm) as prod_knm
             ,CASE WHEN SUM(val2) = 0 THEN 0
                   ELSE SUM(val1) / SUM(val2) END AS val1
             ,0 AS val2
       FROM  (SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
--                    ,SUM(a.value)/12 AS val1
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'              
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '4. L/C (K$)' 
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '4. L/C (K$)' 
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'              
              GROUP BY prod.display_name
             ) a
       GROUP BY a.display_name
       UNION ALL
       SELECT a.display_name as display_name
             ,MIN(a.prod_enm) as prod_enm
             ,MIN(a.prod_knm) as prod_knm
             ,0 AS val1
             ,CASE WHEN SUM(val2) = 0 THEN 0
                   ELSE SUM(val1) / SUM(val2) END AS val2
       FROM  (SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,SUM(a.value) AS val1
                    ,0 AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '1. Production Amount(K$)'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'              
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '4. L/C (K$)' 
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product <> 'Total'
              GROUP BY prod.display_name
              UNION ALL
              SELECT prod.display_name as display_name
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,SUM(a.value) AS val2
              FROM   M_OPSMR_HR(NOLOCK) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                    ,m_opsmr_hr_mst(nolock) hr
              WHERE  a.index1 = '4. L/C (K$)' 
              AND    a.index2 = 'Total - Include O/S'
              AND    a.std_yyyymm = @base_yyyymm
              AND    a.yyyymm LIKE SUBSTRING(@vc_py_pre_13,1,4)+'%'
              AND    a.product = hr.org_code
              AND    prod.sheet19_yn = 'Y'
              AND    hr.gbu_code = prod.mapping_code
              AND    hr.gbu_code IS NOT NULL
              AND    a.product = 'Total'
              AND    a.subsidiary = 'Total(AT����)'              
              GROUP BY prod.display_name
             ) a
       GROUP BY a.display_name
      ) ppy
GROUP BY ppy.display_name

;



END