ALTER PROCEDURE [dbo].[m_opsmr_sp_rate_70_less_ppt]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
 ,@base_rate     FLOAT
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_rate_70_less_ppt
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_rate_70_less_ppt

--   EXEC m_opsmr_sp_rate_70_less_ppt 'STD', @base_yyyymm, 70

4. 관 련 화 면 :

버전  작 성 자   일      자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.11  최초작성
1.1   shlee      2016.04.21  날짜와 subsidiary/ Product Master적용
1.2   shlee      2016.04.22  * 100 제거
***************************************************************************/

DECLARE @vc_pre_13               AS VARCHAR(6);
DECLARE @vc_py_yyyy              AS VARCHAR(6);
DECLARE @vc_start_yyyymm         AS VARCHAR(6);
DECLARE @vc_py_act_start_yyyymm  AS VARCHAR(6);
DECLARE @vc_py_act_end_yyyymm    AS VARCHAR(6);
DECLARE @vc_py_plan_start_yyyymm AS VARCHAR(6);
DECLARE @vc_py_plan_end_yyyymm   AS VARCHAR(6);

DECLARE @vc_post_1               AS VARCHAR(6);
DECLARE @vc_post_2               AS VARCHAR(6);
DECLARE @vc_post_3               AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13      = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전13월
SET @vc_py_yyyy   = CONVERT(VARCHAR(4), DATEADD(yy,  -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전년
SET @vc_start_yyyymm  = SUBSTRING(@base_yyyymm,1,4)+'01';    -- 누적년시작월 @vc_start_yyyymm
SET @vc_py_act_start_yyyymm = @vc_py_yyyy + '01';    -- 전년01월
SET @vc_py_act_end_yyyymm   = @vc_py_yyyy + SUBSTRING(@base_yyyymm,5,2);    -- 전년현재월
SET @vc_py_plan_start_yyyymm = @vc_py_yyyy + SUBSTRING(CONVERT(VARCHAR(6), DATEADD(m,  1, CONVERT(DATETIME,@base_yyyymm + '01')), 112),5,2);    -- 전년차월
SET @vc_py_plan_end_yyyymm   = @vc_py_yyyy + SUBSTRING(CONVERT(VARCHAR(6), DATEADD(m,  3, CONVERT(DATETIME,@base_yyyymm + '01')), 112),5,2);    -- 전년차차차월

SET @vc_post_1      = CONVERT(VARCHAR(6), DATEADD(m,  1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 차월
SET @vc_post_2      = CONVERT(VARCHAR(6), DATEADD(m,  2, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 차월
SET @vc_post_3      = CONVERT(VARCHAR(6), DATEADD(m,  3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 차월

BEGIN

select a.sub
      ,a.prod
      ,MAX(a.sub_enm ) AS sub_enm 
      ,MAX(a.sub_knm ) AS sub_knm 
      ,MAX(a.prod_enm) AS prod_enm
      ,MAX(a.prod_knm) AS prod_knm
      ,CASE copy_t.col WHEN 1 THEN 'RATE' WHEN 2 THEN 'QTY' END AS TP
      ,SUM(CASE copy_t.col WHEN 1 THEN a.plan_total_rate     WHEN 2 THEN a.plan_total_qty    END) AS plan_total
      ,SUM(CASE copy_t.col WHEN 1 THEN a.plan_post_1_rate    WHEN 2 THEN a.plan_post_1_qty   END) AS plan_post_1
      ,SUM(CASE copy_t.col WHEN 1 THEN a.plan_post_2_rate    WHEN 2 THEN a.plan_post_2_qty   END) AS plan_post_2
      ,SUM(CASE copy_t.col WHEN 1 THEN a.plan_post_3_rate    WHEN 2 THEN a.plan_post_3_qty   END) AS plan_post_3
      ,SUM(CASE copy_t.col WHEN 1 THEN a.act_cur_mon_rate    WHEN 2 THEN a.act_cur_mon_qty   END) AS act_cur_mon
      ,SUM(CASE copy_t.col WHEN 1 THEN a.act_cur_base_rate   WHEN 2 THEN a.act_cur_base_qty  END) AS act_cur_base
      ,SUM(CASE copy_t.col WHEN 1 THEN a.act_py_base_rate    WHEN 2 THEN a.act_py_base_qty   END) AS act_py_base
      ,SUM(CASE copy_t.col WHEN 1 THEN a.act_py_plan_rate    WHEN 2 THEN a.act_py_plan_qty   END) AS act_py_plan
      ,SUM(CASE copy_t.col WHEN 1 THEN a.cur_mon_13_rate     WHEN 2 THEN a.cur_mon_13_qty    END) AS cur_mon_13
      ,SUM(CASE copy_t.col WHEN 1 THEN a.rate_mon_13_rate    WHEN 2 THEN a.rate_mon_13_qty   END) AS rate_mon_13
      ,SUM(CASE copy_t.col WHEN 1 THEN a.vs_rate             WHEN 2 THEN a.vs_qty            END) AS vs
      ,SUM(CASE copy_t.col WHEN 1 THEN a.vs_base_rate        WHEN 2 THEN ''                  END) AS vs_base
      ,SUM(CASE copy_t.col WHEN 1 THEN a.accu_rate           WHEN 2 THEN ''                  END) AS accu
      ,SUM(CASE copy_t.col WHEN 1 THEN a.py13_cur_accu_rate  WHEN 2 THEN ''                  END) AS py13_cur_accu
from (
      select a.sub
            ,a.prod
            ,a.sub_enm
            ,a.sub_knm
            ,a.prod_enm
            ,a.prod_knm
            ,a.plan_total_rate
            ,a.plan_post_1_rate
            ,a.plan_post_2_rate
            ,a.plan_post_3_rate
            ,a.act_cur_mon_rate
            ,a.act_cur_base_rate
            ,a.act_py_base_rate
            ,a.act_py_plan_rate
            ,a.cur_mon_13_rate
            ,a.rate_mon_13_rate
            ,a.vs_rate
            ,a.vs_base_rate
            ,a.accu_rate
            ,a.py13_cur_accu_rate
            ,a.plan_total_qty
            ,a.plan_post_1_qty
            ,a.plan_post_2_qty
            ,a.plan_post_3_qty
            ,a.act_cur_mon_qty
            ,a.act_cur_base_qty
            ,a.act_py_base_qty
            ,a.act_py_plan_qty
            ,a.cur_mon_13_qty
            ,a.rate_mon_13_qty
            ,a.vs_qty
      from  (
             select a.sub
                   ,a.prod
                   ,max(a.sub_enm)  AS sub_enm
                   ,max(a.sub_knm)  AS sub_knm
                   ,max(a.prod_enm) AS prod_enm
                   ,max(a.prod_knm) AS prod_knm
                   ,sum(a.plan_total_rate) AS plan_total_rate
                   ,sum(a.plan_post_1_rate) AS plan_post_1_rate
                   ,sum(a.plan_post_2_rate) AS plan_post_2_rate
                   ,sum(a.plan_post_3_rate) AS plan_post_3_rate
                   ,sum(a.act_cur_mon_rate) AS act_cur_mon_rate
                   ,sum(a.act_cur_base_rate) AS act_cur_base_rate
                   ,sum(a.act_py_base_rate) AS act_py_base_rate
                   ,sum(a.act_py_plan_rate) AS act_py_plan_rate
                   ,sum(a.cur_mon_13_rate) AS cur_mon_13_rate
                   ,sum(a.rate_mon_13_rate) AS rate_mon_13_rate
                   ,sum(a.plan_total_qty) AS plan_total_qty
                   ,sum(a.plan_post_1_qty) AS plan_post_1_qty
                   ,sum(a.plan_post_2_qty) AS plan_post_2_qty
                   ,sum(a.plan_post_3_qty) AS plan_post_3_qty
                   ,sum(a.act_cur_mon_qty) AS act_cur_mon_qty
                   ,sum(a.act_cur_base_qty) AS act_cur_base_qty
                   ,sum(a.act_py_base_qty) AS act_py_base_qty
                   ,sum(a.act_py_plan_qty) AS act_py_plan_qty
                   ,sum(a.cur_mon_13_qty) AS cur_mon_13_qty
                   ,sum(a.rate_mon_13_qty) AS rate_mon_13_qty
                   ,sum(a.plan_total_rate) - sum(a.act_cur_mon_rate) AS vs_rate
                   ,sum(a.plan_total_qty) - sum(a.act_cur_mon_qty) AS vs_qty
                   ,sum(a.plan_total_rate) - sum(a.act_cur_base_rate) AS vs_base_rate
                   ,sum(a.accu_rate) AS accu_rate
                   ,sum(a.py13_cur_accu_rate) AS py13_cur_accu_rate
             from (
                   select sub.display_name AS sub
                         ,prod.display_name AS prod
                         ,MIN(sub.display_enm) as sub_enm
                         ,MIN(sub.display_knm) as sub_knm
                         ,MIN(prod.display_enm) as prod_enm
                         ,MIN(prod.display_knm) as prod_knm
                         ,case when sum(case when a.kpi_period_code IN (@vc_post_1,@vc_post_2,@vc_post_3) then a.production_capa end) = 0 then 0
                               else sum(case when a.kpi_period_code IN (@vc_post_1,@vc_post_2,@vc_post_3) then a.production_quantity end) / sum(case when a.kpi_period_code IN (@vc_post_1,@vc_post_2,@vc_post_3) then a.production_capa end) end AS plan_total_rate
                               
                         ,case when sum(case when a.kpi_period_code = @vc_post_1 then a.production_capa end) = 0 then 0
                               else sum(case when a.kpi_period_code = @vc_post_1 then a.production_quantity end) / sum(case when a.kpi_period_code = @vc_post_1 then a.production_capa end) end AS plan_post_1_rate
                               
                         ,case when sum(case when a.kpi_period_code = @vc_post_2 then a.production_capa end) = 0 then 0
                               else sum(case when a.kpi_period_code = @vc_post_2 then a.production_quantity end) / sum(case when a.kpi_period_code = @vc_post_2 then a.production_capa end) end AS plan_post_2_rate
                               
                         ,case when sum(case when a.kpi_period_code = @vc_post_3 then a.production_capa end) = 0 then 0
                               else sum(case when a.kpi_period_code = @vc_post_3 then a.production_quantity end) / sum(case when a.kpi_period_code = @vc_post_3 then a.production_capa end) end AS plan_post_3_rate
                               
                         ,case when sum(case when a.kpi_period_code = @base_yyyymm then a.production_capa end) = 0 then 0
                               else sum(case when a.kpi_period_code = @base_yyyymm then a.production_quantity end) / sum(case when a.kpi_period_code = @base_yyyymm then a.production_capa end) end AS act_cur_mon_rate
                               
                         ,case when sum(case when a.kpi_period_code between @vc_start_yyyymm and @base_yyyymm then a.production_capa end) = 0 then 0
                               else sum(case when a.kpi_period_code between @vc_start_yyyymm and @base_yyyymm then a.production_quantity end) / sum(case when a.kpi_period_code between @vc_start_yyyymm and @base_yyyymm then a.production_capa end) end AS act_cur_base_rate
                               
                         ,case when sum(case when a.kpi_period_code between @vc_py_act_start_yyyymm and @vc_py_act_end_yyyymm then a.production_capa end) = 0 then 0
                               else sum(case when a.kpi_period_code between @vc_py_act_start_yyyymm and @vc_py_act_end_yyyymm then a.production_quantity end) / sum(case when a.kpi_period_code between @vc_py_act_start_yyyymm and @vc_py_act_end_yyyymm then a.production_capa end) end AS act_py_base_rate
                               
                         ,case when sum(case when a.kpi_period_code between @vc_py_plan_start_yyyymm and @vc_py_plan_end_yyyymm then a.production_capa end) = 0 then 0
                               else sum(case when a.kpi_period_code between @vc_py_plan_start_yyyymm and @vc_py_plan_end_yyyymm then a.production_quantity end) / sum(case when a.kpi_period_code between @vc_py_plan_start_yyyymm and @vc_py_plan_end_yyyymm then a.production_capa end) end AS act_py_plan_rate
                               
                         ,case when sum(a.production_capa) = 0 then 0
                             else sum(case when a.kpi_period_code between @vc_start_yyyymm and @base_yyyymm then a.production_quantity end) / sum(a.production_capa) end AS cur_mon_13_rate
                             
                         ,case when sum(a.production_capa) = 0 then 0
                             else sum(a.production_quantity) / sum(a.production_capa) end AS rate_mon_13_rate
                             
                         ,SUM(case when a.kpi_period_code IN (@vc_post_1,@vc_post_2,@vc_post_3) then a.production_quantity end)/3 AS plan_total_qty
                         ,sum(case when a.kpi_period_code = @vc_post_1 then a.production_quantity end) AS plan_post_1_qty
                         ,sum(case when a.kpi_period_code = @vc_post_2 then a.production_quantity end) AS plan_post_2_qty
                         ,sum(case when a.kpi_period_code = @vc_post_3 then a.production_quantity end) AS plan_post_3_qty
                         ,sum(case when a.kpi_period_code = @base_yyyymm then a.production_quantity end) AS act_cur_mon_qty
                         ,sum(case when a.kpi_period_code between @vc_start_yyyymm and @base_yyyymm then a.production_quantity end) AS act_cur_base_qty
                         ,sum(case when a.kpi_period_code between @vc_py_act_start_yyyymm and @vc_py_act_end_yyyymm then a.production_quantity end) AS act_py_base_qty
                         ,sum(case when a.kpi_period_code between @vc_py_plan_start_yyyymm and @vc_py_plan_end_yyyymm then a.production_quantity end) AS act_py_plan_qty
                         ,sum(case when a.kpi_period_code between @vc_start_yyyymm and @base_yyyymm then a.production_quantity end) AS cur_mon_13_qty
                         ,sum(a.production_quantity) AS rate_mon_13_qty
             
                         ,case when max(pqty.production_quantity) = 0 then 0
                             else sum(case when a.kpi_period_code between @vc_start_yyyymm and @base_yyyymm then a.production_quantity end) / max(pqty.production_quantity) end AS accu_rate
                             
                         ,case when SUM(case when a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm THEN a.production_capa end) = 0 then 0
                               else SUM(case when a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm THEN a.production_quantity end) / SUM(case when a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm THEN a.production_capa end) end AS py13_cur_accu_rate
                             
                   FROM   m_opsmr_tb_op_rate(nolock) a
                         ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
                         ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
                         ,(SELECT GBU_CODE,
                                  SUM(PRODUCTION_QUANTITY) AS production_quantity
                           FROM   M_OPSMR_TB_OP_RATE(NOLOCK)
                           WHERE  OPSMR_TYPE = 'STD'
                           AND    KPI_PERIOD_CODE BETWEEN @vc_start_yyyymm AND @base_yyyymm
                           GROUP BY GBU_CODE) pqty
                   where  a.opsmr_type = @opsmr_type
                   and    a.base_yyyymm = @base_yyyymm
                   and    a.kpi_period_code BETWEEN @vc_py_act_start_yyyymm AND @vc_post_3
                   AND    a.factory_region1 = sub.mapping_code
                   AND    a.gbu_code = prod.mapping_code
                   AND    sub.use_flag = 'Y'
                   AND    prod.use_flag = 'Y'
                   AND    a.gbu_code = pqty.gbu_code
                   GROUP BY sub.display_name
                           ,prod.display_name
             
                   ) a
             where a.plan_total_rate < @base_rate*0.01
             group by a.sub
                     ,a.prod
            ) a
      where a.plan_total_rate <> 0              
      ) a
     ,(
        select 1 as col
        union all
        select 2
      ) copy_t
GROUP BY a.sub
        ,a.prod
        ,CASE copy_t.col WHEN 1 THEN 'RATE' WHEN 2 THEN 'QTY' END
;

END