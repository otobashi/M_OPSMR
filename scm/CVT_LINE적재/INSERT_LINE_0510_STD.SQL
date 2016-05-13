INSERT INTO  dbo.M_OPSMR_TB_OP_RATE_LINE
(
    MONTH_RN                     
   ,TARGET_CODE                  
   ,KPI_PERIOD_CODE              
   ,YYYYMM                       
   ,YEAR                         
   ,MON                          
   ,FACTORY_REGION1              
   ,GBU_CODE                     
   ,GBU_NAME                     
   ,DATE_CODE                    
   ,WIP_LINE_CODE                
   ,WIP_LINE_DESC                
   ,STANDARD_OPERATION_RATE      
   ,PRODUCTION_QUANTITY          
   ,PRODUCTION_CAPA              
   ,PEAK_OFF_SEASON              
   ,TOTAL_LINE_NUMBER            
   ,SHIFT_LINE_NUMBER1           
   ,SHIFT_LINE_NUMBER2           
   ,LINE_COUNT_TOTAL             
   ,LINE_COUNT_USE               
   ,LINE_COUNT_IDLE              
   ,TOTAL_OVERTIME               
   ,TOTAL_HOLIDAY_WORK_TIME      
   ,OVERTIME_PER_PERSON          
   ,HOLIDAY_WORKTIME_PER_PERSON  
   ,WORKER_NUMBER_TOTAL          
   ,ACTUAL_OPERATION_RATE        
   ,ACTUAL_PRODUCTION_CAPA       
   ,DUMMY1                       
   ,DUMMY2                       
   ,DUMMY3                       
   ,DUMMY4                       
   ,DUMMY5                       
   ,OPSMR_TYPE                   
   ,BASE_YYYYMM                  
   ,SCENARIO_TYPE_CODE           
)
SELECT std.month_rn AS MONTH_RN
      ,std.target_code AS TARGET_CODE
      ,std.kpi_period_code AS KPI_PERIOD_CODE
      ,std.yyyymm AS YYYYMM
      ,std.year AS YEAR
      ,std.mon AS MON
      ,CASE WHEN std.factory_region1 =  'LGEKR(Kitchen Package)' THEN 'LGEKR' ELSE std.factory_region1 END AS FACTORY_REGION1
      ,std.gbu_code+std.wip_line_code AS GBU_CODE
      ,std.gbu_code AS GBU_NAME
      ,std.date_code AS DATE_CODE
      ,std.wip_line_code AS WIP_LINE_CODE
      ,std.wip_line_desc AS WIP_LINE_DESC
      ,std.standard_operation_rate AS STANDARD_OPERATION_RATE
      ,std.production_quantity AS PRODUCTION_QUANTITY
      ,std.production_capa AS PRODUCTION_CAPA
      ,'' AS PEAK_OFF_SEASON
      ,std.line_quantity_for_day + std.line_quantity_for_night AS TOTAL_LINE_NUMBER
      ,std.line_quantity_for_day AS SHIFT_LINE_NUMBER1
      ,std.line_quantity_for_night AS SHIFT_LINE_NUMBER2
      ,1 AS LINE_COUNT_TOTAL
      ,CASE WHEN NULLIF(std.production_quantity,0) = 0 THEN 0 ELSE 1 END AS LINE_COUNT_USE
      ,CASE WHEN NULLIF(std.production_quantity,0) = 0 THEN 1 ELSE 0 END AS LINE_COUNT_IDLE
      ,NULL AS TOTAL_OVERTIME
      ,NULL AS TOTAL_HOLIDAY_WORK_TIME
      ,NULL AS OVERTIME_PER_PERSON
      ,NULL AS HOLIDAY_WORKTIME_PER_PERSON
      ,NULL AS WORKER_NUMBER_TOTAL
      ,NULL AS ACTUAL_OPERATION_RATE
      ,NULL AS ACTUAL_PRODUCTION_CAPA
      ,NULL AS DUMMY1
      ,NULL AS DUMMY2
      ,NULL AS DUMMY3
      ,NULL AS DUMMY4
      ,NULL AS DUMMY5
      ,'STD' AS OPSMR_TYPE
      ,'201604' AS BASE_YYYYMM
      ,CASE WHEN std.kpi_period_code <= '201604' THEN 'AC0'
	        WHEN std.kpi_period_code = '201605' THEN 'PR1'
			WHEN std.kpi_period_code = '201606' THEN 'PR2'
			WHEN std.kpi_period_code = '201607' THEN 'PR3' END AS SCENARIO_TYPE_CODE
  FROM OPENQUERY(LS_LGEDWDBSE1Q_EDWPROD_OD_APP,'
SELECT MONTH_rn,
       LINE_rn,
       A.TARGET_CODE,
       EYP.KPI_PERIOD_CODE ,
       YYYYMM,
       YEAR,
       MON,
       EYP.FACTORY_REGION1,
       EYP.GBU_CODE,
       EYP.WIP_LINE_CODE,
       EYP.WIP_LINE_DESC,
       CASE WHEN EYP.CROSS_LINE_YN = ''Y'' THEN 1 ELSE 0 END AS CROSS_LINE_CNT,
       CASE WHEN VI.VIRTUAL_LINE_CODE IS NOT NULL THEN 1 ELSE 0 END AS VIRTUAL_LINE_CNT,
       ''M'' AS DATE_CODE ,
       STANDARD_OPERATION_RATE/100 AS STANDARD_OPERATION_RATE,
       CASE WHEN VALUE(AL.PRODUCTION_QUANTITY,0)=0 THEN
                 CASE WHEN A.PRODUCTION_QUANTITY IS NULL THEN VALUE(FF.PRODUCTION_QUANTITY,0)
                      ELSE VALUE(A.PRODUCTION_QUANTITY,0)
                 END
            ELSE VALUE(AL.PRODUCTION_QUANTITY,0)
       END AS PRODUCTION_QUANTITY ,
       CASE WHEN VALUE(AL.PRODUCTION_QUANTITY,0) = 0 THEN
                 CASE WHEN A.PRODUCTION_QUANTITY IS NULL THEN 3
                      WHEN A.PRODUCTION_QUANTITY IS NOT NULL AND EYP.CROSS_LINE_YN = ''Y'' THEN 1
                      ELSE 2
                 END
            ELSE 1
       END AS QUANTITY_SOURCE ,
       PRODUCTION_CAPA,
       UPH,
       WORKING_HOUR,
       NORMAL_WORKING_HOUR,
       OVERTIME_WORKING_HOUR,
       WORKING_DAY,
       NORMAL_WORKING_DAY,
       HOLIDAY_WORKING_DAY,
       TARGET_EFFICIENCY/100 AS TARGET_EFFICIENCY,
       OPERATION_SHIFT,
       LINE_QUANTITY_FOR_DAY,
       LINE_QUANTITY_FOR_NIGHT,
       PRODUCT_WEIGHT/100 AS PRODUCT_WEIGHT,
       ACTUAL_WORKING_DAY
  FROM (
          SELECT KWL.FACTORY_REGION1
               , KWL.GBU_CODE
               , EYP.KPI_PERIOD_CODE
               , EYP.YYYYMM
               , EYP.YEAR
               , EYP.MON
               , KWL.WIP_LINE_CODE
               , KWL.WIP_LINE_DESC
               , KWL.CROSS_LINE_YN
               , MONTH_rn
               , LINE_rn
            FROM (
                    SELECT ROWNUMBER() OVER(ORDER BY T.YYYYMM_ORIG_ID ) AS MONTH_rn
                         , T.YYYYMM_ORIG_ID AS KPI_PERIOD_CODE
                         , max(T.YYYYMM_ORIG_ID) as YYYYMM
                         , MAX(SUBSTR(T.YYYYMM_ORIG_ID,1,4)) AS YEAR
                         , MAX(SUBSTR(T.YYYYMM_STD1_NAME,1,3)) AS MON
                      FROM ENTMT.ED_YYYYMMDD_PD T
                     WHERE T.YYYYMM_ORIG_ID BETWEEN ''201001'' AND ''201607''
                     GROUP BY T.YYYYMM_ORIG_ID
                 ) EYP ,
                 (
                    SELECT L.FACTORY_REGION1
                         , L.GBU_CODE
                         , L.WIP_LINE_CODE
                         , L.WIP_LINE_DESC
                         , L.CROSS_LINE_YN
                         , ROWNUMBER() OVER(ORDER BY L.CROSS_LINE_YN, L.CROSS_LINE_ACTIVE_YN DESC, L.MAP_LINE_CODE, L.LINE_RN_1, L.WIP_LINE_CODE) AS LINE_rn
                      FROM (
                              SELECT L.FACTORY_REGION1
                                   , L.GBU_CODE
                                   , RTRIM(TRIM(L.WIP_LINE_CODE)) AS WIP_LINE_CODE
                                   , RTRIM(TRIM(L.WIP_LINE_DESC)) AS WIP_LINE_DESC
                                   , RTRIM(TRIM(L.WIP_LINE_CODE)) AS MAP_LINE_CODE
                                   , 0 AS LINE_RN_1
                                   , ''N'' AS CROSS_LINE_YN
                                   , '''' AS CROSS_LINE_ACTIVE_YN
                                FROM PDSC.OC_B100_PD_KPI_WIP_LINE L
                               WHERE L.USED_FLAG = ''Y''
                                 AND L.SUPPLIER_FLAG =''N''
                                 AND L.GBU_CODE = ''CVT''
                                 AND L.WIP_LINE_CODE IN (''C7'',''C11'')
                               UNION ALL
                              SELECT LV.FACTORY_REGION AS FACTORY_REGION1
                                   , LV.GBU_CODE
                                   , LV.MEANING AS WIP_LINE_CODE
                                   , LV.MEANING AS WIP_LINE_DESC
                                   , LV.ATTRIBUTE1 AS MAP_LINE_CODE
                                   , 1 AS LINE_RN_1
                                   , ''Y'' AS CROSS_LINE_YN
                                   , LV.ENABLED_FLAG AS CROSS_LINE_ACTIVE_YN
                                FROM PDSC.OC_B100_XXLGE_LOOKUP_VALUES LV
                               WHERE LV.LOOKUP_TYPE = ''PD_INPUT_TEMPLET_MANUAL_LINE''
                                 AND LV.GBU_CODE = ''CVT''
                                 AND LV.ATTRIBUTE2 = ''201604''
                                 AND LV.MEANING IN (''C7'',''C11'')
                           ) L
                 ) KWL
       ) EYP
       LEFT OUTER JOIN  PDSC.OC_B100_PD_KPI_OPERATION_RATE_L A
    ON EYP.KPI_PERIOD_CODE = A.KPI_PERIOD_CODE
   AND EYP.WIP_LINE_CODE = A.LINE_NAME
   AND EYP.WIP_LINE_CODE IN (''C7'',''C11'')
   AND A.TARGET_CODE = ''PD_002''
   AND A.DATE_CODE = ''M''
   AND A.GBU_CODE = ''CVT''
       LEFT OUTER JOIN
       (
          SELECT F.TARGET_CODE,
                 F.KPI_PERIOD_CODE,
                 F.FACTORY_REGION1,
                 F.GBU_CODE,
                 F.LINE_CODE,
                 F.DATE_CODE,
                 F.PRODUCTION_QUANTITY
            FROM (
                    SELECT F.TARGET_CODE,
                           F.KPI_PERIOD_CODE,
                           F.FACTORY_REGION1,
                           F.GBU_CODE,
                           F.LINE_CODE,
                           F.DATE_CODE,
                           F.PRODUCTION_QUANTITY,
                           ROW_NUMBER() OVER (PARTITION BY F.TARGET_CODE, F.KPI_PERIOD_CODE, F.FACTORY_REGION1, F.GBU_CODE, F.LINE_CODE, F.DATE_CODE ORDER BY F.KPI_PERIOD_STD DESC) AS RN
                      FROM PDSC.OC_B100_PD_KPI_OPERATION_FUTURE F
                     WHERE F.TARGET_CODE =''PD_002''
                       AND (F.KPI_PERIOD_CODE = ''201604'' OR F.KPI_PERIOD_STD = ''201604'')
                       AND F.GBU_CODE = ''CVT''
                       AND (''N'' <> ''Y'' OR F.KPI_PERIOD_CODE <> ''201604'')
                 ) F
           WHERE RN = 1
       ) FF
    ON EYP.KPI_PERIOD_CODE = FF.KPI_PERIOD_CODE
   AND EYP.WIP_LINE_CODE = FF.LINE_CODE
   AND FF.LINE_CODE IN (''C7'',''C11'')
       LEFT OUTER JOIN
       (
          SELECT T.TARGET_CODE
               , T.KPI_PERIOD_CODE
               , T.FACTORY_REGION1
               , T.GBU_CODE
               , T.LINE_CODE
               , T.PRODUCTION_QUANTITY
            FROM pdsc.OC_B100_PD_KPI_AT_OPERATION_RATE t
           WHERE t.TARGET_CODE =''PD_002''
             AND T.DATE_CODE =''M''
             AND T.TOTAL_LINE_CODE =''L''
       ) AL
    ON A.TARGET_CODE = AL.TARGET_CODE
   AND A.KPI_PERIOD_CODE = AL.KPI_PERIOD_CODE
   AND A.FACTORY_REGION1 = AL.FACTORY_REGION1
   AND A.GBU_CODE = AL.GBU_CODE
   AND A.LINE_NAME = AL.LINE_CODE
        LEFT OUTER JOIN
       (
          SELECT FACTORY_REGION
               , GBU_CODE
               , ATTRIBUTE1 AS VIRTUAL_LINE_CODE
            FROM PDSC.OC_B100_XXLGE_LOOKUP_VALUES D
           WHERE LOOKUP_TYPE = ''PD_INPUT_TEMPLETE_VIRTUAL_LINE''
             AND ENABLED_FLAG = ''Y''
           UNION ALL
          SELECT FACTORY_REGION
               , GBU_CODE
               , MEANING AS VIRTUAL_LINE_CODE
            FROM PDSC.OC_B100_XXLGE_LOOKUP_VALUES D
           WHERE LOOKUP_TYPE = ''PD_INPUT_TEMPLET_MANUAL_LINE''
             AND ENABLED_FLAG = ''N''
       AND ATTRIBUTE2 = ''201604''
       ) VI
    ON EYP.FACTORY_REGION1 = VI.FACTORY_REGION
   AND EYP.GBU_CODE = VI.GBU_CODE
   AND EYP.WIP_LINE_CODE = VI.VIRTUAL_LINE_CODE
   AND EYP.WIP_LINE_CODE IN (''C7'',''C11'')
 ORDER BY MONTH_RN,LINE_rn
 WITH UR') STD
WHERE TARGET_CODE IS NOT NULL
;