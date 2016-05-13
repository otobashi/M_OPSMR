ALTER PROCEDURE [dbo].[m_opsmr_sp_rate_gap_10_post]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
 ,@base_rate     FLOAT
 ,@chg_rate      FLOAT
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_rate_gap_10_post
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_rate_gap_10_post

--   EXEC m_opsmr_sp_rate_gap_10_post 'STD', '201603', 85, 10

4. 관 련 화 면 :

버전  작 성 자   일      자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.05  최초작성
1.1   shlee      2016.04.21  날짜와 subsidiary/ Product Master적용
***************************************************************************/

DECLARE @vc_pre_yyyymm   AS VARCHAR(6);
DECLARE @vc_start_yyyymm AS VARCHAR(6);
DECLARE @vc_post_1       AS VARCHAR(6);
DECLARE @vc_pre_13       AS VARCHAR(6);


SET NOCOUNT ON

SET @vc_pre_yyyymm   = CONVERT(VARCHAR(6), DATEADD(m, -1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전월
SET @vc_start_yyyymm = SUBSTRING(@base_yyyymm,1,4) + '01' ;
SET @vc_post_1       = CONVERT(VARCHAR(6), DATEADD(m,  1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 차월
SET @vc_pre_13       = CONVERT(VARCHAR(6), DATEADD(m,-12, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 전13월


BEGIN

SELECT a.sub
      ,a.prod
      ,a.sub_enm
      ,a.sub_knm
      ,a.prod_enm
      ,a.prod_knm
      ,a.pre_rate
      ,a.cur_rate
      ,a.post_rate
      ,a.pre_rate_gap
      ,a.post_rate_gap
      ,a.abs_pre_rate_gap
      ,a.abs_post_rate_gap
      ,a.pre_qty
      ,a.cur_qty
      ,a.post_qty
      ,a.pre_qty_gap
      ,a.post_qty_gap
      ,a.abs_pre_qty_gap
      ,a.abs_post_qty_gap
      ,a.rate_mon13
      ,a.qty_mon13
      ,a.qty_rate_mon13
      ,a.qty_rate_1_base
      ,CASE WHEN a.post_rate_gap >= 0 THEN 1
            ELSE -1 END AS signal 
FROM  ( SELECT sub.display_name AS sub
              ,prod.display_name AS prod
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,MIN(prod.display_enm) as prod_enm
              ,MIN(prod.display_knm) as prod_knm
              ,isnull(sum(case when a.kpi_period_code = @vc_pre_yyyymm then standard_operation_rate end),0) as pre_rate
              ,isnull(sum(case when a.kpi_period_code = @base_yyyymm then standard_operation_rate end),0) as cur_rate
              ,isnull(sum(case when a.kpi_period_code = @vc_post_1 then standard_operation_rate end),0) as post_rate
              ,(isnull(sum(case when a.kpi_period_code = @base_yyyymm then standard_operation_rate end),0)) - (isnull(sum(case when a.kpi_period_code = @vc_pre_yyyymm then standard_operation_rate end),0)) AS pre_rate_gap
              ,(isnull(sum(case when a.kpi_period_code = @vc_post_1 then standard_operation_rate end),0)) - (isnull(sum(case when a.kpi_period_code = @base_yyyymm then standard_operation_rate end),0)) AS post_rate_gap
              ,abs((isnull(sum(case when a.kpi_period_code = @base_yyyymm then standard_operation_rate end),0)) - (isnull(sum(case when a.kpi_period_code = @vc_pre_yyyymm then standard_operation_rate end),0))) AS abs_pre_rate_gap
              ,abs((isnull(sum(case when a.kpi_period_code = @vc_post_1 then standard_operation_rate end),0)) - (isnull(sum(case when a.kpi_period_code = @base_yyyymm then standard_operation_rate end),0))) AS abs_post_rate_gap
              ,isnull(sum(case when a.kpi_period_code = @vc_pre_yyyymm then a.production_quantity end),0) as pre_qty
              ,isnull(sum(case when a.kpi_period_code = @base_yyyymm then a.production_quantity end),0) as cur_qty
              ,isnull(sum(case when a.kpi_period_code = @vc_post_1 then a.production_quantity end),0) as post_qty
              ,(isnull(sum(case when a.kpi_period_code = @base_yyyymm then a.production_quantity end),0)) - (isnull(sum(case when a.kpi_period_code = @vc_pre_yyyymm then a.production_quantity end),0)) AS pre_qty_gap
              ,(isnull(sum(case when a.kpi_period_code = @vc_post_1 then a.production_quantity end),0)) - (isnull(sum(case when a.kpi_period_code = @base_yyyymm then a.production_quantity end),0)) AS post_qty_gap
              ,abs((isnull(sum(case when a.kpi_period_code = @base_yyyymm then a.production_quantity end),0)) - (isnull(sum(case when a.kpi_period_code = @vc_pre_yyyymm then a.production_quantity end),0))) AS abs_pre_qty_gap
              ,abs((isnull(sum(case when a.kpi_period_code = @vc_post_1 then a.production_quantity end),0)) - (isnull(sum(case when a.kpi_period_code = @base_yyyymm then a.production_quantity end),0))) AS abs_post_qty_gap
              ,case when isnull(sum(case when a.kpi_period_code between @vc_pre_13 and @base_yyyymm then production_capa end),0) = 0 then 0
                    else isnull(sum(case when a.kpi_period_code between @vc_pre_13 and @base_yyyymm then a.production_quantity end),0) / isnull(sum(case when a.kpi_period_code between @vc_pre_13 and @base_yyyymm then production_capa end),0) end AS rate_mon13
                ,isnull(sum(case when a.kpi_period_code between @vc_pre_13 and @base_yyyymm then a.production_quantity end),0) AS qty_mon13
              ,case when isnull(sum(case when a.kpi_period_code between @vc_pre_13 and @base_yyyymm then a.production_quantity end),0) = 0 then 0
                    else isnull(sum(case when a.kpi_period_code = @base_yyyymm then a.production_quantity end),0) / isnull(sum(case when a.kpi_period_code between @vc_pre_13 and @base_yyyymm then a.production_quantity end),0) end AS qty_rate_mon13
              ,case when isnull(max(qty.production_quantity),0) = 0 then 0
                    else isnull(sum(case when a.kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm then a.production_quantity end),0) / isnull(max(qty.production_quantity),0) end AS qty_rate_1_base
        FROM   m_opsmr_tb_op_rate(nolock) a
              ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
              ,(
                select gbu_code
                      ,SUM(production_quantity) AS production_quantity
                from   m_opsmr_tb_op_rate(nolock)
                where  kpi_period_code BETWEEN @vc_start_yyyymm AND @base_yyyymm
                AND    OPSMR_TYPE = 'STD'
                group by gbu_code
              ) qty
        WHERE  a.opsmr_type = @opsmr_type
        AND    a.base_yyyymm = @base_yyyymm
        AND    a.kpi_period_code between @vc_pre_13 and @vc_post_1
        AND    a.factory_region1 = sub.mapping_code
        AND    a.gbu_code = prod.mapping_code
        AND    sub.sheet10_yn = 'Y'
        AND    prod.sheet10_yn = 'Y'
        AND    a.factory_region1 <> 'CROSS(KR)'
        AND    a.gbu_code = qty.gbu_code
        GROUP BY sub.display_name
                ,prod.display_name
      ) a
WHERE  a.post_rate < @base_rate*0.01
and    a.abs_post_rate_gap > @chg_rate*0.01
;

END