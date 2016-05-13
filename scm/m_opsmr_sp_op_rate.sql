ALTER PROCEDURE [dbo].[m_opsmr_sp_op_rate]
(
  @opsmr_type    VARCHAR(5)
 ,@start_yyyymm  VARCHAR(6)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. �� �� �� Ʈ : M_OPSMR
2. ���α׷� ID : m_opsmr_sp_op_rate
3. ��     �� : DB2 ���ذ����� �� ��������� M_OPSMR_SP_OP_RATE

--   EXEC m_opsmr_sp_op_rate 'STD', '201602', '201602' -- ���ذ�����
--   EXEC m_opsmr_sp_op_rate 'PROD', '201602', '201602' -- �������
             
4. �� �� ȭ �� :

����    �� �� ��     ��        ��    ��                                        ��
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.03.29  �����ۼ�
1.1   shlee      2016.04.05  INPUT_YN ��������
1.2   shlee      2016.04.07  scenario_type_code �߰��� ���� ����
1.3   shlee      2016.04.21  ��¥�� subsidiary/ Product Master����
***************************************************************************/

DECLARE @pre_yyyymm   AS VARCHAR(6);
DECLARE @end_yyyymm   AS VARCHAR(6);

SET NOCOUNT ON

SET @pre_yyyymm    = CONVERT(VARCHAR(6), DATEADD(m,-1, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����13������
SET @end_yyyymm    = CONVERT(VARCHAR(6), DATEADD(m, 3, CONVERT(DATETIME,@base_yyyymm + '01')), 112);    -- ����13������

BEGIN

SELECT *
FROM (
-- ��������
SELECT sub.display_name as sub
      ,prod.display_name as prod
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,substring(a.yyyymm,1,4)+'-'+substring(a.yyyymm,5,2)+'-'+'01' AS yyyymmdd
      ,b.kpi_type as kpi_type
      ,CASE WHEN sub.display_name IN ('LGEQA','LGEKR') AND prod.display_name = 'Chiller' AND b.seq = '21' THEN 'Unit'
            WHEN sub.display_name IN ('LGEQA','LGEKR') AND prod.display_name = 'Chiller' AND b.seq = '24' THEN '��'
            WHEN sub.display_name IN ('LGEQA','LGEKR') AND prod.display_name = 'Chiller' AND b.seq = '02' THEN '��'
            WHEN sub.display_name IN ('LGEQA','LGEKR') AND prod.display_name = 'Chiller' AND b.seq = '03' THEN '��'

            WHEN sub.display_name = 'LGEKR' AND prod.display_name = 'Solar' AND b.seq = '21' THEN 'MW'
            WHEN sub.display_name = 'LGEKR' AND prod.display_name = 'Solar' AND b.seq = '24' THEN 'MW'
            WHEN sub.display_name = 'LGEKR' AND prod.display_name = 'Solar' AND b.seq = '02' THEN 'MW'
            WHEN sub.display_name = 'LGEKR' AND prod.display_name = 'Solar' AND b.seq = '03' THEN 'MW'

            ELSE b.unit
       END as unit
      ,b.seq as seq
	    ,a.yyyymm as yyyymm
	    ,a.base_yyyymm as base_yyyymm
      ,(
         CASE b.seq
            WHEN '01' THEN ( CASE WHEN ISNULL(SUM(a.production_capa),0) = 0 THEN 0 ELSE SUM(a.production_quantity) / SUM(a.production_capa) END )
            WHEN '02' THEN SUM(a.production_capa)
            WHEN '03' THEN SUM(a.production_quantity)
            WHEN '04' THEN SUM(a.peak_off_season)
            WHEN '05' THEN SUM(a.total_line_number)
            WHEN '06' THEN SUM(a.shift_line_number1)
            WHEN '07' THEN SUM(a.shift_line_number2)
            WHEN '08' THEN NULL
            WHEN '09' THEN SUM(a.line_count_total)
            WHEN '10' THEN SUM(a.line_count_use)
            WHEN '11' THEN NULL
            WHEN '12' THEN SUM(a.total_overtime)
            WHEN '13' THEN SUM(a.total_holiday_work_time)
            WHEN '14' THEN NULL
            WHEN '15' THEN NULL
            WHEN '21' THEN SUM(a.production_capa)
            WHEN '22' THEN SUM(a.line_count_total)
            WHEN '23' THEN NULL
            WHEN '24' THEN SUM(a.actual_production_capa)
            WHEN '25' THEN NULL
            WHEN '26' THEN NULL
            WHEN '27' THEN NULL
            WHEN '28' THEN SUM(a.total_overtime)
            WHEN '29' THEN SUM(a.total_holiday_work_time)
            WHEN '30' THEN SUM(a.line_count_use)
            WHEN '31' THEN SUM(a.line_count_idle)
         END
       )
       AS val
  FROM m_opsmr_tb_op_rate a
      ,(
        SELECT 'STD' OPSMR_TYPE, '������' AS KPI_TYPE, '%' AS UNIT, '01' AS SEQ
        UNION ALL
        SELECT 'STD','���� Capa','õ��','02'
        UNION ALL
        SELECT 'STD','���� ���','õ��','03'
        UNION ALL
        SELECT 'STD','������/����� ����','-','04'
        UNION ALL
        SELECT 'STD','Shift �','','05'
        UNION ALL
        SELECT 'STD','1 Shift ����','Line','06'
        UNION ALL
        SELECT 'STD','2 Shift �̻� ����','Line','07'
        UNION ALL
        SELECT 'STD','Line �','','08'
        UNION ALL
        SELECT 'STD',' �� ���� ����','Line','09'
        UNION ALL
        SELECT 'STD',' � ���� ����','Line','10'
        UNION ALL
        SELECT 'STD','�ܾ�/Ư��','�ð�','11'
        UNION ALL
        SELECT 'STD',' �ܾ� �ð�','�ð�','12'
        UNION ALL
        SELECT 'STD',' Ư�� �ð�','�ð�','13'
        UNION ALL
        SELECT 'STD','�� �۾���','%','14'
        UNION ALL
        SELECT 'STD','�� �۾���','%','15'
        UNION ALL
        SELECT 'PROD','���� Capa','K Unit','21'
        UNION ALL
        SELECT 'PROD',' �� ���μ�','��','22'
        UNION ALL
        SELECT 'PROD','� Capa ����','','23'
        UNION ALL
        SELECT 'PROD',' � Capa','õ��','24'
        UNION ALL
        SELECT 'PROD',' � UPH','��/Hour','25'
        UNION ALL
        SELECT 'PROD',' �۾� �ϼ�','��','26'
        UNION ALL
        SELECT 'PROD',' �۾� �ð�','Hour','27'
        UNION ALL
        SELECT 'PROD','. Ư��','Hour','28'
        UNION ALL
        SELECT 'PROD','. �ܾ�','Hour','29'
        UNION ALL
        SELECT 'PROD',' ����μ�','��','30'
        UNION ALL
        SELECT 'PROD','. ���޶���','��','31'
      ) b
      , m_opsmr_tb_op_rate_prod_mst(nolock) prod
      , m_opsmr_tb_op_rate_sub_mst(nolock) sub
 WHERE a.opsmr_type  = @opsmr_type
   AND a.opsmr_type  = b.opsmr_type
   AND a.base_yyyymm = @base_yyyymm
   AND a.kpi_period_code between @start_yyyymm and @pre_yyyymm
   AND a.factory_region1 = sub.mapping_code
   AND a.gbu_code = prod.mapping_code
   AND sub.sheet01_yn = 'Y'
   AND prod.sheet01_yn = 'Y'
GROUP BY sub.display_name
        ,prod.display_name
        ,substring(a.yyyymm,1,4)+'-'+substring(a.yyyymm,5,2)+'-'+'01'
        ,b.kpi_type
        ,b.seq
        ,b.unit
        ,a.yyyymm
        ,a.base_yyyymm

UNION ALL

-- ��ȹ����
SELECT sub.display_name as sub
      ,prod.display_name as prod
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
      ,substring(a.yyyymm,1,4)+'-'+substring(a.yyyymm,5,2)+'-'+'01' AS yyyymmdd
      ,b.kpi_type as kpi_type
      ,CASE WHEN sub.display_name IN ('LGEQA','LGEKR') AND prod.display_name = 'Chiller' AND b.seq = '21' THEN 'Unit'
            WHEN sub.display_name IN ('LGEQA','LGEKR') AND prod.display_name = 'Chiller' AND b.seq = '24' THEN '��'
            WHEN sub.display_name IN ('LGEQA','LGEKR') AND prod.display_name = 'Chiller' AND b.seq = '02' THEN '��'
            WHEN sub.display_name IN ('LGEQA','LGEKR') AND prod.display_name = 'Chiller' AND b.seq = '03' THEN '��'

            WHEN sub.display_name = 'LGEKR' AND prod.display_name = 'Solar' AND b.seq = '21' THEN 'MW'
            WHEN sub.display_name = 'LGEKR' AND prod.display_name = 'Solar' AND b.seq = '24' THEN 'MW'
            WHEN sub.display_name = 'LGEKR' AND prod.display_name = 'Solar' AND b.seq = '02' THEN 'MW'
            WHEN sub.display_name = 'LGEKR' AND prod.display_name = 'Solar' AND b.seq = '03' THEN 'MW'

            ELSE b.unit
       END as unit
      ,b.seq as seq
	    ,a.yyyymm as yyyymm
	    ,a.base_yyyymm as base_yyyymm
      ,CASE c.yn
            WHEN 'Y' THEN
                 (
                   CASE b.seq
                      WHEN '01' THEN ( CASE WHEN ISNULL(SUM(a.production_capa),0) = 0 THEN 0 ELSE SUM(a.production_quantity) / SUM(a.production_capa) END )
                      WHEN '02' THEN SUM(a.production_capa)
                      WHEN '03' THEN SUM(a.production_quantity)
                      WHEN '04' THEN SUM(a.peak_off_season)
                      WHEN '05' THEN SUM(a.total_line_number)
                      WHEN '06' THEN SUM(a.shift_line_number1)
                      WHEN '07' THEN SUM(a.shift_line_number2)
                      WHEN '08' THEN NULL
                      WHEN '09' THEN SUM(a.line_count_total)
                      WHEN '10' THEN SUM(a.line_count_use)
                      WHEN '11' THEN NULL
                      WHEN '12' THEN SUM(a.total_overtime)
                      WHEN '13' THEN SUM(a.total_holiday_work_time)
                      WHEN '14' THEN NULL
                      WHEN '15' THEN NULL
                      WHEN '21' THEN SUM(a.production_capa)
                      WHEN '22' THEN SUM(a.line_count_total)
                      WHEN '23' THEN NULL
                      WHEN '24' THEN SUM(a.actual_production_capa)
                      WHEN '25' THEN NULL
                      WHEN '26' THEN NULL
                      WHEN '27' THEN NULL
                      WHEN '28' THEN SUM(a.total_overtime)
                      WHEN '29' THEN SUM(a.total_holiday_work_time)
                      WHEN '30' THEN SUM(a.line_count_use)
                      WHEN '31' THEN SUM(a.line_count_idle)
                   END
                 )
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
       AS val
  FROM m_opsmr_tb_op_rate a
    	 LEFT JOIN
       (
         SELECT CASE KIT.FACTORY_REGION1
                     WHEN 'LGEAK'                   THEN 'LGEAK'
                     WHEN 'LGEAT'                   THEN 'LGEAT'
                     WHEN 'LGEEG'                   THEN 'LGEEG'
                     WHEN 'LGEHN'                   THEN 'LGEHN'
                     WHEN 'LGEHZ'                   THEN 'LGEHZ'
                     WHEN 'LGEIL(Noida)'            THEN 'LGEIL(Noida)'
                     WHEN 'LGEIL(Pune)'             THEN 'LGEIL(Pune)'
                     WHEN 'LGEIN(Cibit)'            THEN 'LGEIN'
                     WHEN 'LGEIN(Tang)'             THEN 'LGEIN'
                     WHEN 'LGEKR(AC)'               THEN 'LGEKR'
                     WHEN 'LGEKR(BdMS)'             THEN 'LGEKR'
                     WHEN 'LGEKR(C&M)'              THEN 'LGEKR'
                     WHEN 'LGEKR(CAV)'              THEN 'LGEKR'
                     WHEN 'LGEKR(CEM)'              THEN 'LGEKR'
                     WHEN 'LGEKR(Chiller)'          THEN 'LGEKR'
                     WHEN 'LGEKR(CommercialWater)'  THEN 'LGEKR'
                     WHEN 'LGEKR(IT)'               THEN 'LGEKR'
                     WHEN 'LGEKR(IVI)'              THEN 'LGEKR'
                     WHEN 'LGEKR(KitchenPackage)'   THEN 'LGEKR'
                     WHEN 'LGEKR(Lighting)'         THEN 'LGEKR'
                     WHEN 'LGEKR(Mobile)'           THEN 'LGEKR'
                     WHEN 'LGEKR(REF)'              THEN 'LGEKR'
                     WHEN 'LGEKR(Solar)'            THEN 'LGEKR'
                     WHEN 'LGEKR(TV)'               THEN 'LGEKR'
                     WHEN 'LGEKR(WM)'               THEN 'LGEKR'
                     WHEN 'LGEKS'                   THEN 'LGEKS'
                     WHEN 'LGEMA'                   THEN 'LGEMA'
                     WHEN 'LGEMM'                   THEN 'LGEMM'
                     WHEN 'LGEMX'                   THEN 'LGEMX'
                     WHEN 'LGEND'                   THEN 'LGEND'
                     WHEN 'LGEPN'                   THEN 'LGEPN'
                     WHEN 'LGEQA'                   THEN 'LGEQA'
                     WHEN 'LGEQD'                   THEN 'LGEQD'
                     WHEN 'LGEQH'                   THEN 'LGEQH'
                     WHEN 'LGERA'                   THEN 'LGERA'
                     WHEN 'LGERS'                   THEN 'LGERS'
                     WHEN 'LGESA'                   THEN 'LGESA'
                     WHEN 'LGESH'                   THEN 'LGESH'
                     WHEN 'LGESR'                   THEN 'LGESR'
                     WHEN 'LGESY'                   THEN 'LGESY'
                     WHEN 'LGETA'                   THEN 'LGETA'
                     WHEN 'LGETH'                   THEN 'LGETH'
                     WHEN 'LGETR'                   THEN 'LGETR'
                     WHEN 'LGEWR'                   THEN 'LGEWR'
                     WHEN 'LGEYT'                   THEN 'LGEYT'
                     ELSE KIT.FACTORY_REGION1
                END AS FACTORY_REGION1
               ,CASE KIT.FACTORY_REGION1+KIT.GBU_CODE
                     WHEN 'LGEMM'+'CVT' THEN 'CVTC11'
                     WHEN 'LGETA'+'CVT' THEN 'CVTC7'
                     WHEN 'LGEAZ'+'CVT' THEN 'CVTC7'
                     WHEN 'LGESP(Mao)'+'CVT' THEN 'CVTC7'
                     WHEN 'LGETH'+'CVT' THEN 'CVTC7'
                     WHEN 'LGEVH'+'CVT' THEN 'CVTC7'
                     WHEN 'LGEVN(HP)'+'CVT' THEN 'CVTC7'
                     WHEN 'LGEIL(Noida)'+'CVT' THEN 'CVTC7'
                     ELSE KIT.GBU_CODE END
                AS gbu_code
               ,KIT.INPUT_YN AS YN
			         ,KIT.KPI_PERIOD_CODE AS KPI_PERIOD_CODE
           FROM m_opsrm_tb_kit_temp kit
          WHERE kit.kpi_period_code = @base_yyyymm
          UNION ALL
          SELECT 'LGEKR'
                ,'CVTC7'
                ,INPUT_YN
                ,KPI_PERIOD_CODE
           FROM m_opsrm_tb_kit_temp
          WHERE kpi_period_code = @base_yyyymm
          AND   FACTORY_REGION1 = 'LGEKR(Kitchen Package)'
          AND   GBU_CODE = 'CVT'
          UNION ALL
          SELECT 'LGEKR'
                ,'CVTC11'
                ,INPUT_YN
                ,KPI_PERIOD_CODE
           FROM m_opsrm_tb_kit_temp
          WHERE kpi_period_code = @base_yyyymm
          AND   FACTORY_REGION1 = 'LGEKR(Kitchen Package)'
          AND   GBU_CODE = 'CVT'
          
       ) c
    	 ON  a.factory_region1 = c.factory_region1
    	 AND c.gbu_code = (CASE a.factory_region1+a.gbu_code WHEN 'LGEQH'+'DQT' THEN 'DHT' ELSE a.gbu_code END )
    	 AND a.opsmr_type      = @opsmr_type
       AND a.base_yyyymm     = @base_yyyymm
       AND a.kpi_period_code BETWEEN @base_yyyymm AND @end_yyyymm
      ,(
        SELECT 'STD' OPSMR_TYPE, '������' AS KPI_TYPE, '%' AS UNIT, '01' AS SEQ
        UNION ALL
        SELECT 'STD','���� Capa','õ��','02'
        UNION ALL
        SELECT 'STD','���� ���','õ��','03'
        UNION ALL
        SELECT 'STD','������/����� ����','-','04'
        UNION ALL
        SELECT 'STD','Shift �','','05'
        UNION ALL
        SELECT 'STD','1 Shift ����','Line','06'
        UNION ALL
        SELECT 'STD','2 Shift �̻� ����','Line','07'
        UNION ALL
        SELECT 'STD','Line �','','08'
        UNION ALL
        SELECT 'STD',' �� ���� ����','Line','09'
        UNION ALL
        SELECT 'STD',' � ���� ����','Line','10'
        UNION ALL
        SELECT 'STD','�ܾ�/Ư��','�ð�','11'
        UNION ALL
        SELECT 'STD',' �ܾ� �ð�','�ð�','12'
        UNION ALL
        SELECT 'STD',' Ư�� �ð�','�ð�','13'
        UNION ALL
        SELECT 'STD','�� �۾���','%','14'
        UNION ALL
        SELECT 'STD','�� �۾���','%','15'
        UNION ALL
        SELECT 'PROD','���� Capa','K Unit','21'
        UNION ALL
        SELECT 'PROD',' �� ���μ�','��','22'
        UNION ALL
        SELECT 'PROD','� Capa ����','','23'
        UNION ALL
        SELECT 'PROD',' � Capa','õ��','24'
        UNION ALL
        SELECT 'PROD',' � UPH','��/Hour','25'
        UNION ALL
        SELECT 'PROD',' �۾� �ϼ�','��','26'
        UNION ALL
        SELECT 'PROD',' �۾� �ð�','Hour','27'
        UNION ALL
        SELECT 'PROD','. Ư��','Hour','28'
        UNION ALL
        SELECT 'PROD','. �ܾ�','Hour','29'
        UNION ALL
        SELECT 'PROD',' ����μ�','��','30'
        UNION ALL
        SELECT 'PROD','. ���޶���','��','31'
      ) b
      , m_opsmr_tb_op_rate_prod_mst(nolock) prod
      , m_opsmr_tb_op_rate_sub_mst(nolock) sub
 WHERE a.opsmr_type  = @opsmr_type
   AND a.opsmr_type  = b.opsmr_type
   AND a.base_yyyymm = @base_yyyymm
   AND a.kpi_period_code BETWEEN @base_yyyymm AND @end_yyyymm
   AND a.factory_region1 = sub.mapping_code
   AND a.gbu_code = prod.mapping_code
   AND sub.sheet01_yn = 'Y'
   AND prod.sheet01_yn = 'Y'
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
) A
WHERE A.sub+A.prod NOT IN ('LGEHZPhotoPrinter'
,'LGEIL(Noida)MWO'
,'LGEIL(Noida)Motor'
,'LGEVHCAC'
,'LGEKRMGT'
,'LGEKRCommercialWater'
,'LGEKRPhotoPrinter'
,'LGEKRBdMS'
,'����KRLTV'
,'����KRRAC'
)       

;

END