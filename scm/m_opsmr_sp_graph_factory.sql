ALTER PROCEDURE [dbo].[m_opsmr_sp_graph_factory]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
 ,@display_name  VARCHAR(30)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_graph_factory
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_graph_factory

--   EXEC m_opsmr_sp_graph_factory 'STD', '201603', 'LOCAL'
--   EXEC m_opsmr_sp_graph_factory 'STD', '201603', 'OVERSEA'

4. �� �� ȭ �� :

����    �� �� ��     ��        ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.12  �����ۼ�
1.1   shlee      2016.04.15  KPI_TYPE ���������� ��û�� ���� �߰�
1.2   shlee      2016.04.21  ��¥�� subsidiary/ Product Master����
1.3   shlee      2016.04.22  ��ȹ����
1.4   shlee      2016.04.25  �������� ����
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
--      ,sum(a.standard_operation_rate) AS val
      ,CASE WHEN isnull(SUM(a.production_capa),0) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) end AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @vc_post_3
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name
        ,kpi_period_code

UNION ALL
-- 13�����ְ�
SELECT '02.13�����ְ�' AS kpi_type
      ,a.prod AS prod
      ,MIN(a.prod_enm) AS prod_enm
      ,MIN(a.prod_knm) AS prod_knm
      ,'13�����ְ�' AS kpi
      ,MAX(a.val) AS val
FROM  (
       SELECT '01.������������' AS kpi_type
             ,prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,kpi_period_code
       --      ,sum(a.standard_operation_rate) AS val
             ,CASE WHEN isnull(SUM(a.production_capa),0) = 0 THEN 0
                   ELSE SUM(a.production_quantity) / SUM(a.production_capa) end AS val
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet18_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
       GROUP BY prod.display_name
               ,kpi_period_code
      ) a
GROUP BY a.prod

UNION ALL
-- 01������ ���ؿ�����
SELECT '03.01������ ���ؿ�����' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2) AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name

UNION ALL
-- 13��������
SELECT '04.13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'13��������' AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name

UNION ALL
-- ������ ��������� �������
SELECT '05.������ ��������� �������' AS kpi_type
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'������ ��������� �������' AS kpi
      ,sum(a.val1) - sum(a.val2) AS val
FROM (
      -- 01������ ���ؿ�����
      SELECT prod.display_name AS prod
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
            ,sum(a.production_quantity) AS val1
            ,0 AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  a.opsmr_type = @opsmr_type
      AND    a.base_yyyymm = @base_yyyymm
      AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
      AND    a.gbu_code = prod.mapping_code
      AND    prod.sheet18_yn = 'Y'
      AND    a.factory_region1 <> 'CROSS(KR)'
      AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
      GROUP BY prod.display_name

      UNION ALL
      -- ����01������ ���ؿ�����
      SELECT prod.display_name AS prod
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
            ,0 AS val1
            ,sum(a.production_quantity) AS val2
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  a.opsmr_type = @opsmr_type
      AND    a.base_yyyymm = @base_yyyymm
      AND    a.kpi_period_code BETWEEN @vc_py_start_yyyymm AND @vc_pre_13
      AND    a.gbu_code = prod.mapping_code
      AND    prod.sheet18_yn = 'Y'
      AND    a.factory_region1 <> 'CROSS(KR)'
      AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
      GROUP BY prod.display_name

     ) a
GROUP BY a.prod
        ,a.prod_enm
        ,a.prod_knm

UNION ALL
-- ����13��������
SELECT '051.������ؿ�����' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'������ؿ�����' AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_py_start_yyyymm AND @vc_pre_13
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name

UNION ALL
-- ����13��������
SELECT '06.����13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'����13����' AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name

UNION ALL
-- 13���� ������ rate
SELECT '07.13���� ������ rate' AS kpi_type
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'������ 13����' AS kpi
      ,sum(a.val1) - sum(a.val2) AS val
FROM  (
       -- 13��������
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,'13��������' AS kpi
             ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
                   ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val1
             ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet18_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
       GROUP BY prod.display_name
       UNION ALL
       -- ����13��������
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,'����13����' AS kpi
             ,0 AS val1
             ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
                   ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet18_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
       GROUP BY prod.display_name
      ) a
