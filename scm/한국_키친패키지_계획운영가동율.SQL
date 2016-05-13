INSERT INTO M_OPSMR_TB_OP_RATE
SELECT MONTH_RN                     
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
      ,'PROD' AS OPSMR_TYPE                   
      ,BASE_YYYYMM                  
      ,SCENARIO_TYPE_CODE  
FROM   M_OPSMR_TB_OP_RATE(NOLOCK)
WHERE  FACTORY_REGION1 = 'LGEKR'
AND    GBU_CODE IN ('CVTC7','CVTC11')
AND    WIP_LINE_CODE LIKE 'C%'
;

UPDATE M_OPSMR_TB_OP_RATE
SET    ACTUAL_PRODUCTION_CAPA = PRODUCTION_CAPA
WHERE  FACTORY_REGION1 ='LGEKR'
AND    GBU_CODE LIKE 'CVT%'
AND    KPI_PERIOD_CODE >= '201603'
AND    WIP_LINE_CODE LIKE 'C%'
AND    OPSMR_TYPE = 'PROD'
;

DELETE M_OPSMR_TB_OP_RATE
WHERE  FACTORY_REGION1 ='LGEKR'
AND    GBU_CODE LIKE 'CVT%'
AND    KPI_PERIOD_CODE >= '201603'
AND    WIP_LINE_CODE LIKE 'C%'
AND    OPSMR_TYPE = 'PROD'
;