ALTER PROCEDURE [dbo].[m_opsmr_sp_graph_location]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
 ,@location      VARCHAR(30)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_graph_location
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_graph_location

--   EXEC m_opsmr_sp_graph_location 'STD', '201603', 'LOCAL'
--   EXEC m_opsmr_sp_graph_location 'STD', '201603', 'OVERSEA'
             
4. �� �� ȭ �� :

����    �� �� ��     ��        ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.12  �����ۼ�
1.1   shlee      2016.04.15  KPI_TYPE ���������� ��û�� ���� �߰�
1.2   shlee      2016.04.21  ��¥�� subsidiary/ Product Master����
1.3   shlee      2016.04.22  ��ȹ����
***************************************************************************/

DECLARE @vc_pre_13          AS VARCHAR(6);
DECLARE @vc_py_pre_13       AS VARCHAR(6);
DECLARE @vc_start_yyyymm    AS VARCHAR(6);
DECLARE @vc_py_start_yyyymm AS VARCHAR(6);

DECLARE @vc_post_3          AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13           = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ��13��
SET @vc_py_pre_13        = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@vc_pre_13 + '01')), 112);    -- ��13��
SET @vc_start_yyyymm     = SUBSTRING(@base_yyyymm,1,4)+'01';    -- ��������ۿ� @vc_start_yyyymm
SET @vc_py_start_yyyymm  = SUBSTRING(@vc_pre_13,1,4)+'01';    -- ��������ۿ� @vc_start_yyyymm

SET @vc_post_3           = CONVERT(VARCHAR(6), DATEADD(m,3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ��13��

BEGIN

-- �� ���� ��������
SELECT '01.������������' AS kpi_type
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
-- 13�����ְ�
SELECT '02.13�����ְ�' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'13�����ְ�' AS kpi
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
-- 01������ ���ؿ�����
SELECT '03.01������ ���ؿ�����' AS kpi_type
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
-- 13��������
SELECT '04.13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'13��������' AS kpi
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
-- ������ ��������� �������
SELECT '05.������ ��������� �������' AS kpi_type
      ,prod
      ,prod_enm
      ,prod_knm
	    ,'������ ��������� �������' AS kpi
	    ,sum(val1) - sum(val2) AS val
FROM (	  
      -- 01������ ���ؿ�����
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
      -- ����01������ ���ؿ�����
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
-- ����13��������
SELECT '051.������ؿ�����' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'������ؿ�����' AS kpi
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
-- ����13��������
SELECT '06.����13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'����13����' AS kpi
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
-- 13���� ������ rate
SELECT '07.13���� ������ rate' AS kpi_type
      ,prod
      ,prod_enm
      ,prod_knm
      ,'������ 13����' AS kpi
      ,sum(val1) - sum(val2) AS val
FROM  (      
       -- 13��������
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
       	     ,'13��������' AS kpi
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
       -- ����13��������
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
       	     ,'����13����' AS kpi
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
-- 01������ ���ؿ����� ����
SELECT '08.01������ ���ؿ����� ����' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'����' AS kpi
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
-- 01������ ���ؿ����� ���� ������
SELECT '09.01������ ���ؿ����� ���� ������' AS kpi_type
      ,prod
      ,prod_enm
      ,prod_knm
      ,'��������� ���������' AS kpi
      ,CASE WHEN sum(val1)-sum(val2) = 0 THEN 0
            ELSE sum(val2) / sum(val1)-sum(val2) END AS val
FROM  (            
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
        	    ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'����' AS kpi
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
       	     ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'����' AS kpi
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
-- 13��������
SELECT '10.13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'13��������' AS kpi
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
-- ����13��������
SELECT '11.����13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'����13��������' AS kpi
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
SELECT '12.����13��������' AS kpi_type
      ,prod
      ,prod_enm
      ,prod_knm
      ,'������ 13��������' AS kpi
      ,sum(val1) - sum(val2) AS val
FROM  (
       -- 13��������
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
       -- ����13��������
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
-- �ֿ���ǰ ���ؿ� ���ذ�����
SELECT '13.�ֿ���ǰ ���ؿ� ���ذ�����' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'�ֿ���ǰ ���ؿ� ���ذ�����' AS kpi
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
-- �ֿ���ǰ ���ؿ� ���ذ�����
SELECT '14.�ֿ���ǰ ���ؿ� �������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'�ֿ���ǰ ���ؿ� �������' AS kpi
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
-- �������� ���ذ�����
SELECT '15.�������� ���ذ�����' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'�������� ���' AS kpi
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
-- 13��������
SELECT '16.�������� 13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'�������� 13��������' AS kpi
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