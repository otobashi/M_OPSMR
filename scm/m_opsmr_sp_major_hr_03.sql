ALTER PROCEDURE [dbo].[m_opsmr_sp_major_hr_03]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
 ,@subsidiary    VARCHAR(30)
 ,@product       VARCHAR(30)
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_major_hr_03
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_major_hr_03

--   EXEC m_opsmr_sp_major_hr_03 'STD', '201603', 'LGEAT', 'RAC'
--   EXEC m_opsmr_sp_major_hr_03 'STD', '201603', 'Total(AT포함)', 'Total'

4. 관 련 화 면 :

버전    작 성 자     일        자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.18  최초작성
***************************************************************************/

DECLARE @vc_pre_13          AS VARCHAR(6);
DECLARE @vc_py_pre_13       AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13           = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전13월
SET @vc_py_pre_13        = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@vc_pre_13 + '01')), 112);    -- 전13월

BEGIN

-- 01.생산액(백만불)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'01.생산액(백만불)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
      ,CASE WHEN MIN(b.col) = '1' THEN SUM(a.value)*0.001
            WHEN MIN(b.col) = '2' THEN SUM(a.value)*0.001 END AS val
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
AND    prod.sheet19_yn = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
AND    a.product <> 'Total'
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END
UNION ALL

-- 02.총인원(사내도급제외)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'02.총인원(사내도급제외)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
      ,CASE WHEN MIN(b.col) = '1' THEN SUM(a.value)
            WHEN MIN(b.col) = '2' THEN SUM(a.value)/12 END AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '3. H/C'
AND    a.index2 = 'Total - Exclude O/S'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.sheet19_yn = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
AND    a.product <> 'Total'
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END
UNION ALL
-- 03.총인원(사내도급포함)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'03.총인원(사내도급포함)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
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
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.sheet19_yn = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
AND    a.product <> 'Total'
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END
UNION ALL
-- 04.인건비(사내도급제외)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'04.인건비(사내도급제외)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
      ,SUM(a.value)*0.001 AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '4. L/C (K$)'
AND    a.index2 = 'Total - Exclude O/S'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.sheet19_yn = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
AND    a.product <> 'Total'
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END
UNION ALL
-- 05.인건비(사내도급포함)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'05.인건비(사내도급포함)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
      ,SUM(a.value)*0.001 AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '4. L/C (K$)'
AND    a.index2 = 'Total - Include O/S'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.sheet19_yn = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
AND    a.product <> 'Total'
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END

UNION ALL
-- 06.인당생산액(천불)
SELECT a.display_name as display_name
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
      ,'06.인당생산액(천불)' AS kpi_type
      ,a.kpi_code
      ,CASE WHEN SUM(val2) = 0 THEN 0
            ELSE SUM(val1) / SUM(val2) END * 1000 AS val
FROM  (

       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN b.col = '1' THEN a.yyyymm
                   WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
             ,CASE WHEN MIN(b.col) = '1' THEN SUM(a.value)*0.001
                   WHEN MIN(b.col) = '2' THEN SUM(a.value)*0.001 END AS val1
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
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN b.col = '1' THEN a.yyyymm
                   WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
             ,0 AS val1
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
       AND    a.subsidiary = @subsidiary
       AND    a.product    = @product
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END) a
GROUP BY a.display_name
        ,a.kpi_code             

UNION ALL
-- 07.원당생산액(불)
SELECT a.display_name as display_name
      ,MIN(a.prod_enm) as prod_enm
      ,MIN(a.prod_knm) as prod_knm
      ,'07.원당생산액(불)' AS kpi_type
      ,a.kpi_code
      ,CASE WHEN SUM(val2) = 0 THEN 0
            ELSE SUM(val1) / SUM(val2) END AS val
FROM  (SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN b.col = '1' THEN a.yyyymm
                   WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
             ,CASE WHEN MIN(b.col) = '1' THEN SUM(a.value)*0.001
                   WHEN MIN(b.col) = '2' THEN SUM(a.value)*0.001 END AS val1
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
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END
       UNION ALL
       SELECT prod.display_name as display_name
             ,MIN(prod.display_enm) as prod_enm
             ,MIN(prod.display_knm) as prod_knm
             ,CASE WHEN b.col = '1' THEN a.yyyymm
                   WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
             ,0 AS val1
             ,SUM(a.value)*0.001 AS val2
--             ,SUM(a.value) AS val2
       FROM   M_OPSMR_HR(NOLOCK) a
             ,(SELECT '1' AS col
               UNION ALL
               SELECT '2') b
             ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
             ,m_opsmr_hr_mst(nolock) hr
       WHERE  a.index1 = '4. L/C (K$)'
       AND    a.index2 = 'Total - Include O/S' 
       AND    a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary = @subsidiary
       AND    a.product    = @product
       AND    a.product = hr.org_code
       AND    prod.sheet19_yn = 'Y'
       AND    hr.gbu_code = prod.mapping_code
       AND    hr.gbu_code IS NOT NULL
       AND    a.product <> 'Total'
       GROUP BY prod.display_name
               ,CASE WHEN b.col = '1' THEN a.yyyymm
                     WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END) a
GROUP BY a.display_name
        ,a.kpi_code             
UNION ALL
-- 08.매출액(백만불)
SELECT prod.display_name as display_name
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,'08.매출액(백만불)' AS kpi_type
      ,CASE WHEN b.col = '1' THEN a.yyyymm
            WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END AS kpi_code
      ,SUM(a.value)*0.001 AS val
FROM   M_OPSMR_HR(NOLOCK) a
      ,(SELECT '1' AS col
        UNION ALL
        SELECT '2') b
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      ,m_opsmr_hr_mst(nolock) hr
WHERE  a.index1 = '2. Sales(K$)'
AND    a.std_yyyymm = @base_yyyymm
AND    a.subsidiary = @subsidiary
AND    a.product    = @product
AND    a.product = hr.org_code
AND    prod.sheet19_yn = 'Y'
AND    hr.gbu_code = prod.mapping_code
AND    hr.gbu_code IS NOT NULL
AND    a.product <> 'Total'
GROUP BY prod.display_name
        ,CASE WHEN b.col = '1' THEN a.yyyymm
              WHEN b.col = '2' THEN SUBSTRING(a.yyyymm,3,2)+' 연간' END


;



END