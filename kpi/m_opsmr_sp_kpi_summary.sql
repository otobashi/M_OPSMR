ALTER PROCEDURE [dbo].[m_opsmr_sp_kpi_summary]
(
  @base_yyyymm  VARCHAR(6)
 ,@subsidiary   VARCHAR(6)
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_kpi_summary
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_kpi_summary

--   EXEC m_opsmr_sp_kpi_summary '201603', 'LGEAK'

4. 관 련 화 면 :

버전  작 성 자   일      자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.05.09  최초작성
***************************************************************************/

DECLARE @vc_pre_yyyy        AS VARCHAR(4);
DECLARE @vc_pre_py_yyyy     AS VARCHAR(4);

DECLARE @vc_start_yyyymm    AS VARCHAR(6);
DECLARE @vc_py_start_yyyymm AS VARCHAR(6);
DECLARE @vc_py_end_yyyymm   AS VARCHAR(6);

DECLARE @vc_post_1          AS VARCHAR(6);
DECLARE @vc_post_3          AS VARCHAR(6);
DECLARE @vc_py_post_1       AS VARCHAR(6);
DECLARE @vc_py_post_3       AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_yyyy         = CONVERT(VARCHAR(4), DATEADD(yy, -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전년
SET @vc_pre_py_yyyy      = CONVERT(VARCHAR(4), DATEADD(yy, -2, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전전년

SET @vc_start_yyyymm     = SUBSTRING(@base_yyyymm,1,4)+'01';
SET @vc_py_start_yyyymm  = @vc_pre_yyyy+'01'; -- 전년누적시작월
SET @vc_py_end_yyyymm    = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2); -- 전년누적종료월

SET @vc_post_1           = CONVERT(VARCHAR(6), DATEADD(m,   1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직후1개월
SET @vc_post_3           = CONVERT(VARCHAR(6), DATEADD(m,   3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직후3개월

SET @vc_py_post_1        = @vc_pre_yyyy+SUBSTRING(@vc_post_1,5,2); -- 전년직후3개월시작월
SET @vc_py_post_3        = @vc_pre_yyyy+SUBSTRING(@vc_post_3,5,2); -- 전년직후3개월종료월

BEGIN

-- 01.매출(전전년)
SELECT 'A01' AS seq
      ,'01.매출' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'SALE'
GROUP BY sub.display_name

UNION ALL
-- 01.매출(전년)
SELECT 'A02' AS seq
      ,'01.매출' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'SALE'
GROUP BY sub.display_name

UNION ALL
-- 01.매출(전전년대비)
SELECT 'A03' AS seq
      ,'01.매출' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 01.매출(전전년)
        SELECT '01.매출' AS cat_cd
      ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'SALE'
        GROUP BY sub.display_name

        UNION ALL
        -- 01.매출(전년)
        SELECT '01.매출' AS cat_cd
      ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'SALE'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 01.매출
SELECT 'A04' AS seq
      ,'01.매출' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm = @base_yyyymm
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'SALE'
GROUP BY sub.display_name

UNION ALL
-- 01.매출
SELECT 'A05' AS seq
      ,'01.매출' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 01.매출(전전년)
        SELECT '01.매출' AS cat_cd
      ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2)
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'SALE'
        GROUP BY sub.display_name

        UNION ALL
        -- 01.매출(전년)
        SELECT '01.매출' AS cat_cd
      ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @base_yyyymm
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'SALE'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 01.매출(누계)
SELECT 'A06' AS seq
      ,'01.매출' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'SALE'
GROUP BY sub.display_name

UNION ALL
-- 01.매출
SELECT 'A07' AS seq
      ,'01.매출' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 01.매출(전전년)
        SELECT '01.매출' AS cat_cd
      ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_start_yyyymm and @vc_py_end_yyyymm
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'SALE'
        GROUP BY sub.display_name

        UNION ALL
        -- 01.매출(전년)
        SELECT '01.매출' AS cat_cd
      ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'SALE'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 01.매출(M/L)
SELECT 'A08' AS seq
      ,'01.매출' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_post_1 and @vc_post_3
and    a.scenario_type <> 'AC0'
and    a.kpi_code = 'SALE'
GROUP BY sub.display_name


UNION ALL
-- 01.매출
SELECT 'A09' AS seq
      ,'01.매출' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 01.매출(전전년)
        SELECT '01.매출' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_post_1 and @vc_py_post_3
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'SALE'
        GROUP BY sub.display_name

        UNION ALL
        -- 01.매출(전년)
        SELECT '01.매출' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_post_1 and @vc_post_3
        and    a.scenario_type <> 'AC0'
        and    a.kpi_code = 'SALE'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL

-- 02.영업이익(전전년)
SELECT 'B01' AS seq
      ,'02.영업이익' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'COI'
GROUP BY sub.display_name

UNION ALL
-- 02.영업이익(전년)
SELECT 'B02' AS seq
      ,'02.영업이익' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'COI'
GROUP BY sub.display_name

UNION ALL
-- 02.영업이익(전전년대비)
SELECT 'B03' AS seq
      ,'02.영업이익' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 02.영업이익(전전년)
        SELECT '02.영업이익' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'COI'
        GROUP BY sub.display_name

        UNION ALL
        -- 02.영업이익(전년)
        SELECT '02.영업이익' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'COI'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 02.영업이익
SELECT 'B04' AS seq
      ,'02.영업이익' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm = @base_yyyymm
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'COI'
GROUP BY sub.display_name

UNION ALL
-- 02.영업이익
SELECT 'B05' AS seq
      ,'02.영업이익' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 02.영업이익(전전년)
        SELECT '02.영업이익' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2)
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'COI'
        GROUP BY sub.display_name

        UNION ALL
        -- 02.영업이익(전년)
        SELECT '02.영업이익' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @base_yyyymm
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'COI'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 02.영업이익(누계)
SELECT 'B06' AS seq
      ,'02.영업이익' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
and    a.scenario_type = 'AC0'
and    a.kpi_code = 'COI'
GROUP BY sub.display_name

UNION ALL
-- 02.영업이익
SELECT 'B07' AS seq
      ,'02.영업이익' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 02.영업이익(전전년)
        SELECT '02.영업이익' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_start_yyyymm and @vc_py_end_yyyymm
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'COI'
        GROUP BY sub.display_name

        UNION ALL
        -- 02.영업이익(전년)
        SELECT '02.영업이익' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'COI'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 02.영업이익(M/L)
SELECT 'B08' AS seq
      ,'02.영업이익' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_salecoi(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_post_1 and @vc_post_3
and    a.scenario_type <> 'AC0'
and    a.kpi_code = 'COI'
GROUP BY sub.display_name


UNION ALL
-- 02.영업이익
SELECT 'B09' AS seq
      ,'02.영업이익' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 02.영업이익(전전년)
        SELECT '02.영업이익' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_post_1 and @vc_py_post_3
        and    a.scenario_type = 'AC0'
        and    a.kpi_code = 'COI'
        GROUP BY sub.display_name

        UNION ALL
        -- 02.영업이익(전년)
        SELECT '02.영업이익' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_salecoi(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_post_1 and @vc_post_3
        and    a.scenario_type <> 'AC0'
        and    a.kpi_code = 'COI'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL

-- 03.생산액(전전년)
SELECT 'C01' AS seq
      ,'03.생산액' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
AND    a.index1 = '1. Production Amount(K$)'
AND    a.product = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 03.생산액(전년)
SELECT 'C02' AS seq
      ,'03.생산액' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
AND    a.index1 = '1. Production Amount(K$)'
AND    a.product = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 03.생산액(전전년대비)
SELECT 'C03' AS seq
      ,'03.생산액' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 03.생산액(전전년)
        SELECT '03.생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
        AND    a.index1 = '1. Production Amount(K$)'
        AND    a.product = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 03.생산액(전년)
        SELECT '03.생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
        AND    a.index1 = '1. Production Amount(K$)'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 03.생산액
SELECT 'C04' AS seq
      ,'03.생산액' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm = @base_yyyymm
AND    a.index1 = '1. Production Amount(K$)'
AND    a.product = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 03.생산액
SELECT 'C05' AS seq
      ,'03.생산액' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 03.생산액(전전년)
        SELECT '03.생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2)
        AND    a.index1 = '1. Production Amount(K$)'
        AND    a.product = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 03.생산액(전년)
        SELECT '03.생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @base_yyyymm
        AND    a.index1 = '1. Production Amount(K$)'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 03.생산액(누계)
SELECT 'C06' AS seq
      ,'03.생산액' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
AND    a.index1 = '1. Production Amount(K$)'
AND    a.product = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 03.생산액
SELECT 'C07' AS seq
      ,'03.생산액' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 03.생산액(전전년)
        SELECT '03.생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_start_yyyymm and @vc_py_end_yyyymm
        AND    a.index1 = '1. Production Amount(K$)'
        AND    a.product = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 03.생산액(전년)
        SELECT '03.생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
        AND    a.index1 = '1. Production Amount(K$)'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 03.생산액(M/L)
SELECT 'C08' AS seq
      ,'03.생산액' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_post_1 and @vc_post_3
AND    a.index1 = '1. Production Amount(K$)'
AND    a.product = 'Total'
GROUP BY sub.display_name


UNION ALL
-- 03.생산액
SELECT 'C09' AS seq
      ,'03.생산액' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 03.생산액(전전년)
        SELECT '03.생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_post_1 and @vc_py_post_3
        AND    a.index1 = '1. Production Amount(K$)'
        AND    a.product = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 03.생산액(전년)
        SELECT '03.생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_post_1 and @vc_post_3
        AND    a.index1 = '1. Production Amount(K$)'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub


UNION ALL

-- 04.제조원가율(전전년)
SELECT 'D01' AS seq
      ,'04.제조원가율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val
FROM   db_owner.m_costprod_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
and    a.division = 'DIVISION'
and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
GROUP BY sub.display_name

UNION ALL
-- 04.제조원가율(전년)
SELECT 'D02' AS seq
      ,'04.제조원가율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val
FROM   db_owner.m_costprod_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
and    a.division = 'DIVISION'
and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
GROUP BY sub.display_name

UNION ALL
-- 04.제조원가율(전전년대비)
SELECT 'D03' AS seq
      ,'04.제조원가율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 04.제조원가율(전전년)
        SELECT '04.제조원가율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val1
              ,0 AS val2
        FROM   db_owner.m_costprod_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
        and    a.division = 'DIVISION'
        and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
        GROUP BY sub.display_name

        UNION ALL
        -- 04.제조원가율(전년)
        SELECT '04.제조원가율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val2
        FROM   db_owner.m_costprod_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
        and    a.division = 'DIVISION'
        and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 04.제조원가율
SELECT 'D04' AS seq
      ,'04.제조원가율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val
FROM   db_owner.m_costprod_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm = @base_yyyymm
and    a.division = 'DIVISION'
and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
GROUP BY sub.display_name

UNION ALL
-- 04.제조원가율
SELECT 'D05' AS seq
      ,'04.제조원가율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 04.제조원가율(전전년)
        SELECT '04.제조원가율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val1
              ,0 AS val2
        FROM   db_owner.m_costprod_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2)
        and    a.division = 'DIVISION'
        and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
        GROUP BY sub.display_name

        UNION ALL
        -- 04.제조원가율(전년)
        SELECT '04.제조원가율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
       		          ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val2
        FROM   db_owner.m_costprod_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @base_yyyymm
        and    a.division = 'DIVISION'
        and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 04.제조원가율(누계)
SELECT 'D06' AS seq
      ,'04.제조원가율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val
FROM   db_owner.m_costprod_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
and    a.division = 'DIVISION'
and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
GROUP BY sub.display_name

UNION ALL
-- 04.제조원가율
SELECT 'D07' AS seq
      ,'04.제조원가율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 04.제조원가율(전전년)
        SELECT '04.제조원가율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
   		              ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val1
              ,0 AS val2
        FROM   db_owner.m_costprod_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_start_yyyymm and @vc_py_end_yyyymm
        and    a.division = 'DIVISION'
        and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
        GROUP BY sub.display_name

        UNION ALL
        -- 04.제조원가율(전년)
        SELECT '04.제조원가율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val2
        FROM   db_owner.m_costprod_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
        and    a.division = 'DIVISION'
        and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 04.제조원가율(M/L)
SELECT 'D08' AS seq
      ,'04.제조원가율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val
FROM   db_owner.m_costprod_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_post_1 and @vc_post_3
and    a.division = 'DIVISION'
and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
GROUP BY sub.display_name


UNION ALL
-- 04.제조원가율
SELECT 'D09' AS seq
      ,'04.제조원가율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 04.제조원가율(전전년)
        SELECT '04.제조원가율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val1
              ,0 AS val2
        FROM   db_owner.m_costprod_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_post_1 and @vc_py_post_3
        and    a.division = 'DIVISION'
        and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
        GROUP BY sub.display_name

        UNION ALL
        -- 04.제조원가율(전년)
        SELECT '04.제조원가율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)') THEN a.VALUE END) / SUM(CASE WHEN a.[INDEX] IN ('NET AMOUNT OF PRODUCTION(GPU) (703000MS)') THEN a.VALUE END) END AS val2
        FROM   db_owner.m_costprod_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_post_1 and @vc_post_3
        and    a.division = 'DIVISION'
        and    a.[INDEX] IN ('Raw Materials Cost (71000000)','Labor Cost (72000000)','Manuf Exp (73000000)','NET AMOUNT OF PRODUCTION(GPU) (703000MS)')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL

-- 05.원당생산액(전전년)
SELECT 'E01' AS seq
      ,'05.원당생산액' AS cat_cd
      ,A.sub AS sub
      ,MIN(A.sub_enm) as sub_enm
      ,MIN(A.sub_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,CASE WHEN SUM(A.val2) = 0 THEN 0
            ELSE SUM(A.val1) / SUM(A.val2) END AS val
FROM  (      
       SELECT '05.원당생산액' AS cat_cd
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
       AND    a.index1 = '1. Production Amount(K$)'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
       UNION ALL
       SELECT '05.원당생산액' AS cat_cd
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
       AND    a.index1 = '4. L/C (K$)'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
) A
GROUP BY a.sub

UNION ALL
-- 05.원당생산액(전년)
SELECT 'E02' AS seq
      ,'05.원당생산액' AS cat_cd
      ,A.sub AS sub
      ,MIN(A.sub_enm) as sub_enm
      ,MIN(a.sub_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,CASE WHEN SUM(A.val2) = 0 THEN 0
            ELSE SUM(A.val1) / SUM(A.val2) END AS val
FROM (
       SELECT '05.원당생산액' AS cat_cd
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
       AND    a.index1 = '1. Production Amount(K$)'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
       
       UNION ALL
       SELECT '05.원당생산액' AS cat_cd
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
       AND    a.index1 = '4. L/C (K$)'
       
       AND    a.index2 = 'Total - Include O/S'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
      ) A
GROUP BY A.sub

UNION ALL
-- 05.원당생산액(전전년대비)
SELECT 'E03' AS seq
      ,'05.원당생산액' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 05.원당생산액(전전년)
        SELECT '05.원당생산액' AS cat_cd
              ,A.sub AS sub
              ,MIN(A.sub_enm) as sub_enm
              ,MIN(A.sub_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(A.val2) = 0 THEN 0
                    ELSE SUM(A.val1) / SUM(A.val2) END AS val1
              ,0 AS val2
        FROM (        
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
                     ,SUM(a.value) AS val1
                     ,0 AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
               AND    a.index1 = '1. Production Amount(K$)'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
               
               UNION ALL
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
                     ,0 AS val1
                     ,SUM(a.value) AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
               AND    a.index1 = '4. L/C (K$)'
               AND    a.index2 = 'Total - Include O/S'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
              ) A
        GROUP BY A.sub

        UNION ALL

        SELECT '05.원당생산액' AS cat_cd
              ,A.sub AS sub
              ,MIN(A.sub_enm) as sub_enm
              ,MIN(A.sub_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(A.val2) = 0 THEN 0
                    ELSE SUM(A.val1) / SUM(A.val2) END AS val2
        FROM (        
               -- 05.원당생산액(전년)
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
                     ,SUM(a.value) AS val1
                     ,0 AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
               AND    a.index1 = '1. Production Amount(K$)'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
               
               UNION ALL

               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
                     ,0 AS val1
                     ,SUM(a.value) AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
               AND    a.index1 = '4. L/C (K$)'
               AND    a.index2 = 'Total - Include O/S'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
               
              ) A
        GROUP BY A.sub
      ) a
GROUP BY a.sub

UNION ALL

-- 05.원당생산액
SELECT 'E04' AS seq
      ,'05.원당생산액' AS cat_cd
      ,a.sub AS sub
      ,MIN(a.sub_enm) as sub_enm
      ,MIN(a.sub_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,CASE WHEN SUM(A.val2) = 0 THEN 0
            ELSE SUM(A.val1) / SUM(A.val2) END AS val
FROM  (
        SELECT '05.원당생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @base_yyyymm
        AND    a.index1 = '1. Production Amount(K$)'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
        
        UNION ALL
        SELECT '05.원당생산액' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @base_yyyymm
        AND    a.index1 = '4. L/C (K$)'
        AND    a.index2 = 'Total - Include O/S'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
      ) A
GROUP BY a.sub

UNION ALL
-- 05.원당생산액
SELECT 'E05' AS seq
      ,'05.원당생산액' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 05.원당생산액(전전년)
        SELECT '05.원당생산액' AS cat_cd
              ,A.sub AS sub
              ,MIN(A.sub_enm) as sub_enm
              ,MIN(A.sub_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(A.val2) = 0 THEN 0
                    ELSE SUM(A.val1) / SUM(A.val2) END AS val1
              ,0 AS val2
        FROM  (        
                SELECT '05.원당생산액' AS cat_cd
                      ,sub.display_name AS sub
                      ,MIN(sub.display_enm) as sub_enm
                      ,MIN(sub.display_knm) as sub_knm
                      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
                      ,SUM(a.value) AS val1
                      ,0 AS val2
                FROM   m_opsmr_hr(nolock) a
                       LEFT JOIN
                       m_opsmr_tb_op_rate_sub_mst(nolock) sub
                       ON  a.subsidiary  = sub.mapping_code
                       AND sub.use_flag = 'Y'
                WHERE  a.std_yyyymm = @base_yyyymm
                AND    a.subsidiary LIKE @subsidiary+'%'
                AND    a.yyyymm = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2)
                AND    a.index1 = '1. Production Amount(K$)'
                AND    a.product = 'Total'
                GROUP BY sub.display_name
                
                UNION ALL

                SELECT '05.원당생산액' AS cat_cd
                      ,sub.display_name AS sub
                      ,MIN(sub.display_enm) as sub_enm
                      ,MIN(sub.display_knm) as sub_knm
                      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
                      ,0 AS val1
                      ,SUM(a.value) AS val2
                FROM   m_opsmr_hr(nolock) a
                       LEFT JOIN
                       m_opsmr_tb_op_rate_sub_mst(nolock) sub
                       ON  a.subsidiary  = sub.mapping_code
                       AND sub.use_flag = 'Y'
                WHERE  a.std_yyyymm = @base_yyyymm
                AND    a.subsidiary LIKE @subsidiary+'%'
                AND    a.yyyymm = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2)
                AND    a.index1 = '4. L/C (K$)'
                AND    a.index2 = 'Total - Include O/S'
                AND    a.product = 'Total'
                GROUP BY sub.display_name
                
               ) A
        GROUP BY A.sub

        UNION ALL
        -- 05.원당생산액(전년)
        SELECT '05.원당생산액' AS cat_cd
              ,A.sub AS sub
              ,MIN(A.sub_enm) as sub_enm
              ,MIN(A.sub_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(A.val2) = 0 THEN 0
                    ELSE SUM(A.val1) / SUM(A.val2) END AS val2
        FROM  (
                SELECT '05.원당생산액' AS cat_cd
                      ,sub.display_name AS sub
                      ,MIN(sub.display_enm) as sub_enm
                      ,MIN(sub.display_knm) as sub_knm
                      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
                      ,SUM(a.value) AS val1
                      ,0 AS val2
                FROM   m_opsmr_hr(nolock) a
                       LEFT JOIN
                       m_opsmr_tb_op_rate_sub_mst(nolock) sub
                       ON  a.subsidiary  = sub.mapping_code
                       AND sub.use_flag = 'Y'
                WHERE  a.std_yyyymm = @base_yyyymm
                AND    a.subsidiary LIKE @subsidiary+'%'
                AND    a.yyyymm = @base_yyyymm
                AND    a.index1 = '1. Production Amount(K$)'
                AND    a.product = 'Total'
                GROUP BY sub.display_name
                
                UNION ALL

                SELECT '05.원당생산액' AS cat_cd
                      ,sub.display_name AS sub
                      ,MIN(sub.display_enm) as sub_enm
                      ,MIN(sub.display_knm) as sub_knm
                      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
                      ,0 AS val1
                      ,SUM(a.value) AS val2
                FROM   m_opsmr_hr(nolock) a
                       LEFT JOIN
                       m_opsmr_tb_op_rate_sub_mst(nolock) sub
                       ON  a.subsidiary  = sub.mapping_code
                       AND sub.use_flag = 'Y'
                WHERE  a.std_yyyymm = @base_yyyymm
                AND    a.subsidiary LIKE @subsidiary+'%'
                AND    a.yyyymm = @base_yyyymm
                AND    a.index1 = '4. L/C (K$)'
        
                AND    a.index2 = 'Total - Include O/S'
                AND    a.product = 'Total'
                GROUP BY sub.display_name
                        
              ) A
        GROUP BY A.sub
      ) a
GROUP BY a.sub

UNION ALL
-- 05.원당생산액(누계)
SELECT 'E06' AS seq
      ,'05.원당생산액' AS cat_cd
      ,a.sub AS sub
      ,MIN(a.sub_enm) as sub_enm
      ,MIN(a.sub_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,CASE WHEN SUM(A.val2) = 0 THEN 0
            ELSE SUM(A.val1) / SUM(A.val2) END AS val
FROM (
       SELECT '05.원당생산액' AS cat_cd
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
       AND    a.index1 = '1. Production Amount(K$)'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
       UNION ALL
       SELECT '05.원당생산액' AS cat_cd
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
       AND    a.index1 = '4. L/C (K$)'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
       
      ) A
GROUP BY A.sub

UNION ALL
-- 05.원당생산액
SELECT 'E07' AS seq
      ,'05.원당생산액' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 05.원당생산액(전전년)
        SELECT '05.원당생산액' AS cat_cd
              ,a.sub AS sub
              ,MIN(a.sub_enm) as sub_enm
              ,MIN(a.sub_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(A.val2) = 0 THEN 0
                    ELSE SUM(A.val1) / SUM(A.val2) END AS val1
              ,0 AS val2
        FROM (
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
                     ,SUM(a.value) AS val1
                     ,0 AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_py_start_yyyymm and @vc_py_end_yyyymm
               AND    a.index1 = '1. Production Amount(K$)'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
               UNION ALL
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
                     ,0 AS val1
                     ,SUM(a.value) AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_py_start_yyyymm and @vc_py_end_yyyymm
               AND    a.index1 = '4. L/C (K$)'
               AND    a.index2 = 'Total - Include O/S'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
              ) A
        GROUP BY A.sub

        UNION ALL

        SELECT '05.원당생산액' AS cat_cd
              ,A.sub AS sub
              ,MIN(A.sub_enm) as sub_enm
              ,MIN(A.sub_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(A.val2) = 0 THEN 0
                    ELSE SUM(A.val1) / SUM(A.val2) END AS val2
        FROM (        
               -- 05.원당생산액(전년)<a name=""></a>
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
                     ,SUM(a.value) AS val1
                     ,0 AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
               AND    a.index1 = '1. Production Amount(K$)'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
               
               UNION ALL
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
                     ,0 AS val1
                     ,SUM(a.value) AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
               AND    a.index1 = '4. L/C (K$)'
       
               AND    a.index2 = 'Total - Include O/S'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
               
             ) A
        GROUP BY A.sub
      ) a
GROUP BY a.sub

UNION ALL

-- 05.원당생산액(M/L)
SELECT 'E08' AS seq
      ,'05.원당생산액' AS cat_cd
      ,a.sub AS sub
      ,MIN(a.sub_enm) as sub_enm
      ,MIN(a.sub_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,CASE WHEN SUM(A.val2) = 0 THEN 0
            ELSE SUM(A.val1) / SUM(A.val2) END  AS val
FROM  (
       SELECT '05.원당생산액' AS cat_cd
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
             ,SUM(a.value) AS val1
             ,0 AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_post_1 and @vc_post_3
       AND    a.index1 = '1. Production Amount(K$)'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
       UNION ALL
       SELECT '05.원당생산액' AS cat_cd
             ,sub.display_name AS sub
             ,MIN(sub.display_enm) as sub_enm
             ,MIN(sub.display_knm) as sub_knm
             ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
             ,0 AS val1
             ,SUM(a.value) AS val2
       FROM   m_opsmr_hr(nolock) a
              LEFT JOIN
              m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ON  a.subsidiary  = sub.mapping_code
              AND sub.use_flag = 'Y'
       WHERE  a.std_yyyymm = @base_yyyymm
       AND    a.subsidiary LIKE @subsidiary+'%'
       AND    a.yyyymm between @vc_post_1 and @vc_post_3
       AND    a.index1 = '4. L/C (K$)'
       AND    a.index2 = 'Total - Include O/S'
       AND    a.product = 'Total'
       GROUP BY sub.display_name
      ) A
GROUP BY A.sub

UNION ALL
-- 05.원당생산액
SELECT 'E09' AS seq
      ,'05.원당생산액' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 05.원당생산액(전전년)
        SELECT '05.원당생산액' AS cat_cd
              ,a.sub AS sub
              ,MIN(a.sub_enm) as sub_enm
              ,MIN(a.sub_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(A.val2) = 0 THEN 0
                    ELSE SUM(A.val1) / SUM(A.val2) END  AS val1
              ,0 AS val2
        FROM (
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
                     ,SUM(a.value) AS val1
                     ,0 AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_py_post_1 and @vc_py_post_3
               AND    a.index1 = '1. Production Amount(K$)'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
               UNION ALL
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
                     ,0 AS val1
                     ,SUM(a.value) AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_py_post_1 and @vc_py_post_3
               AND    a.index1 = '4. L/C (K$)'
               AND    a.index2 = 'Total - Include O/S'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
             ) a
        GROUP BY a.sub

        UNION ALL
        -- 05.원당생산액(전년)
        SELECT '05.원당생산액' AS cat_cd
              ,A.sub AS sub
              ,MIN(a.sub_enm) as sub_enm
              ,MIN(a.sub_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(A.val2) = 0 THEN 0
                    ELSE SUM(A.val1) / SUM(A.val2) END AS val2
        FROM (
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
                     ,SUM(a.value) AS val1
                     ,0 AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_post_1 and @vc_post_3
               AND    a.index1 = '1. Production Amount(K$)'
               AND    a.product = 'Total'
               GROUP BY sub.display_name
               UNION ALL
               SELECT '05.원당생산액' AS cat_cd
                     ,sub.display_name AS sub
                     ,MIN(sub.display_enm) as sub_enm
                     ,MIN(sub.display_knm) as sub_knm
                     ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
                     ,0 AS val1
                     ,SUM(a.value) AS val2
               FROM   m_opsmr_hr(nolock) a
                      LEFT JOIN
                      m_opsmr_tb_op_rate_sub_mst(nolock) sub
                      ON  a.subsidiary  = sub.mapping_code
                      AND sub.use_flag = 'Y'
               WHERE  a.std_yyyymm = @base_yyyymm
               AND    a.subsidiary LIKE @subsidiary+'%'
               AND    a.yyyymm between @vc_post_1 and @vc_post_3
               AND    a.index1 = '4. L/C (K$)'
               AND    a.index2 = 'Total - Include O/S'
               AND    a.product = 'Total'
               GROUP BY sub.display_name        
             ) A
        GROUP BY A.sub
      ) a
GROUP BY a.sub


UNION ALL

-- 06.인원(전전년)
SELECT 'F01' AS seq
      ,'06.인원' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.product = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 06.인원(전년)
SELECT 'F02' AS seq
      ,'06.인원' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.product = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 06.인원(전전년대비)
SELECT 'F03' AS seq
      ,'06.인원' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 06.인원(전전년)
        SELECT '06.인원' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
        AND    a.index1 = '3. H/C'
        AND    a.index2 = 'Total - Include O/S'
        AND    a.product = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 06.인원(전년)
        SELECT '06.인원' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
        AND    a.index1 = '3. H/C'
        AND    a.index2 = 'Total - Include O/S'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 06.인원
SELECT 'F04' AS seq
      ,'06.인원' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm = @base_yyyymm
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.product = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 06.인원
SELECT 'F05' AS seq
      ,'06.인원' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 06.인원(전전년)
        SELECT '06.인원' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2)
        AND    a.index1 = '3. H/C'
        AND    a.index2 = 'Total - Include O/S'
        AND    a.product = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 06.인원(전년)
        SELECT '06.인원' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @base_yyyymm
        AND    a.index1 = '3. H/C'
        AND    a.index2 = 'Total - Include O/S'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 06.인원(누계)
SELECT 'F06' AS seq
      ,'06.인원' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.product = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 06.인원
SELECT 'F07' AS seq
      ,'06.인원' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 06.인원(전전년)
        SELECT '06.인원' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_start_yyyymm and @vc_py_end_yyyymm
        AND    a.index1 = '3. H/C'
        AND    a.index2 = 'Total - Include O/S'
        AND    a.product = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 06.인원(전년)
        SELECT '06.인원' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
        AND    a.index1 = '3. H/C'
        AND    a.index2 = 'Total - Include O/S'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 06.인원(M/L)
SELECT 'F08' AS seq
      ,'06.인원' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,SUM(a.value) AS val
FROM   m_opsmr_hr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_post_1 and @vc_post_3
AND    a.index1 = '3. H/C'
AND    a.index2 = 'Total - Include O/S'
AND    a.product = 'Total'
GROUP BY sub.display_name


UNION ALL
-- 06.인원
SELECT 'F09' AS seq
      ,'06.인원' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 06.인원(전전년)
        SELECT '06.인원' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_post_1 and @vc_py_post_3
        AND    a.index1 = '3. H/C'
        AND    a.index2 = 'Total - Include O/S'
        AND    a.product = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 06.인원(전년)
        SELECT '06.인원' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   m_opsmr_hr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_post_1 and @vc_post_3
        AND    a.index1 = '3. H/C'
        AND    a.index2 = 'Total - Include O/S'
        AND    a.product = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub


UNION ALL

-- 07.OVERHEAD율(전전년)
SELECT 'G01' AS seq
      ,'07.OVERHEAD율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val
FROM   dbo.m_oh_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
AND    a.index1 = 'V/F'
AND    a.index2 IN ('Net Sales','O/H Cost')
GROUP BY sub.display_name

UNION ALL
-- 07.OVERHEAD율(전년)
SELECT 'G02' AS seq
      ,'07.OVERHEAD율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val
FROM   dbo.m_oh_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
AND    a.index1 = 'V/F'
AND    a.index2 IN ('Net Sales','O/H Cost')
GROUP BY sub.display_name

UNION ALL
-- 07.OVERHEAD율(전전년대비)
SELECT 'G03' AS seq
      ,'07.OVERHEAD율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 07.OVERHEAD율(전전년)
        SELECT '07.OVERHEAD율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val1
              ,0 AS val2
        FROM   dbo.m_oh_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
                AND    a.index1 = 'V/F'
        AND    a.index2 IN ('Net Sales','O/H Cost')
        GROUP BY sub.display_name

        UNION ALL
        -- 07.OVERHEAD율(전년)
        SELECT '07.OVERHEAD율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val2
        FROM   dbo.m_oh_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
                AND    a.index1 = 'V/F'
        AND    a.index2 IN ('Net Sales','O/H Cost')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 07.OVERHEAD율
SELECT 'G04' AS seq
      ,'07.OVERHEAD율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val
FROM   dbo.m_oh_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm = @base_yyyymm
AND    a.index1 = 'V/F'
AND    a.index2 IN ('Net Sales','O/H Cost')
GROUP BY sub.display_name

UNION ALL
-- 07.OVERHEAD율
SELECT 'G05' AS seq
      ,'07.OVERHEAD율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 07.OVERHEAD율(전전년)
        SELECT '07.OVERHEAD율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val1
              ,0 AS val2
        FROM   dbo.m_oh_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2)
        AND    a.index1 = 'V/F'
        AND    a.index2 IN ('Net Sales','O/H Cost')
        GROUP BY sub.display_name

        UNION ALL
        -- 07.OVERHEAD율(전년)
        SELECT '07.OVERHEAD율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
       		          ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val2
        FROM   dbo.m_oh_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @base_yyyymm
        AND    a.index1 = 'V/F'
        AND    a.index2 IN ('Net Sales','O/H Cost')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 07.OVERHEAD율(누계)
SELECT 'G06' AS seq
      ,'07.OVERHEAD율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val
FROM   dbo.m_oh_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
AND    a.index1 = 'V/F'
AND    a.index2 IN ('Net Sales','O/H Cost')
GROUP BY sub.display_name

UNION ALL
-- 07.OVERHEAD율
SELECT 'G07' AS seq
      ,'07.OVERHEAD율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 07.OVERHEAD율(전전년)
        SELECT '07.OVERHEAD율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
   		              ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val1
              ,0 AS val2
        FROM   dbo.m_oh_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_start_yyyymm and @vc_py_end_yyyymm
        AND    a.index1 = 'V/F'
        AND    a.index2 IN ('Net Sales','O/H Cost')
        GROUP BY sub.display_name

        UNION ALL
        -- 07.OVERHEAD율(전년)
        SELECT '07.OVERHEAD율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val2
        FROM   dbo.m_oh_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
        AND    a.index1 = 'V/F'
        AND    a.index2 IN ('Net Sales','O/H Cost')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 07.OVERHEAD율(M/L)
SELECT 'G08' AS seq
      ,'07.OVERHEAD율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val
FROM   dbo.m_oh_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_post_1 and @vc_post_3
AND    a.index1 = 'V/F'
AND    a.index2 IN ('Net Sales','O/H Cost')
GROUP BY sub.display_name


UNION ALL
-- 07.OVERHEAD율
SELECT 'G09' AS seq
      ,'07.OVERHEAD율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 07.OVERHEAD율(전전년)
        SELECT '07.OVERHEAD율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val1
              ,0 AS val2
        FROM   dbo.m_oh_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_post_1 and @vc_py_post_3
        AND    a.index1 = 'V/F'
        AND    a.index2 IN ('Net Sales','O/H Cost')
        GROUP BY sub.display_name

        UNION ALL
        -- 07.OVERHEAD율(전년)
        SELECT '07.OVERHEAD율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.index2 IN ('O/H Cost') THEN a.amt END) / SUM(CASE WHEN a.index2 IN ('Net Sales') THEN a.amt END) END AS val2
        FROM   dbo.m_oh_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_post_1 and @vc_post_3
        AND    a.index1 = 'V/F'
        AND    a.index2 IN ('Net Sales','O/H Cost')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL

-- 08.자재재고일수(전전년)
SELECT 'H01' AS seq
      ,'08.자재재고일수' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = @vc_pre_py_yyyy
AND    a.mm between 1 and 12
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '자재 재고'
AND    a.inv_detail = '재고일수(DIO)'
AND    a.division = 'Division'
GROUP BY sub.display_name

UNION ALL
-- 08.자재재고일수(전년)
SELECT 'H02' AS seq
      ,'08.자재재고일수' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = @vc_pre_yyyy
AND    a.mm between 1 and 12
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '자재 재고'
AND    a.inv_detail = '재고일수(DIO)'
AND    a.division = 'Division'
GROUP BY sub.display_name

UNION ALL
-- 08.자재재고일수(전전년대비)
SELECT 'H03' AS seq
      ,'08.자재재고일수' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 08.자재재고일수(전전년)
        SELECT '08.자재재고일수' AS cat_cd
      ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = @vc_pre_py_yyyy
        AND    a.mm between 1 and 12
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '자재 재고'
        AND    a.inv_detail = '재고일수(DIO)'
        AND    a.division = 'Division'
        GROUP BY sub.display_name

        UNION ALL
        -- 08.자재재고일수(전년)
        SELECT '08.자재재고일수' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = @vc_pre_yyyy
        AND    a.mm between 1 and 12
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '자재 재고'
        AND    a.inv_detail = '재고일수(DIO)'
        AND    a.division = 'Division'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 08.자재재고일수
SELECT 'H04' AS seq
      ,'08.자재재고일수' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = substring(@base_yyyymm,1,4)
AND    a.mm = convert(int,substring(@base_yyyymm,5,2))
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '자재 재고'
AND    a.inv_detail = '재고일수(DIO)'
AND    a.division = 'Division'
GROUP BY sub.display_name

UNION ALL
-- 08.자재재고일수
SELECT 'H05' AS seq
      ,'08.자재재고일수' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 08.자재재고일수(전전년)
        SELECT '08.자재재고일수' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = @vc_pre_yyyy
        AND    a.mm = convert(int,substring(@base_yyyymm,5,2))
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '자재 재고'
        AND    a.inv_detail = '재고일수(DIO)'
        AND    a.division = 'Division'
        GROUP BY sub.display_name

        UNION ALL
        -- 08.자재재고일수(전년)
        SELECT '08.자재재고일수' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@base_yyyymm,1,4)
        AND    a.mm = convert(int,substring(@base_yyyymm,5,2))
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '자재 재고'
        AND    a.inv_detail = '재고일수(DIO)'
        AND    a.division = 'Division'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 08.자재재고일수(누계)
SELECT 'H06' AS seq
      ,'08.자재재고일수' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = substring(@base_yyyymm,1,4)
AND    a.mm between convert(int,substring(@vc_start_yyyymm,5,2)) and convert(int,substring(@base_yyyymm,5,2))
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '자재 재고'
AND    a.inv_detail = '재고일수(DIO)'
AND    a.division = 'Division'
GROUP BY sub.display_name

UNION ALL
-- 08.자재재고일수
SELECT 'H07' AS seq
      ,'08.자재재고일수' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 08.자재재고일수(전전년)
        SELECT '08.자재재고일수' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@vc_py_start_yyyymm,1,4)
        AND    a.mm between convert(int,substring(@vc_py_start_yyyymm,5,2)) and convert(int,substring(@vc_py_end_yyyymm,5,2))
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '자재 재고'
        AND    a.inv_detail = '재고일수(DIO)'
        AND    a.division = 'Division'
        GROUP BY sub.display_name

        UNION ALL
        -- 08.자재재고일수(전년)
        SELECT '08.자재재고일수' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@vc_start_yyyymm,1,4)
        AND    a.mm between convert(int,substring(@vc_start_yyyymm,5,2)) and convert(int,substring(@base_yyyymm,5,2))
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '자재 재고'
        AND    a.inv_detail = '재고일수(DIO)'
        AND    a.division = 'Division'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 08.자재재고일수(M/L)
SELECT 'H08' AS seq
      ,'08.자재재고일수' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = substring(@vc_post_1,1,4)
AND    a.mm between convert(int,substring(@vc_post_1,5,2)) and convert(int,substring(@vc_post_3,5,2))
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '자재 재고'
AND    a.inv_detail = '재고일수(DIO)'
AND    a.division = 'Division'
GROUP BY sub.display_name


UNION ALL
-- 08.자재재고일수
SELECT 'H09' AS seq
      ,'08.자재재고일수' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1))/SUM(a.val1) AS val
FROM   (
        -- 08.자재재고일수(전전년)
        SELECT '08.자재재고일수' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@vc_py_post_1,1,4)
        AND    a.mm between convert(int,substring(@vc_py_post_1,5,2)) and convert(int,substring(@vc_py_post_3,5,2))
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '자재 재고'
        AND    a.inv_detail = '재고일수(DIO)'
        AND    a.division = 'Division'
        GROUP BY sub.display_name

        UNION ALL
        -- 08.자재재고일수(전년)
        SELECT '08.자재재고일수' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@vc_post_1,1,4)
        AND    a.mm between convert(int,substring(@vc_post_1,5,2)) and convert(int,substring(@vc_post_3,5,2))
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '자재 재고'
        AND    a.inv_detail = '재고일수(DIO)'
        AND    a.division = 'Division'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub


UNION ALL

-- 09.장기재고율(전전년)
SELECT 'I01' AS seq
      ,'09.장기재고율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = @vc_pre_py_yyyy
AND    a.mm between 1 and 12
AND    a.division = 'Division'
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '총재고'
AND    a.inv_detail IN ( '장기재고','창고재고')
GROUP BY sub.display_name

UNION ALL
-- 09.장기재고율(전년)
SELECT 'I02' AS seq
      ,'09.장기재고율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = @vc_pre_yyyy
AND    a.mm between 1 and 12
AND    a.division = 'Division'
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '총재고'
AND    a.inv_detail IN ( '장기재고','창고재고')
GROUP BY sub.display_name

UNION ALL
-- 09.장기재고율(전전년대비)
SELECT 'I03' AS seq
      ,'09.장기재고율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 09.장기재고율(전전년)
        SELECT '09.장기재고율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val1
              ,0 AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = @vc_pre_py_yyyy
        AND    a.mm between 1 and 12
        AND    a.division = 'Division'
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '총재고'
        AND    a.inv_detail IN ( '장기재고','창고재고')
        GROUP BY sub.display_name

        UNION ALL
        -- 09.장기재고율(전년)
        SELECT '09.장기재고율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = @vc_pre_yyyy
        AND    a.mm between 1 and 12
        AND    a.division = 'Division'
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '총재고'
        AND    a.inv_detail IN ( '장기재고','창고재고')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 09.장기재고율
SELECT 'I04' AS seq
      ,'09.장기재고율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = substring(@base_yyyymm,1,4)
AND    a.mm = convert(int,substring(@base_yyyymm,5,2))
AND    a.division = 'Division'
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '총재고'
AND    a.inv_detail IN ( '장기재고','창고재고')
GROUP BY sub.display_name

UNION ALL
-- 09.장기재고율
SELECT 'I05' AS seq
      ,'09.장기재고율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 09.장기재고율(전전년)
        SELECT '09.장기재고율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val1
              ,0 AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@vc_pre_yyyy,1,4)
        AND    a.mm = convert(int,substring(@base_yyyymm,5,2))
        AND    a.division = 'Division'
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '총재고'
        AND    a.inv_detail IN ( '장기재고','창고재고')
        GROUP BY sub.display_name

        UNION ALL
        -- 09.장기재고율(전년)
        SELECT '09.장기재고율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
       		          ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@base_yyyymm,1,4)
        AND    a.mm = convert(int,substring(@base_yyyymm,5,2))
        AND    a.division = 'Division'
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '총재고'
        AND    a.inv_detail IN ( '장기재고','창고재고')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 09.장기재고율(누계)
SELECT 'I06' AS seq
      ,'09.장기재고율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = substring(@vc_start_yyyymm,1,4)
AND    a.mm between convert(int,substring(@vc_start_yyyymm,5,2)) and convert(int,substring(@base_yyyymm,5,2))
AND    a.division = 'Division'
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '총재고'
AND    a.inv_detail IN ( '장기재고','창고재고')
GROUP BY sub.display_name

UNION ALL
-- 09.장기재고율
SELECT 'I07' AS seq
      ,'09.장기재고율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 09.장기재고율(전전년)
        SELECT '09.장기재고율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
   		              ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val1
              ,0 AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@vc_py_start_yyyymm,1,4)
        AND    a.mm between convert(int,substring(@vc_py_start_yyyymm,5,2)) and convert(int,substring(@vc_py_end_yyyymm,5,2))
        AND    a.division = 'Division'
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '총재고'
        AND    a.inv_detail IN ( '장기재고','창고재고')
        GROUP BY sub.display_name

        UNION ALL
        -- 09.장기재고율(전년)
        SELECT '09.장기재고율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@vc_start_yyyymm,1,4)
        AND    a.mm between convert(int,substring(@vc_start_yyyymm,5,2)) and convert(int,substring(@base_yyyymm,5,2))
        AND    a.division = 'Division'
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '총재고'
        AND    a.inv_detail IN ( '장기재고','창고재고')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 09.장기재고율(M/L)
SELECT 'I08' AS seq
      ,'09.장기재고율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		        ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val
FROM   dbo.m_inv_data(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyy = substring(@vc_post_1,1,4)
AND    a.mm between convert(int,substring(@vc_post_1,5,2)) and convert(int,substring(@vc_post_3,5,2))
AND    a.division = 'Division'
AND    a.type1 = 'ACT'
AND    a.type2 = 'ACT'
AND    a.inv_type = '총재고'
AND    a.inv_detail IN ( '장기재고','창고재고')
GROUP BY sub.display_name


UNION ALL
-- 09.장기재고율
SELECT 'I09' AS seq
      ,'09.장기재고율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 09.장기재고율(전전년)
        SELECT '09.장기재고율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val1
              ,0 AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@vc_py_post_1,1,4)
        AND    a.mm between convert(int,substring(@vc_py_post_1,5,2)) and convert(int,substring(@vc_py_post_3,5,2))
        AND    a.division = 'Division'
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '총재고'
        AND    a.inv_detail IN ( '장기재고','창고재고')
        GROUP BY sub.display_name

        UNION ALL
        -- 09.장기재고율(전년)
        SELECT '09.장기재고율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,CASE WHEN SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.value END) = 0 THEN 0
		                ELSE SUM(CASE WHEN a.inv_detail IN ( '장기재고') THEN a.VALUE END) / SUM(CASE WHEN a.inv_detail IN ( '창고재고') THEN a.VALUE END) END AS val2
        FROM   dbo.m_inv_data(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyy = substring(@vc_post_1,1,4)
        AND    a.mm between convert(int,substring(@vc_post_1,5,2)) and convert(int,substring(@vc_post_3,5,2))
        AND    a.division = 'Division'
        AND    a.type1 = 'ACT'
        AND    a.type2 = 'ACT'
        AND    a.inv_type = '총재고'
        AND    a.inv_detail IN ( '장기재고','창고재고')
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub


UNION ALL

-- 10.시장불량율(전전년)
SELECT 'J01' AS seq
      ,'10.시장불량율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_opsmr_ffr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
and    a.prod = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 10.시장불량율(전년)
SELECT 'J02' AS seq
      ,'10.시장불량율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_opsmr_ffr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
and    a.prod = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 10.시장불량율(전전년대비)
SELECT 'J03' AS seq
      ,'10.시장불량율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'03.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 10.시장불량율(전전년)
        SELECT '10.시장불량율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   dbo.m_opsmr_ffr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_py_yyyy+'01' and @vc_pre_py_yyyy+'12'
        and    a.prod = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 10.시장불량율(전년)
        SELECT '10.시장불량율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   dbo.m_opsmr_ffr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_pre_yyyy+'01' and @vc_pre_yyyy+'12'
        and    a.prod = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 10.시장불량율
SELECT 'J04' AS seq
      ,'10.시장불량율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'04.'+SUBSTRING(@base_yyyymm,5,2) AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_opsmr_ffr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm = @base_yyyymm
and    a.prod = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 10.시장불량율
SELECT 'J05' AS seq
      ,'10.시장불량율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'05.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 10.시장불량율(전전년)
        SELECT '10.시장불량율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   dbo.m_opsmr_ffr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @vc_pre_yyyy+SUBSTRING(@base_yyyymm,5,2)
        and    a.prod = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 10.시장불량율(전년)
        SELECT '10.시장불량율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   dbo.m_opsmr_ffr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm = @base_yyyymm
        and    a.prod = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 10.시장불량율(누계)
SELECT 'J06' AS seq
      ,'10.시장불량율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'06.'+SUBSTRING(@base_yyyymm,5,2)+'누계' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_opsmr_ffr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
and    a.prod = 'Total'
GROUP BY sub.display_name

UNION ALL
-- 10.시장불량율
SELECT 'J07' AS seq
      ,'10.시장불량율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'07.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 10.시장불량율(전전년)
        SELECT '10.시장불량율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   dbo.m_opsmr_ffr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_start_yyyymm and @vc_py_end_yyyymm
        and    a.prod = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 10.시장불량율(전년)
        SELECT '10.시장불량율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   dbo.m_opsmr_ffr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_start_yyyymm and @base_yyyymm
        and    a.prod = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

UNION ALL
-- 10.시장불량율(M/L)
SELECT 'J08' AS seq
      ,'10.시장불량율' AS cat_cd
      ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,'08.'+SUBSTRING(@vc_post_1,5,2)+'~'+SUBSTRING(@vc_post_3,5,2)+'월' AS kpi_code
      ,SUM(a.value) AS val
FROM   dbo.m_opsmr_ffr(nolock) a
       LEFT JOIN
       m_opsmr_tb_op_rate_sub_mst(nolock) sub
       ON  a.subsidiary  = sub.mapping_code
       AND sub.use_flag = 'Y'
WHERE  a.std_yyyymm = @base_yyyymm
AND    a.subsidiary LIKE @subsidiary+'%'
AND    a.yyyymm between @vc_post_1 and @vc_post_3
and    a.prod = 'Total'
GROUP BY sub.display_name


UNION ALL
-- 10.시장불량율
SELECT 'J09' AS seq
      ,'10.시장불량율' AS cat_cd
      ,a.sub           AS sub
      ,MAX(a.sub_enm)  AS sub_enm
      ,MAX(a.sub_knm)  AS sub_knm
      ,'09.전년대비'      AS kpi_code
      ,(SUM(a.val2) - SUM(a.val1)) AS val
FROM   (
        -- 10.시장불량율(전전년)
        SELECT '10.시장불량율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'01.'+SUBSTRING(@vc_pre_py_yyyy,3,2)+'연간' AS kpi_code
              ,SUM(a.value) AS val1
              ,0 AS val2
        FROM   dbo.m_opsmr_ffr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_py_post_1 and @vc_py_post_3
        and    a.prod = 'Total'
        GROUP BY sub.display_name

        UNION ALL
        -- 10.시장불량율(전년)
        SELECT '10.시장불량율' AS cat_cd
              ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,'02.'+SUBSTRING(@vc_pre_yyyy,3,2)+'연간' AS kpi_code
              ,0 AS val1
              ,SUM(a.value) AS val2
        FROM   dbo.m_opsmr_ffr(nolock) a
               LEFT JOIN
               m_opsmr_tb_op_rate_sub_mst(nolock) sub
               ON  a.subsidiary  = sub.mapping_code
               AND sub.use_flag = 'Y'
        WHERE  a.std_yyyymm = @base_yyyymm
        AND    a.subsidiary LIKE @subsidiary+'%'
        AND    a.yyyymm between @vc_post_1 and @vc_post_3
        and    a.prod = 'Total'
        GROUP BY sub.display_name
      ) a
GROUP BY a.sub

;

END