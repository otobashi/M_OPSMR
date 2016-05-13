ALTER PROCEDURE [dbo].[m_opsmr_sp_rate_120_more]
(
  @opsmr_type    VARCHAR(5)
 ,@base_yyyymm   VARCHAR(6)
 ,@base_rate     FLOAT
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_rate_120_more
3. ��     �� : DB2 ���ذ����� �� ��������� m_opsmr_sp_rate_120_more

--   EXEC m_opsmr_sp_rate_120_more 'STD', '201603', 120

4. �� �� ȭ �� :

����  �� �� ��   ��      ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.11  �����ۼ�
1.1   shlee      2016.04.21  ��¥�� subsidiary/ Product Master����
1.2   shlee      2016.04.22  * 100 ����
***************************************************************************/

DECLARE @vc_post_1               AS VARCHAR(6);
DECLARE @vc_post_2               AS VARCHAR(6);
DECLARE @vc_post_3               AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_post_1      = CONVERT(VARCHAR(6), DATEADD(m,  1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����
SET @vc_post_2      = CONVERT(VARCHAR(6), DATEADD(m,  2, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����
SET @vc_post_3      = CONVERT(VARCHAR(6), DATEADD(m,  3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����

BEGIN


SELECT sub
      ,prod
      ,sub_enm
      ,sub_knm
      ,prod_enm
      ,prod_knm
      ,cur_rate
      ,cur_qty
      ,pr1_rate
      ,pr1_qty
      ,pr2_rate
      ,pr2_qty
      ,pr3_rate
      ,pr3_qty
      ,max_3mon
      ,plan_rate
      ,plan_qty
      ,vs_rate
      ,vs_qty
FROM (
      SELECT sub.display_name AS sub
            ,prod.display_name AS prod
      	    ,MIN(sub.display_enm) as sub_enm
            ,MIN(sub.display_knm) as sub_knm
            ,MIN(prod.display_enm) as prod_enm
            ,MIN(prod.display_knm) as prod_knm
            ,case when sum(case when a.kpi_period_code = @base_yyyymm then production_capa end) = 0 then 0
                  else sum(case when a.kpi_period_code = @base_yyyymm then production_quantity end) / sum(case when a.kpi_period_code = @base_yyyymm then production_capa end) end AS cur_rate
            ,sum(case when a.kpi_period_code = @base_yyyymm then production_quantity end) AS cur_qty
            ,case when sum(case when a.kpi_period_code = @vc_post_1 then production_capa end) = 0 then 0
                  else sum(case when a.kpi_period_code = @vc_post_1 then production_quantity end) / sum(case when a.kpi_period_code = @vc_post_1 then production_capa end) end AS pr1_rate
            ,sum(case when a.kpi_period_code = @vc_post_1 then production_quantity end) AS pr1_qty
            ,case when sum(case when a.kpi_period_code = @vc_post_2 then production_capa end) = 0 then 0
                  else sum(case when a.kpi_period_code = @vc_post_2 then production_quantity end) / sum(case when a.kpi_period_code = @vc_post_2 then production_capa end) end AS pr2_rate
            ,sum(case when a.kpi_period_code = @vc_post_2 then production_quantity end) AS pr2_qty
            ,case when sum(case when a.kpi_period_code = @vc_post_3 then production_capa end) = 0 then 0
                  else sum(case when a.kpi_period_code = @vc_post_3 then production_quantity end) / sum(case when a.kpi_period_code = @vc_post_3 then production_capa end) end AS pr3_rate
            ,sum(case when a.kpi_period_code = @vc_post_3 then production_quantity end) AS pr3_qty
            ,max(case when a.kpi_period_code in (@vc_post_1,@vc_post_2,@vc_post_3) then standard_operation_rate end) AS max_3mon
            ,case when sum(case when a.kpi_period_code in (@vc_post_1,@vc_post_2,@vc_post_3) then production_capa end) = 0 then 0
                  else sum(case when a.kpi_period_code in (@vc_post_1,@vc_post_2,@vc_post_3) then production_quantity end) / sum(case when a.kpi_period_code in (@vc_post_1,@vc_post_2,@vc_post_3) then production_capa end) end AS plan_rate
            ,SUM(case when a.kpi_period_code in (@vc_post_1,@vc_post_2,@vc_post_3) then production_quantity end)/3 AS plan_qty
            ,(case when sum(case when a.kpi_period_code in (@vc_post_1,@vc_post_2,@vc_post_3) then production_capa end) = 0 then 0
                  else sum(case when a.kpi_period_code in (@vc_post_1,@vc_post_2,@vc_post_3) then production_quantity end) / sum(case when a.kpi_period_code in (@vc_post_1,@vc_post_2,@vc_post_3) then production_capa end) end )
             -
             (case when sum(case when a.kpi_period_code = @base_yyyymm then production_capa end) = 0 then 0
                  else sum(case when a.kpi_period_code = @base_yyyymm then production_quantity end) / sum(case when a.kpi_period_code = @base_yyyymm then production_capa end) end ) AS vs_rate
            ,(SUM(case when a.kpi_period_code in (@vc_post_1,@vc_post_2,@vc_post_3) then production_quantity end)/3)  - sum(case when a.kpi_period_code = @base_yyyymm then production_quantity end) AS vs_qty
      FROM   m_opsmr_tb_op_rate(nolock) a
            ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
            ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
      WHERE  opsmr_type = @opsmr_type
      AND    a.kpi_period_code BETWEEN @base_yyyymm AND @vc_post_3
      AND    a.factory_region1 = sub.mapping_code
      AND    a.gbu_code = prod.mapping_code
      AND    sub.sheet14_yn = 'Y'
      AND    prod.sheet14_yn = 'Y'
      GROUP BY sub.display_name
              ,prod.display_name
     ) a
--where  a.plan_rate >= @base_rate*0.01
where  a.max_3mon >= @base_rate*0.01
;

END