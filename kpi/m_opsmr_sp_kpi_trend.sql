ALTER PROCEDURE [dbo].[m_opsmr_sp_kpi_trend]
(
  @base_yyyymm  VARCHAR(6)
 ,@subsidiary   VARCHAR(6)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_kpi_trend
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_kpi_trend

--   EXEC m_opsmr_sp_kpi_trend '201603', 'LGETH'

4. �� �� ȭ �� :

����  �� �� ��   ��      ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.05.09  �����ۼ�
***************************************************************************/

DECLARE @vc_pre_yyyy        AS VARCHAR(4);
DECLARE @vc_pre_py_yyyy     AS VARCHAR(4);
DECLARE @vc_pre_py_py_yyyy  AS VARCHAR(4);

DECLARE @vc_start_yyyymm    AS VARCHAR(6);
DECLARE @vc_py_start_yyyymm AS VARCHAR(6);
DECLARE @vc_py_end_yyyymm   AS VARCHAR(6);

DECLARE @vc_post_1          AS VARCHAR(6);
DECLARE @vc_post_3          AS VARCHAR(6);
DECLARE @vc_py_post_1       AS VARCHAR(6);
DECLARE @vc_py_post_3       AS VARCHAR(6);

DECLARE @vc_py_pre_15       AS VARCHAR(6);
DECLARE @vc_pre_15          AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_yyyy         = CONVERT(VARCHAR(4), DATEADD(yy, -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����
SET @vc_pre_py_yyyy      = CONVERT(VARCHAR(4), DATEADD(yy, -2, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ������
SET @vc_pre_py_py_yyyy   = CONVERT(VARCHAR(4), DATEADD(yy, -3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ������

SET @vc_start_yyyymm     = SUBSTRING(@base_yyyymm,1,4)+'01';
SET @vc_py_start_yyyymm  = @vc_pre_yyyy+'01'; -- ���⴩�����ۿ�
SET @vc_py_end_yyyymm    = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2); -- ���⴩�������

SET @vc_post_1           = CONVERT(VARCHAR(6), DATEADD(m,   1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����1����
SET @vc_post_3           = CONVERT(VARCHAR(6), DATEADD(m,   3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����3����

SET @vc_py_post_1        = @vc_pre_yyyy+SUBSTRING(@vc_post_1,5,2); -- ��������3�������ۿ�
SET @vc_py_post_3        = @vc_pre_yyyy+SUBSTRING(@vc_post_3,5,2); -- ��������3���������

SET @vc_pre_15           = CONVERT(VARCHAR(6), DATEADD(m,-14, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ��13��
SET @vc_py_pre_15        = CONVERT(VARCHAR(6), DATEADD(m,-26, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ��13��

BEGIN

-- 01.����(���γⰣ)
SELECT '01.����' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'SALE'
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 01.����(���ο���)
SELECT '01.����' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'SALE'
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL
-- 02.�����(���γⰣ)
SELECT '02.�����' AS cat_cd
      ,a.sub AS sub
      ,'' AS prod
  	  ,a.kpi_code AS kpi_code
      ,CASE WHEN b.val = 0 THEN 0
            ELSE (b.val - a.val) / b.val END AS val
FROM  (      
       SELECT '01.����' AS cat_cd
             ,sub.display_name AS sub
         	  ,ROW_NUMBER() OVER (ORDER BY '01.'+SUBSTRING(a.yyyymm,3,2)+'����') AS RN
             ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
             ,SUM(a.value) AS val
       FROM   m_opsmr_salecoi(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
       and    a.scenario_type = 'AC0'
       and    a.kpi_code = 'SALE'
       GROUP BY sub.display_name
               ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'
      ) A
      ,(      
       SELECT '01.����' AS cat_cd
             ,sub.display_name AS sub
         	  ,ROW_NUMBER() OVER (ORDER BY '01.'+SUBSTRING(a.yyyymm,3,2)+'����') AS RN
             ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
             ,SUM(a.value) AS val
       FROM   m_opsmr_salecoi(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_py_py_yyyy+'01' and @vc_pre_yyyy + SUBSTRING(@base_yyyymm,5,2)
       and    a.scenario_type = 'AC0'
       and    a.kpi_code = 'SALE'
       GROUP BY sub.display_name
               ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'
      ) B
WHERE A.rn = B.rn

UNION ALL
-- 02.�����(���ο���)
SELECT '02.�����' AS cat_cd
      ,a.sub AS sub
      ,'' AS prod
  	  ,a.kpi_code AS kpi_code
      ,CASE WHEN b.val = 0 THEN 0
            ELSE (b.val - a.val) / b.val END AS val
FROM  (      
       SELECT '01.����' AS cat_cd
             ,sub.display_name AS sub
         	   ,ROW_NUMBER() OVER (ORDER BY '02.'+a.yyyymm) AS RN
             ,'02.'+a.yyyymm AS kpi_code
             ,SUM(a.value) AS val
       FROM   m_opsmr_salecoi(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_15 and @vc_post_3
       and    a.scenario_type = 'AC0'
       and    a.kpi_code = 'SALE'
       GROUP BY sub.display_name
               ,'02.'+a.yyyymm
      ) A
      ,(      
       SELECT '01.����' AS cat_cd
             ,sub.display_name AS sub
         	   ,ROW_NUMBER() OVER (ORDER BY '02.'+a.yyyymm) AS RN
             ,'02.'+a.yyyymm AS kpi_code
             ,SUM(a.value) AS val
       FROM   m_opsmr_salecoi(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_py_pre_15 and @vc_py_post_3
       and    a.scenario_type = 'AC0'
       and    a.kpi_code = 'SALE'
       GROUP BY sub.display_name
               ,'02.'+a.yyyymm
      ) B
WHERE A.rn = B.rn

UNION ALL
-- 03.��ǰ������(���γⰣ)
SELECT '03.��ǰ������' AS cat_cd
      ,sub.display_name AS sub
      ,prod.product AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
       LEFT JOIN
       m_opsmr_tb_sub_prod_mapping(nolock) prod
--       ON  a.subsidiary  = prod.subsidiary
       ON  a.prod        = prod.product
       AND prod.subsidiary LIKE @subsidiary+'%'
       AND prod.kpi_type = 'SALE'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'SALE'
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'
        ,prod.product

UNION ALL
-- 03.��ǰ������(���ο���)
SELECT '03.��ǰ������' AS cat_cd
      ,sub.display_name AS sub
      ,prod.product AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
       LEFT JOIN
       m_opsmr_tb_sub_prod_mapping(nolock) prod
--       ON  a.subsidiary  = prod.subsidiary
       ON  a.prod        = prod.product
       AND prod.subsidiary LIKE @subsidiary+'%'
       AND prod.kpi_type = 'SALE'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'SALE'
GROUP BY sub.display_name
        ,'02.'+a.yyyymm
        ,prod.product

UNION ALL

-- 04.��������(���γⰣ)
SELECT '04.��������' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'COI'
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 04.��������(���ο���)
SELECT '04.��������' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'COI'
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL
-- 05.��ǰ����������(���γⰣ)
SELECT '05.��ǰ����������' AS cat_cd
      ,sub.display_name AS sub
      ,prod.product AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
       LEFT JOIN
       m_opsmr_tb_sub_prod_mapping(nolock) prod
--       ON  a.subsidiary  = prod.subsidiary
       ON  a.prod        = prod.product
       AND prod.subsidiary LIKE @subsidiary+'%'
       AND prod.kpi_type = 'COI'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'COI'
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'
        ,prod.product

UNION ALL
-- 05.��ǰ����������(���ο���)
SELECT '05.��ǰ����������' AS cat_cd
      ,sub.display_name AS sub
      ,prod.product AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
       LEFT JOIN
       m_opsmr_tb_sub_prod_mapping(nolock) prod
--       ON  a.subsidiary  = prod.subsidiary
       ON  a.prod        = prod.product
       AND prod.subsidiary LIKE @subsidiary+'%'
       AND prod.kpi_type = 'COI'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'COI'
GROUP BY sub.display_name
        ,'02.'+a.yyyymm
        ,prod.product

UNION ALL
-- 06.�����(���γⰣ)
SELECT '06.�����' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
AND    a.index1 = '1. Production Amount(K$)'
AND    a.product = 'Total'
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 06.�����(���ο���)
SELECT '06.�����' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
AND    a.index1 = '1. Production Amount(K$)'
AND    a.product = 'Total'
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL
-- 07.����������(���γⰣ)
SELECT '07.����������' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val
FROM   db_owner.m_costprod_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
and    a.division = 'DIVISION'
and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 07.����������(���ο���)
SELECT '07.����������' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val
FROM   db_owner.m_costprod_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
and    a.division = 'DIVISION'
and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL
-- 08.��ǰ������������(���γⰣ)
SELECT '08.��ǰ������������' AS cat_cd
      ,sub.display_name AS sub
      ,prod.product AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val
FROM   db_owner.m_costprod_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
       LEFT JOIN
       m_opsmr_tb_sub_prod_mapping(nolock) prod
--       ON  a.subsidiary  = prod.subsidiary
       ON  a.division    = prod.product
       AND prod.subsidiary LIKE @subsidiary+'%'
       AND prod.kpi_type = 'COST'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
--and    a.division = 'DIVISION'
and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'
        ,prod.product

UNION ALL
-- 08.��ǰ������������(���ο���)
SELECT '08.��ǰ������������' AS cat_cd
      ,sub.display_name AS sub
      ,prod.product AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val
FROM   db_owner.m_costprod_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
       LEFT JOIN
       m_opsmr_tb_sub_prod_mapping(nolock) prod
--       ON  a.subsidiary  = prod.subsidiary
       ON  a.division    = prod.product
       AND prod.subsidiary LIKE @subsidiary+'%'
       AND prod.kpi_type = 'COST'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
--and    a.division = 'DIVISION'
and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
GROUP BY sub.display_name
        ,'02.'+a.yyyymm
        ,prod.product

UNION ALL
-- 09.��������(���γⰣ)
SELECT '09.��������' AS cat_cd
      ,a.sub AS sub
      ,'' AS prod
      ,a.kpi_code AS kpi_code
      ,CASE WHEN SUM(A.val2) = 0 THEN 0
            ELSE SUM(A.val1) / SUM(A.val2) END AS val
FROM  (      
       SELECT '09.��������' AS cat_cd
             ,sub.display_name AS sub
             ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
       AND    a.index1 = '1. Production Amount(K$)'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
               ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'
       UNION ALL
       SELECT '09.��������' AS cat_cd
             ,sub.display_name AS sub
             ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
       AND    a.index1 = '4. L/C (K$)'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
               ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'
) A
GROUP BY a.sub
        ,a.kpi_code
UNION ALL
-- 09.��������(���ο���)
SELECT '09.��������' AS cat_cd
      ,a.sub AS sub
      ,'' AS prod
      ,a.kpi_code AS kpi_code
      ,CASE WHEN SUM(A.val2) = 0 THEN 0
            ELSE SUM(A.val1) / SUM(A.val2) END AS val
FROM  (      
       SELECT '09.��������' AS cat_cd
             ,sub.display_name AS sub
             ,'02.'+a.yyyymm AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_15 and @vc_post_3
       AND    a.index1 = '1. Production Amount(K$)'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
	           ,'02.'+a.yyyymm
       UNION ALL
       SELECT '09.��������' AS cat_cd
             ,sub.display_name AS sub
             ,'02.'+a.yyyymm AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_15 and @vc_post_3
       AND    a.index1 = '4. L/C (K$)'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
	           ,'02.'+a.yyyymm
) A
GROUP BY a.sub
        ,a.kpi_code

UNION ALL

-- 10.�ο�(���γⰣ)
SELECT '10.�ο�' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.product = 'Total'
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 10.�ο�(���ο���)
SELECT '10.�ο�' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.product = 'Total'
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL
-- 11.FSE(���γⰣ)
SELECT '11.FSE' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
AND    a.product = 'Total'
AND  ((a.index1 = '3. H/C' AND a.index2 = 'Executive')
OR    (a.index1 = '3. H/C' AND a.index2 = 'Sub-Total' AND a.index3 = 'FSE (non R&D)')) 
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 11.FSE(���ο���)
SELECT '11.FSE' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
AND    a.product = 'Total'
AND  ((a.index1 = '3. H/C' AND a.index2 = 'Executive')
OR    (a.index1 = '3. H/C' AND a.index2 = 'Sub-Total' AND a.index3 = 'FSE (non R&D)')) 
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL

-- 12.ISE(���γⰣ)
SELECT '12.ISE' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
AND    a.product = 'Total'
AND  ((a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Manufacturing')                   
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Quality'      )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Procurement'  )   
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Finance'      )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Others'       )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Temporary'    )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Manufacturing')                 
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Quality'      )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Procurement'  )   
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Finance'      )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Others'       )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Temporary'     ))
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 12.ISE(���ο���)
SELECT '12.ISE' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
AND    a.product = 'Total'
AND  ((a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Manufacturing')                   
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Quality'      )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Procurement'  )   
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Finance'      )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Others'       )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'Temporary'    )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Manufacturing')                 
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Quality'      )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Procurement'  )   
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Finance'      )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Others'       )
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'Temporary'     ))
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL
-- 13.�系����(���γⰣ)
SELECT '13.�系����' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
AND    a.product = 'Total'
AND  ((a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'O/S')                   
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'O/S'))
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 13.�系����(���ο���)
SELECT '13.�系����' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
AND    a.product = 'Total'
AND  ((a.index1 = '3. H/C' AND a.index2 = 'Staff'     AND a.index3 = 'O/S')                   
OR    (a.index1 = '3. H/C' AND a.index2 = 'Operator'  AND a.index3 = 'O/S'))
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL
-- 14.�ΰǺ���(���γⰣ)
SELECT '14.�ΰǺ���' AS cat_cd
      ,a.sub AS sub
      ,'' AS prod
      ,a.kpi_code AS kpi_code
      ,CASE WHEN SUM(A.val2) = 0 THEN 0
            ELSE SUM(A.val1) / SUM(A.val2) END AS val
FROM  (      
       SELECT '14.�ΰǺ���' AS cat_cd
             ,sub.display_name AS sub
             ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
       AND    a.product = 'Total'
       AND  ((a.index1 = '4. L/C (K$)' AND a.index2 = 'Total - Include O/S'                          )
       OR    (a.index1 = '4. L/C (K$)' AND a.index2 = 'Labor Cost' AND a.index3 = 'FSE (R&D)'        )
       OR    (a.index1 = '4. L/C (K$)' AND a.index2 = 'Labor Cost' AND a.index3 = 'R&D SW Labor Cost'))
       GROUP BY sub.display_name
               ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'
       UNION ALL
       SELECT '14.�ΰǺ���' AS cat_cd
             ,sub.display_name AS sub
             ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
       AND    a.index1 = '2. Sales(K$)'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
               ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'
) A
GROUP BY a.sub
        ,a.kpi_code
UNION ALL
-- 14.�ΰǺ���(���ο���)
SELECT '14.�ΰǺ���' AS cat_cd
      ,a.sub AS sub
      ,'' AS prod
      ,a.kpi_code AS kpi_code
      ,CASE WHEN SUM(A.val2) = 0 THEN 0
            ELSE SUM(A.val1) / SUM(A.val2) END AS val
FROM  (      
       SELECT '14.�ΰǺ���' AS cat_cd
             ,sub.display_name AS sub
             ,'02.'+a.yyyymm AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.product = 'Total'
       AND    a.yyyymm between @vc_pre_15 and @vc_post_3
       AND  ((a.index1 = '4. L/C (K$)' AND a.index2 = 'Total - Include O/S'                          )
       OR    (a.index1 = '4. L/C (K$)' AND a.index2 = 'Labor Cost' AND a.index3 = 'FSE (R&D)'        )
       OR    (a.index1 = '4. L/C (K$)' AND a.index2 = 'Labor Cost' AND a.index3 = 'R&D SW Labor Cost'))
       GROUP BY sub.display_name
	           ,'02.'+a.yyyymm
       UNION ALL
       SELECT '14.�ΰǺ���' AS cat_cd
             ,sub.display_name AS sub
             ,'02.'+a.yyyymm AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_15 and @vc_post_3
       AND    a.index1 = '2. Sales(K$)'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
	           ,'02.'+a.yyyymm
) A
GROUP BY a.sub
        ,a.kpi_code

UNION ALL
-- 15.OVERHEAD��(���γⰣ)
SELECT '15.OVERHEAD��' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val
FROM   dbo.m_oh_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
AND    a.index1 = 'V/F'
AND    a.index2 IN ('Net Sales','O/H Cost')
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 15.OVERHEAD��(���ο���)
SELECT '15.OVERHEAD��' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val
FROM   dbo.m_oh_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
AND    a.index1 = 'V/F'
AND    a.index2 IN ('Net Sales','O/H Cost')
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL
-- 16.��������ϼ�(���γⰣ)
SELECT '16.��������ϼ�' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyy,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy between @vc_pre_py_yyyy and substring(@base_yyyymm,1,4)
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '���� ���'
AND    a.inv_detail = '����ϼ�(DIO)'
AND    a.division = 'Division'
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyy,3,2)+'����'

UNION ALL
-- 16.��������ϼ�(���ο���)
SELECT '16.��������ϼ�' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyy+right('0'+a.mm,2) AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy+right('0'+a.mm,2) between @vc_pre_15 and @vc_post_3
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '���� ���'
AND    a.inv_detail = '����ϼ�(DIO)'
AND    a.division = 'Division'
GROUP BY sub.display_name
        ,'02.'+a.yyyy+right('0'+a.mm,2)

UNION ALL
-- 17.��������(���γⰣ)
SELECT '17.��������' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyy,3,2)+'����' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( 'â�����') THEN a.VALUE END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.inv_detail IN ( '������') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( 'â�����') THEN a.VALUE END) END AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy between @vc_pre_py_yyyy and substring(@base_yyyymm,1,4)
AND    a.division = 'Division'
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '�����'
AND    a.inv_detail IN ( '������','â�����')
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyy,3,2)+'����'

UNION ALL
-- 17.��������(���ο���)
SELECT '17.��������' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyy+right('0'+a.mm,2) AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( 'â�����') THEN a.VALUE END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.inv_detail IN ( '������') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( 'â�����') THEN a.VALUE END) END AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy+right('0'+a.mm,2) between @vc_pre_15 and @vc_post_3
AND    a.division = 'Division'
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '�����'
AND    a.inv_detail IN ( '������','â�����')
GROUP BY sub.display_name
        ,'02.'+a.yyyy+right('0'+a.mm,2)

UNION ALL
-- 18.����ҷ���(���γⰣ)
SELECT '18.����ҷ���' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_opsmr_ffr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @base_yyyymm
and    a.prod = 'Total'
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.yyyymm,3,2)+'����'

UNION ALL
-- 18.����ҷ���(���ο���)
SELECT '18.����ҷ���' AS cat_cd
      ,sub.display_name AS sub
      ,'' AS prod
      ,'02.'+a.yyyymm AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_opsmr_ffr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_15 and @vc_post_3
and    a.prod = 'Total'
GROUP BY sub.display_name
        ,'02.'+a.yyyymm

UNION ALL
-- 19.��ǰ��������(���γⰣ)
SELECT '19.��ǰ��������' AS cat_cd
      ,sub.display_name AS sub
      ,prod.product AS prod
      ,'01.'+SUBSTRING(a.kpi_period_code,3,2)+'����' AS kpi_code
      ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.factory_region1  = sub.mapping_code
       AND sub.use_flag = 'Y'
       LEFT JOIN
       m_opsmr_tb_sub_prod_mapping(nolock) prod
--       ON  a.factory_region1  = prod.subsidiary
       ON  a.gbu_name    = prod.product
       AND prod.subsidiary LIKE @subsidiary+'%'
       AND prod.kpi_type = 'RATE'
WHERE  a.base_yyyymm = @base_yyyymm
AND    a.factory_region1 LIKE @subsidiary+'%'
AND    a.kpi_period_code between @vc_pre_py_yyyy+'01' and @base_yyyymm
AND    a.kpi_period_code NOT LIKE '%TOT%'
AND    a.opsmr_type = 'STD'
GROUP BY sub.display_name
        ,'01.'+SUBSTRING(a.kpi_period_code,3,2)+'����'
        ,prod.product

UNION ALL
-- 19.��ǰ��������(���ο���)
SELECT '19.��ǰ��������' AS cat_cd
      ,sub.display_name AS sub
      ,prod.product AS prod
      ,'02.'+a.kpi_period_code AS kpi_code
      ,CASE WHEN SUM(a.production_capa) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.factory_region1  = sub.mapping_code
       AND sub.use_flag = 'Y'
       LEFT JOIN
       m_opsmr_tb_sub_prod_mapping(nolock) prod
--       ON  a.factory_region1  = prod.subsidiary
       ON  a.gbu_name    = prod.product
       AND prod.subsidiary LIKE @subsidiary+'%'
       AND prod.kpi_type = 'RATE'
WHERE  a.base_yyyymm = @base_yyyymm
AND    a.factory_region1 LIKE @subsidiary+'%'
AND    a.kpi_period_code between @vc_pre_15 and @vc_post_3
AND    a.kpi_period_code NOT LIKE '%TOT%'
AND    a.opsmr_type = 'STD'
GROUP BY sub.display_name
        ,'02.'+a.kpi_period_code
        ,prod.product
;

END