SELECT MONTH_rn,
       LINE_rn,
       A.TARGET_CODE,           -- :ERP_KPI_CODE AS TARGET_CODE ,
       EYP.KPI_PERIOD_CODE ,
       YYYYMM,
       YEAR,
       MON,
       EYP.FACTORY_REGION1,     -- :ERP_SUBSIDIARY_CODE AS FACTORY_REGION1 ,
       EYP.GBU_CODE,            -- :PRODUCT_GROUP AS GBU_CODE ,
       EYP.WIP_LINE_CODE,
       EYP.WIP_LINE_DESC,
       CASE WHEN EYP.CROSS_LINE_YN = 'Y' THEN 1 ELSE 0 END AS CROSS_LINE_CNT,
       CASE WHEN VI.VIRTUAL_LINE_CODE IS NOT NULL THEN 1 ELSE 0 END AS VIRTUAL_LINE_CNT,
       'M' AS DATE_CODE ,
       STANDARD_OPERATION_RATE/100 AS STANDARD_OPERATION_RATE,
       CASE WHEN VALUE(AL.PRODUCTION_QUANTITY,0)=0 THEN
                 CASE WHEN A.PRODUCTION_QUANTITY IS NULL THEN VALUE(FF.PRODUCTION_QUANTITY,0)
                      ELSE VALUE(A.PRODUCTION_QUANTITY,0)
                 END
            ELSE VALUE(AL.PRODUCTION_QUANTITY,0)
       END AS PRODUCTION_QUANTITY ,
       CASE WHEN VALUE(AL.PRODUCTION_QUANTITY,0) = 0 THEN --VBA에서 데이터 원천에 따라 글자색을 구분하여 표시하기 위한 정보 (수작업 = 1, EDW = 2, 이동 계획 = 3)
                 CASE WHEN A.PRODUCTION_QUANTITY IS NULL THEN 3
                      WHEN A.PRODUCTION_QUANTITY IS NOT NULL AND EYP.CROSS_LINE_YN = 'Y' THEN 1 --교차생산라인에서는 수작업 입력 생산수량을
                      ELSE 2                                                                    --OC_B100_PD_KPI_OPERATION_RATE_L 테이블에 저장하므로
                 END                                                                            --이 경우에도 VBA에서 수작업 입력 표시(붉은색 글씨)를 함
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
                     WHERE T.YYYYMM_ORIG_ID BETWEEN '201602' AND '201606'
                     GROUP BY T.YYYYMM_ORIG_ID
                 ) EYP ,
                 (
                    SELECT L.FACTORY_REGION1
                         , L.GBU_CODE
                         , L.WIP_LINE_CODE
                         , L.WIP_LINE_DESC  --하나의 라인에 교차 생산 라인 2개 이상일 경우를 대비해 3가지 조건을 가지고 순번을 구함
                         , L.CROSS_LINE_YN
                         , ROWNUMBER() OVER(ORDER BY L.CROSS_LINE_YN, L.CROSS_LINE_ACTIVE_YN DESC, L.MAP_LINE_CODE, L.LINE_RN_1, L.WIP_LINE_CODE) AS LINE_rn
                      FROM (
                              SELECT L.FACTORY_REGION1
                                   , L.GBU_CODE
                                   , RTRIM(TRIM(L.WIP_LINE_CODE)) AS WIP_LINE_CODE
                                   , RTRIM(TRIM(L.WIP_LINE_DESC)) AS WIP_LINE_DESC
                                   , RTRIM(TRIM(L.WIP_LINE_CODE)) AS MAP_LINE_CODE
                                   , 0 AS LINE_RN_1  --교차 생산 라인을 원래의 라인 바로 아래 위치 시키기 위한 정렬 정보
                                   , 'N' AS CROSS_LINE_YN --교차 생산 라인 여부(VBA에서 저장 시 이 정보를 활용)
                                   , '' AS CROSS_LINE_ACTIVE_YN
                                FROM PDSC.OC_B100_PD_KPI_WIP_LINE L
                               WHERE L.FACTORY_REGION1 = 'LGEKR(Kitchen Package)'
                                 AND L.GBU_CODE = 'CVT'
                                 AND L.USED_FLAG ='Y'
                                 AND L.SUPPLIER_FLAG ='N'

                               --20141217 고상현 아래는 교차 생산 라인 정보를 포함하기 위해 추가함
                               UNION ALL
                              SELECT LV.FACTORY_REGION AS FACTORY_REGION1
                                   , LV.GBU_CODE
                                   , LV.MEANING AS WIP_LINE_CODE
                                   , LV.MEANING AS WIP_LINE_DESC
                                   , LV.ATTRIBUTE1 AS MAP_LINE_CODE
                                   , 1 AS LINE_RN_1  --교차 생산 라인을 원래의 라인 바로 아래 위치 시키기 위한 정렬 정보
                                   , 'Y' AS CROSS_LINE_YN --교차 생산 라인 여부(VBA에서 저장 시 이 정보를 활용)
                                   , LV.ENABLED_FLAG AS CROSS_LINE_ACTIVE_YN
                                FROM PDSC.OC_B100_XXLGE_LOOKUP_VALUES LV
                               WHERE LV.FACTORY_REGION = 'LGEKR(Kitchen Package)'
                                 AND LV.GBU_CODE = 'CVT'
                                 AND LV.LOOKUP_TYPE = 'PD_INPUT_TEMPLET_MANUAL_LINE'
                                 AND LV.ATTRIBUTE2 = '201603'
                                 --ENABLED_FLAG = 'Y' 와 상관없이 보여줌,
                                 --단 'N' 일 경우는 보여주되 가상라인처럼 VBA에서 블라인드 처리 및 유효성 체크 예외처리함
                           ) L
                 ) KWL
       ) EYP
       LEFT OUTER JOIN  PDSC.OC_B100_PD_KPI_OPERATION_RATE_L A
    ON EYP.KPI_PERIOD_CODE = A.KPI_PERIOD_CODE
   AND EYP.WIP_LINE_CODE = A.LINE_NAME
   AND A.TARGET_CODE = 'PD_002'
   AND A.DATE_CODE = 'M'
   -- 2013/12/04 김준혁 입력이 하기전에는 이전월기준 현재월만 나타나고 끝난상태에서는 입력한 데이터가 보이도록 수정
   --AND A.KPI_PERIOD_CODE BETWEEN :START_PERIOD AND :END_PERIOD
   -- 2013/12/23 김준혁 EYP.MONTH_rn=1 이 추가되어있으면 LEFT OUTER JOIN이 1개만 작동함
   --AND ( (A.KPI_PERIOD_CODE= :START_PERIOD AND EYP.MONTH_rn=1) OR :INPUT_YN = 'Y' )
   -- 2014/01/06 김준혁 Complete전에는 안보여주려고 하였으나 5일 22시에 들어온 실적데이터까지 보여주지 않는 문제가 있어
   --                   엑셀의 VBA에서 입력타입의 경우 전월을 제외한 나머지 항목은 value="" 처리함
   --AND ( A.KPI_PERIOD_CODE= :START_PERIOD OR :INPUT_YN = 'Y' )
   AND A.FACTORY_REGION1 = 'LGEKR(Kitchen Package)'
   AND A.GBU_CODE = 'CVT'
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
                     WHERE F.TARGET_CODE ='PD_002'
                       -- 2013/12/04 김준혁 미래구간의 경우 이전월에 입력한 값은 안나오고 현재기준월에 입력한 값만 나타나도록 F.KPI_PERIOD_STD = :START_PERIOD
                       --                   이전월에 입력한 현재월의 미래구간값을 가져오기 위하여 F.KPI_PERIOD_CODE = :START_PERIODOR 추가 - 현재월제외한 3개월치를 가져오기 때문에 ROW_NUMER로 최근1개월(전월)의 데이터로 추출
                       -- AND F.KPI_PERIOD_CODE BETWEEN :START_PERIOD AND :END_PERIOD
                       AND (F.KPI_PERIOD_CODE = '201603' OR F.KPI_PERIOD_STD = '201603')
                       AND F.FACTORY_REGION1 = 'LGEKR(Kitchen Package)'
                       AND F.GBU_CODE = 'CVT'
                       AND ('N' <> 'Y' OR F.KPI_PERIOD_CODE <> '201603')        -- :HAND_INPUT
                 ) F
           WHERE RN = 1
       ) FF
    ON EYP.KPI_PERIOD_CODE = FF.KPI_PERIOD_CODE
   AND EYP.WIP_LINE_CODE = FF.LINE_CODE
       LEFT OUTER JOIN
       (
          SELECT T.TARGET_CODE
               , T.KPI_PERIOD_CODE
               , T.FACTORY_REGION1
               , T.GBU_CODE
               , T.LINE_CODE
               , T.PRODUCTION_QUANTITY
            FROM pdsc.OC_B100_PD_KPI_AT_OPERATION_RATE t
           WHERE t.TARGET_CODE ='PD_002'
             AND T.DATE_CODE ='M'
             AND T.TOTAL_LINE_CODE ='L'
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
           WHERE LOOKUP_TYPE = 'PD_INPUT_TEMPLETE_VIRTUAL_LINE'
             AND ENABLED_FLAG = 'Y'

           --20141217 고상현 : 아래는 교차 생산 라인으로 등록되었다가 생산 중단 시 가상라인처럼
           --                  블라인드 처리 및 유효성 체크 예외 처리하기 위해 추가함
           UNION ALL
          SELECT FACTORY_REGION
               , GBU_CODE
               , MEANING AS VIRTUAL_LINE_CODE
            FROM PDSC.OC_B100_XXLGE_LOOKUP_VALUES D
           WHERE LOOKUP_TYPE = 'PD_INPUT_TEMPLET_MANUAL_LINE'
             AND ENABLED_FLAG = 'N' --교차 생산 중단을 의미
       AND ATTRIBUTE2 = '201603'
       ) VI
    ON EYP.FACTORY_REGION1 = VI.FACTORY_REGION
   AND EYP.GBU_CODE = VI.GBU_CODE
   AND EYP.WIP_LINE_CODE = VI.VIRTUAL_LINE_CODE
 ORDER BY MONTH_RN,LINE_rn
  WITH UR