GROUP BY a.prod
        ,a.prod_enm
        ,a.prod_knm

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
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name

UNION ALL

--
SELECT '09.01������ ���ؿ����� ���� ������' AS kpi_type
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'��������� ���������' AS kpi
      ,CASE WHEN isnull( sum(a.val2),0) - ISNULL(sum(a.val1),0 ) = 0 THEN 0
            ELSE sum(a.val1) / (isnull( sum(a.val2),0) - ISNULL(sum(a.val1),0 )) END AS val
FROM  (
        SELECT '05.������ ��������� �������' AS kpi_type
              ,a.prod
              ,a.prod_enm
              ,a.prod_knm
              ,'������ ��������� �������' AS kpi
              ,sum(a.val1) - sum(a.val2) AS val1
              ,0 AS val2
        FROM (
              -- 01������ ���ؿ�����
              SELECT prod.display_name AS prod
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,sum(a.production_quantity) AS val1
                    ,0 AS val2
              FROM   m_opsmr_tb_op_rate(nolock) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
              WHERE  a.opsmr_type = @opsmr_type
              AND    a.base_yyyymm = @base_yyyymm
              AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
              AND    a.gbu_code = prod.mapping_code
              AND    prod.sheet18_yn = 'Y'
              AND    a.factory_region1 <> 'CROSS(KR)'
              AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
              GROUP BY prod.display_name
        
              UNION ALL
              -- ����01������ ���ؿ�����
              SELECT prod.display_name AS prod
                    ,MIN(prod.display_enm) as prod_enm
                    ,MIN(prod.display_knm) as prod_knm
                    ,0 AS val1
                    ,sum(a.production_quantity) AS val2
              FROM   m_opsmr_tb_op_rate(nolock) a
                    ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
              WHERE  a.opsmr_type = @opsmr_type
              AND    a.base_yyyymm = @base_yyyymm
              AND    a.kpi_period_code BETWEEN @vc_py_start_yyyymm AND @vc_pre_13
              AND    a.gbu_code = prod.mapping_code
              AND    prod.sheet18_yn = 'Y'
              AND    a.factory_region1 <> 'CROSS(KR)'
              AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
              GROUP BY prod.display_name
        
             ) a
        GROUP BY a.prod
                ,a.prod_enm
                ,a.prod_knm
        UNION ALL
        -- 01������ ���ؿ����� ����
        SELECT '08.01������ ���ؿ����� ����' AS kpi_type
              ,prod.display_name AS prod
              ,MIN(prod.display_enm) as prod_enm
              ,MIN(prod.display_knm) as prod_knm
              ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'����' AS kpi
              ,0 AS val1
              ,sum(production_quantity) AS val2
        FROM   m_opsmr_tb_op_rate(nolock) a
              ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
        WHERE  a.opsmr_type = @opsmr_type
        AND    a.base_yyyymm = @base_yyyymm
        AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
        AND    a.gbu_code = prod.mapping_code
        AND    prod.sheet18_yn = 'Y'
        AND    a.factory_region1 <> 'CROSS(KR)'
        AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
        GROUP BY prod.display_name
      ) a
GROUP BY a.prod
        ,a.prod_enm
        ,a.prod_knm
/*
-- 01������ ���ؿ����� ���� ������
SELECT '09.01������ ���ؿ����� ���� ������' AS kpi_type
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'��������� ���������' AS kpi
      ,CASE WHEN isnull( sum(a.val1),0) - ISNULL(sum(a.val2),0 ) = 0 THEN 0
            ELSE sum(a.val2) / (isnull( sum(a.val1),0) - ISNULL(sum(a.val2),0 )) END AS val
FROM  (
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'����' AS kpi
             ,sum(a.production_quantity) AS val1
             ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_py_start_yyyymm AND @vc_pre_13
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet18_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUBSTRING(@vc_start_yyyymm,5,2)+'~'+SUBSTRING(@base_yyyymm,5,2)+'����' AS kpi
             ,0 AS val1
             ,sum(a.production_quantity) AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet18_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       GROUP BY prod.display_name
      ) a
GROUP BY a.prod
        ,a.prod_enm
        ,a.prod_knm

*/
UNION ALL
-- 13��������
SELECT '10.13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'13��������' AS kpi
      ,sum(a.production_quantity)/1000 AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
--AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name

UNION ALL
-- ����13��������
SELECT '11.����13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'����13��������' AS kpi
      ,sum(production_quantity)/1000 AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name

UNION ALL
SELECT '12.����13��������' AS kpi_type
      ,a.prod
      ,a.prod_enm
      ,a.prod_knm
      ,'������ 13��������' AS kpi
      ,sum(a.val1) - sum(a.val2) AS val
FROM  (
       -- 13��������
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,sum(a.production_quantity)/1000 AS val1
             ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.base_yyyymm = @base_yyyymm
       --AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet18_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
       GROUP BY prod.display_name

       UNION ALL
       -- ����13��������
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
             ,sum(A.production_quantity)/1000 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = @opsmr_type
       AND    a.kpi_period_code BETWEEN @vc_py_pre_13 AND @vc_pre_13
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet18_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
       GROUP BY prod.display_name
      ) a
GROUP BY a.prod
        ,a.prod_enm
        ,a.prod_knm

UNION ALL
-- �ֿ���ǰ ���ؿ� ���ذ�����
SELECT '13.�ֿ���ǰ ���ؿ� ���ذ�����' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'�ֿ���ǰ ���ؿ� ���ذ�����' AS kpi
--      ,sum(a.standard_operation_rate) AS val
      ,CASE WHEN isnull(SUM(a.production_capa),0) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) end AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code = @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name
/*
UNION ALL
-- �ֿ���ǰ ���ؿ� �������
SELECT '14.�ֿ���ǰ ���ؿ� �������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'�ֿ���ǰ ���ؿ� �������' AS kpi
--      ,sum(a.actual_operation_rate) AS val
      ,CASE WHEN isnull(SUM(a.actual_production_capa),0) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.actual_production_capa) end AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = 'PROD'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code = @base_yyyymm
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 <> 'CROSS(KR)'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name
*/
UNION ALL
-- �ֿ���ǰ ���ؿ� �������
SELECT '14.�ֿ���ǰ ���ؿ� �������' AS kpi_type
      ,prod AS prod
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
      ,'�ֿ���ǰ ���ؿ� �������' AS kpi
      ,CASE WHEN isnull(SUM(a.val2),0) = 0 THEN 0
            ELSE SUM(a.val1) / SUM(a.val2) end AS val
FROM  (
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,SUM(a.production_quantity) AS val1
             ,0 AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = 'STD'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet18_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
       GROUP BY prod.display_name
       UNION ALL
       SELECT prod.display_name AS prod
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,0 AS val1
             ,SUM(a.actual_production_capa) AS val2
       FROM   m_opsmr_tb_op_rate(nolock) a
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
       WHERE  a.opsmr_type = 'PROD'
       AND    a.base_yyyymm = @base_yyyymm
       AND    a.kpi_period_code = @base_yyyymm
       AND    a.gbu_code = prod.mapping_code
       AND    prod.sheet18_yn = 'Y'
       AND    a.factory_region1 <> 'CROSS(KR)'
       AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
       GROUP BY prod.display_name
      ) A
GROUP BY prod

UNION ALL
-- 13��������
SELECT '15.�������� 13��������' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'�������� 13��������' AS kpi
      ,CASE WHEN isnull(sum(a.production_capa),0) = 0 THEN 0
            ELSE sum(a.production_quantity) / sum(a.production_capa) END AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
--AND    kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.factory_region1 = 'CROSS(KR)'
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name

UNION ALL
-- �������� ���ذ�����
SELECT '16.�������� ���ذ�����' AS kpi_type
      ,prod.display_name AS prod
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'�������� ���' AS kpi
--      ,sum(a.standard_operation_rate) AS val
      ,CASE WHEN isnull(SUM(a.production_capa),0) = 0 THEN 0
            ELSE SUM(a.production_quantity) / SUM(a.production_capa) end AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code = @base_yyyymm
AND    a.factory_region1 = 'CROSS(KR)'
AND    a.gbu_code = prod.mapping_code
AND    prod.sheet18_yn = 'Y'
AND    a.factory_region1 IN (SELECT mapping_code FROM m_opsmr_tb_op_rate_sub_mst(nolock) WHERE display_name = @display_name)
GROUP BY prod.display_name

;



END