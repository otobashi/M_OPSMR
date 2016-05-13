CREATE PROCEDURE [dbo].[m_opsmr_sp_op_rate]
(
  @opsmr_type    VARCHAR(5)
 ,@start_yyyymm  VARCHAR(6)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_op_rate
3. 기     능 : DB2 기준가동률 및 운영가동률을 M_OPSMR_SP_OP_RATE

--   EXEC m_opsmr_sp_op_rate 'STD', '201602', '201602' -- 기준가동율
--   EXEC m_opsmr_sp_op_rate 'PROD', '201602', '201602' -- 운영가동율
             
4. 관 련 화 면 :

버전    작 성 자     일        자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.03.29  최초작성
1.1   shlee      2016.04.05  INPUT_YN 기준적용
1.2   shlee      2016.04.07  scenario_type_code 추가로 인한 변경
1.3   shlee      2016.04.21  날짜와 subsidiary/ Product Master적용
***************************************************************************/

DECLARE @pre_yyyymm   AS VARCHAR(6);
DECLARE @end_yyyymm   AS VARCHAR(6);

SET NOCOUNT ON

SET @pre_yyyymm    = CONVERT(VARCHAR(6), DATEADD(m,-1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직전13개월전
SET @end_yyyymm    = CONVERT(VARCHAR(6), DATEADD(m, 3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- 직전13개월전

BEGIN

-- 실적구간
SELECT sub.display_name as sub
      ,prod.display_name as prod
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,substring(a.yyyymm,1,4)+'-'+substring(a.yyyymm,5,2)+'-'+'01' AS yyyymmdd
      ,b.kpi_type as kpi_type
      ,CASE WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '21' THEN 'Unit'
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '24' THEN '대'
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '02' THEN '대'
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '03' THEN '대'

            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '21' THEN 'MW'
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '24' THEN 'MW'
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '02' THEN 'MW'
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '03' THEN 'MW'

            ELSE b.unit
       END as unit
      ,b.seq as seq
	    ,a.yyyymm as yyyymm
	    ,a.base_yyyymm as base_yyyymm
      ,SUM(
         CASE b.seq
            WHEN '01' THEN a.standard_operation_rate
            WHEN '02' THEN a.production_capa
            WHEN '03' THEN a.production_quantity
            WHEN '04' THEN a.peak_off_season
            WHEN '05' THEN a.total_line_number
            WHEN '06' THEN a.shift_line_number1
            WHEN '07' THEN a.shift_line_number2
            WHEN '08' THEN NULL
            WHEN '09' THEN a.line_count_total
            WHEN '10' THEN a.line_count_use
            WHEN '11' THEN NULL
            WHEN '12' THEN a.total_overtime
            WHEN '13' THEN a.total_holiday_work_time
            WHEN '14' THEN NULL
            WHEN '15' THEN NULL
            WHEN '21' THEN a.production_capa
            WHEN '22' THEN a.line_count_total
            WHEN '23' THEN NULL
            WHEN '24' THEN a.actual_production_capa
            WHEN '25' THEN NULL
            WHEN '26' THEN NULL
            WHEN '27' THEN NULL
            WHEN '28' THEN a.total_overtime
            WHEN '29' THEN a.total_holiday_work_time
            WHEN '30' THEN a.line_count_use
            WHEN '31' THEN a.line_count_idle
         END
       )
       *
       CASE WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '21' THEN 1000
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '24' THEN 1000
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '02' THEN 1000
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '03' THEN 1000

            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '21' THEN 1000
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '24' THEN 1000
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '02' THEN 1000
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '03' THEN 1000

            ELSE 1
       END
       AS val
  FROM m_opsmr_tb_op_rate a
      ,(
        SELECT 'STD' OPSMR_TYPE, '가동률' AS KPI_TYPE, '%' AS UNIT, '01' AS SEQ
        UNION ALL
        SELECT 'STD','기준 Capa','천대','02'
        UNION ALL
        SELECT 'STD','생산 대수','천대','03'
        UNION ALL
        SELECT 'STD','성수기/비수기 구분','-','04'
        UNION ALL
        SELECT 'STD','Shift 운영','','05'
        UNION ALL
        SELECT 'STD','1 Shift 라인','Line','06'
        UNION ALL
        SELECT 'STD','2 Shift 이상 라인','Line','07'
        UNION ALL
        SELECT 'STD','Line 운영','','08'
        UNION ALL
        SELECT 'STD',' 총 조립 라인','Line','09'
        UNION ALL
        SELECT 'STD',' 운영 조립 라인','Line','10'
        UNION ALL
        SELECT 'STD','잔업/특근','시간','11'
        UNION ALL
        SELECT 'STD',' 잔업 시간','시간','12'
        UNION ALL
        SELECT 'STD',' 특근 시간','시간','13'
        UNION ALL
        SELECT 'STD','무 작업율','%','14'
        UNION ALL
        SELECT 'STD','재 작업율','%','15'
        UNION ALL
        SELECT 'PROD','기준 Capa','K Unit','21'
        UNION ALL
        SELECT 'PROD',' 총 라인수','개','22'
        UNION ALL
        SELECT 'PROD','운영 Capa 산정','','23'
        UNION ALL
        SELECT 'PROD',' 운영 Capa','천대','24'
        UNION ALL
        SELECT 'PROD',' 운영 UPH','대/Hour','25'
        UNION ALL
        SELECT 'PROD',' 작업 일수','일','26'
        UNION ALL
        SELECT 'PROD',' 작업 시간','Hour','27'
        UNION ALL
        SELECT 'PROD','. 특근','Hour','28'
        UNION ALL
        SELECT 'PROD','. 잔업','Hour','29'
        UNION ALL
        SELECT 'PROD',' 운영라인수','개','30'
        UNION ALL
        SELECT 'PROD','. 유휴라인','개','31'
      ) b
      , m_opsmr_tb_op_rate_prod_mst(nolock) prod
      , m_opsmr_tb_op_rate_sub_mst(nolock) sub
 WHERE a.opsmr_type  = @opsmr_type
   AND a.opsmr_type  = b.opsmr_type
   AND a.base_yyyymm = @base_yyyymm
   AND a.kpi_period_code between @start_yyyymm and @pre_yyyymm
   AND a.scenario_type_code = 'AC0'
   AND a.factory_region1 = sub.mapping_code
   AND a.gbu_code = prod.mapping_code
   AND sub.use_flag = 'Y'
   AND prod.use_flag = 'Y'
GROUP BY sub.display_name
        ,prod.display_name
        ,substring(a.yyyymm,1,4)+'-'+substring(a.yyyymm,5,2)+'-'+'01'
        ,b.kpi_type
        ,b.seq
        ,b.unit
        ,a.yyyymm
        ,a.base_yyyymm

UNION ALL

-- 계획구간
SELECT sub.display_name as sub
      ,prod.display_name as prod
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,substring(a.yyyymm,1,4)+'-'+substring(a.yyyymm,5,2)+'-'+'01' AS yyyymmdd
      ,b.kpi_type as kpi_type
      ,CASE WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '21' THEN 'Unit'
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '24' THEN '대'
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '02' THEN '대'
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '03' THEN '대'

            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '21' THEN 'MW'
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '24' THEN 'MW'
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '02' THEN 'MW'
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '03' THEN 'MW'

            ELSE b.unit
       END as unit
      ,b.seq as seq
	    ,a.yyyymm as yyyymm
	    ,a.base_yyyymm as base_yyyymm
      ,CASE c.yn
            WHEN 'Y' THEN
                 SUM(
                    CASE b.seq
                       WHEN '01' THEN a.standard_operation_rate
                       WHEN '02' THEN a.production_capa
                       WHEN '03' THEN a.production_quantity
                       WHEN '04' THEN a.peak_off_season
                       WHEN '05' THEN a.total_line_number
                       WHEN '06' THEN a.shift_line_number1
                       WHEN '07' THEN a.shift_line_number2
                       WHEN '08' THEN NULL
                       WHEN '09' THEN a.line_count_total
                       WHEN '10' THEN a.line_count_use
                       WHEN '11' THEN NULL
                       WHEN '12' THEN a.total_overtime
                       WHEN '13' THEN a.total_holiday_work_time
                       WHEN '14' THEN NULL
                       WHEN '15' THEN NULL
                       WHEN '21' THEN a.production_capa
                       WHEN '22' THEN a.line_count_total
                       WHEN '23' THEN NULL
                       WHEN '24' THEN a.actual_production_capa
                       WHEN '25' THEN NULL
                       WHEN '26' THEN NULL
                       WHEN '27' THEN NULL
                       WHEN '28' THEN a.total_overtime
                       WHEN '29' THEN a.total_holiday_work_time
                       WHEN '30' THEN a.line_count_use
                       WHEN '31' THEN a.line_count_idle
                    END
                   )
            
            /*WHEN 'N' THEN*/
            ELSE
                 CASE a.scenario_type_code 
                      WHEN 'AC0' THEN
                           SUM(
                              CASE b.seq
                                 WHEN '01' THEN NULL
                                 WHEN '02' THEN NULL
                                 WHEN '03' THEN a.production_quantity
                                 WHEN '04' THEN NULL
                                 WHEN '05' THEN NULL
                                 WHEN '06' THEN NULL
                                 WHEN '07' THEN NULL
                                 WHEN '08' THEN NULL
                                 WHEN '09' THEN a.line_count_total
                                 WHEN '10' THEN a.line_count_use
                                 WHEN '11' THEN NULL
                                 WHEN '12' THEN NULL
                                 WHEN '13' THEN NULL
                                 WHEN '14' THEN NULL
                                 WHEN '15' THEN NULL
                                 WHEN '21' THEN NULL
                                 WHEN '22' THEN a.line_count_total
                                 WHEN '23' THEN NULL
                                 WHEN '24' THEN NULL
                                 WHEN '25' THEN NULL
                                 WHEN '26' THEN NULL
                                 WHEN '27' THEN NULL
                                 WHEN '28' THEN NULL
                                 WHEN '29' THEN NULL
                                 WHEN '30' THEN a.line_count_use
                                 WHEN '31' THEN a.line_count_idle
                              END
                             )
                    ELSE
                         SUM(
                            CASE b.seq
                               WHEN '01' THEN NULL
                               WHEN '02' THEN NULL
                               WHEN '03' THEN NULL
                               WHEN '04' THEN NULL
                               WHEN '05' THEN NULL
                               WHEN '06' THEN NULL
                               WHEN '07' THEN NULL
                               WHEN '08' THEN NULL
                               WHEN '09' THEN a.line_count_total
                               WHEN '10' THEN a.line_count_use
                               WHEN '11' THEN NULL
                               WHEN '12' THEN NULL
                               WHEN '13' THEN NULL
                               WHEN '14' THEN NULL
                               WHEN '15' THEN NULL
                               WHEN '21' THEN NULL
                               WHEN '22' THEN a.line_count_total
                               WHEN '23' THEN NULL
                               WHEN '24' THEN NULL
                               WHEN '25' THEN NULL
                               WHEN '26' THEN NULL
                               WHEN '27' THEN NULL
                               WHEN '28' THEN NULL
                               WHEN '29' THEN NULL
                               WHEN '30' THEN a.line_count_use
                               WHEN '31' THEN a.line_count_idle
                            END
                           )
                           
               END
       END
       *
       CASE WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '21' THEN 1000
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '24' THEN 1000
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '02' THEN 1000
            WHEN sub.display_name IN ('LGEQA','LGEKR(Chiller)') AND prod.display_name = 'Chiller' AND b.seq = '03' THEN 1000

            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '21' THEN 1000
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '24' THEN 1000
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '02' THEN 1000
            WHEN sub.display_name = 'LGEKR(Solar)' AND prod.display_name = 'Solar' AND b.seq = '03' THEN 1000

            ELSE 1
       END
       AS val
  FROM m_opsmr_tb_op_rate a
    	 LEFT JOIN
       (
         SELECT KIT.FACTORY_REGION1 AS factory_region1
               ,KIT.GBU_CODE AS gbu_code
               ,KIT.INPUT_YN AS YN
			         ,KIT.KPI_PERIOD_CODE AS KPI_PERIOD_CODE
           FROM m_opsrm_tb_kit_temp kit
          WHERE kit.kpi_period_code = @base_yyyymm
       ) c
    	 ON  a.factory_region1 = c.factory_region1
    	 AND a.gbu_code        = c.gbu_code
      ,(
        SELECT 'STD' OPSMR_TYPE, '가동률' AS KPI_TYPE, '%' AS UNIT, '01' AS SEQ
        UNION ALL
        SELECT 'STD','기준 Capa','천대','02'
        UNION ALL
        SELECT 'STD','생산 대수','천대','03'
        UNION ALL
        SELECT 'STD','성수기/비수기 구분','-','04'
        UNION ALL
        SELECT 'STD','Shift 운영','','05'
        UNION ALL
        SELECT 'STD','1 Shift 라인','Line','06'
        UNION ALL
        SELECT 'STD','2 Shift 이상 라인','Line','07'
        UNION ALL
        SELECT 'STD','Line 운영','','08'
        UNION ALL
        SELECT 'STD',' 총 조립 라인','Line','09'
        UNION ALL
        SELECT 'STD',' 운영 조립 라인','Line','10'
        UNION ALL
        SELECT 'STD','잔업/특근','시간','11'
        UNION ALL
        SELECT 'STD',' 잔업 시간','시간','12'
        UNION ALL
        SELECT 'STD',' 특근 시간','시간','13'
        UNION ALL
        SELECT 'STD','무 작업율','%','14'
        UNION ALL
        SELECT 'STD','재 작업율','%','15'
        UNION ALL
        SELECT 'PROD','기준 Capa','K Unit','21'
        UNION ALL
        SELECT 'PROD',' 총 라인수','개','22'
        UNION ALL
        SELECT 'PROD','운영 Capa 산정','','23'
        UNION ALL
        SELECT 'PROD',' 운영 Capa','천대','24'
        UNION ALL
        SELECT 'PROD',' 운영 UPH','대/Hour','25'
        UNION ALL
        SELECT 'PROD',' 작업 일수','일','26'
        UNION ALL
        SELECT 'PROD',' 작업 시간','Hour','27'
        UNION ALL
        SELECT 'PROD','. 특근','Hour','28'
        UNION ALL
        SELECT 'PROD','. 잔업','Hour','29'
        UNION ALL
        SELECT 'PROD',' 운영라인수','개','30'
        UNION ALL
        SELECT 'PROD','. 유휴라인','개','31'
      ) b
      , m_opsmr_tb_op_rate_prod_mst(nolock) prod
      , m_opsmr_tb_op_rate_sub_mst(nolock) sub
 WHERE a.opsmr_type  = @opsmr_type
   AND a.opsmr_type  = b.opsmr_type
   AND a.base_yyyymm = @base_yyyymm
   AND a.kpi_period_code >= @base_yyyymm
   AND a.scenario_type_code IN ('AC0','PR1','PR2','PR3')
   AND a.factory_region1 = sub.mapping_code
   AND a.gbu_code = prod.mapping_code
   AND sub.use_flag = 'Y'
   AND prod.use_flag = 'Y'
GROUP BY sub.display_name
        ,prod.display_name
        ,substring(a.yyyymm,1,4)+'-'+substring(a.yyyymm,5,2)+'-'+'01'
        ,b.kpi_type
        ,b.seq
        ,b.unit
        ,c.yn
        ,a.scenario_type_code
        ,a.yyyymm
        ,a.base_yyyymm
        

;

END