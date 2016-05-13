/*Total#3*/
/* 2014.05.21 김준혁 총조립라인 - CAPA가 0이 아닌 라인 개수 */
/*           운영라인 - Product_Quantity 가 0 이 아닌라인 개수 */

/* 2014.02.10 김준혁 검증 쿼리 (전체출력 엑셀파일의 값을 검증할 때 actual 부분을 확인함 */
/*
  LGEQA Chiller DTT 201401 : 생산CAPA가 수식으로는 0.518.... 이지만 DB에 저장시에는 1(UNIT)로 저장 DB에서 가동율 계산시 20/1 이지만 수식으로는 21/0.518..
                  OC_B100_PD_KPI_OPERATION_RATE_T에 는 CAPA가 20 으로 저장, 다른 테이블에는 21로 저장됨(화면에는 21)
               , CASE WHEN VALUE(PRODUCTION_CAPA,0) = 0 THEN 0 ELSE PRODUCTION_QUANTITY * 100 / PRODUCTION_CAPA END AS STANDARD_OPERATION_RATE


현재월
     - 법인 : DB 의 실적값 출력(실적값이 아직 적재되지 않았으면 이전월에 입력한 Most Likely 구간의 값을 출력)
     - 수작업법인 : 수식으로 합계 계산
                         (실적값을 직접입력하도록 되어 있으며 실적값이 적재되지 않더라도 Most likely 구간의 값을
                          사용하지 않게 되어있어 데이터 나타나지 않음)
Most Likely 월
     - 수식으로 합계 계산

1. 수작업의 경우 PRODUCTION_QUANTITY는 수작업테이블의 것을 사용해야함,TOTAL,LINE 테이블의 값(EDW)은 단위가 틀려 맞지 않음
2. PRODUCTION_CAPA는 _L, _AT 의 값이 같아야하나, LGEAT-201401 의 경우와 같이 원인파악하지 못한 차이가발생할 수 있어 라인의 것을 사용함.
3. TV는 저장시 GPT,GLT 로 각각저장함(엑셀저장프로시져에 내용있음) 그러므로 Input Tempet에 만들어진 코드와 조인하여 사용해야함.
  - 일단 그냥 계산해봄.
  - 추후 뺄것
4. 새로 라인이 추가되었는데 DUE_DATE 이후(마감 1일전 부터 Actual은 수정불가 상태가 됨) 입력하게 되면 Actual의 값은 입력이 안되고 Most Likely부터 정상입력이 됨.
   LINE 테이블의 LAST_UPDATE_BY 컬럼에는 ID가 아닌 업데이트 여부가 표시가됨


■■ 화면과 동일하게 나타내기 위하여 처리한 내용■■
* LGEIL(Pune) DMT PA5 경우 - 신규추가 라인인데 DUE_DATE이후 입력하여 Actual이 저장되지 않는 경우
* LGEQA DTT 의 경우 PRODUCTION_CAPA가 DB에는 1(수량이니까)이 , 화면에는 1(이지만 공식에 의하여 계산된 소수점자리의 실수가 들어가 있음) QTY를 나눴을 때 화면과 DB에서 차이가 있어 DB에서도 공식으로 CAPA를 생성하여 소수점으로 계산하여 보여줌


1. 시작 기준은
  ENTMT.ED_YYYYMMDD_PD
  ENTMT.ED_INV_ORG_HIERARCHY_PD OHP
  PDSC.OC_B100_PD_KPI_INPUT_TEMPLETE
  세가지가 inner join 으로 된것을 Primary 로 사용한다.

2. input_yn='N' 인경우 Actual에 Production Quantity를 출력하고 나머진 빈칸으로 출력

3. Production Quantity의 우선 순위는
  1) AT 수작업 : pdsc.OC_B100_PD_KPI_AT_OPERATION_RATE - T,L
  2) TOTAL, LINE 테이블 A :
    - PDSC.OC_B100_PD_KPI_OPERATION_RATE_T
    - PDSC.OC_B100_PD_KPI_OPERATION_RATE_L
  3) FF 미래구간 :
    - PDSC.OC_B100_PD_KPI_FUTURE_VALUES - T
    - PDSC.OC_B100_PD_KPI_OPERATION_FUTURE - L  (PRODUCTION_QUANTITY 만 있음)

  - TOTAL <> SUM(LINE) 같지 않다.

4. Production Capa
  - TOTAL, LINE 테이블 A : 것을 사용한다.(수작업,일반 모두 동일)
  - TOTAL = SUM(LINE) 과 같다.

5. Standard_Operation_Rate

  - 기본적으로 저장된 값을 사용하지않고 Production Quantity와 같은 우선순위로 계산하여 사용한다.
    (입력양식에서는 T,L 테이블의 값을 출력하나 사용하지 않고 수식으로 다시 계산함)

6. Input_yn에 대한 처리는 엑셀에서 매크로로 처리해야할것 같음.
**/



WITH KWL AS
(
   SELECT L.FACTORY_REGION1
        , L.GBU_CODE
        , RTRIM(TRIM(L.WIP_LINE_CODE)) as WIP_LINE_CODE
        , RTRIM(TRIM(L.WIP_LINE_DESC)) as WIP_LINE_DESC
        , 'N' AS CROSS_LINE_YN
     FROM PDSC.OC_B100_PD_KPI_WIP_LINE L
    WHERE L.USED_FLAG ='Y'
      AND L.SUPPLIER_FLAG ='N'

    --20141218 고상현 : 아래는 교차 생산 라인 정보를 포함하기 위해 추가함
    UNION ALL
   SELECT LV.FACTORY_REGION AS FACTORY_REGION1
        , LV.GBU_CODE
        , LV.MEANING AS WIP_LINE_CODE
        , LV.MEANING AS WIP_LINE_DESC
        , 'Y' AS CROSS_LINE_YN
     FROM PDSC.OC_B100_XXLGE_LOOKUP_VALUES LV
    WHERE LV.LOOKUP_TYPE = 'PD_INPUT_TEMPLET_MANUAL_LINE'
      AND LV.ATTRIBUTE2 = '201603'
        --ENABLED_FLAG = 'Y' 와 상관없이 보여줌,
)

SELECT A.*
FROM  (
SELECT MONTH_RN
     , TARGET_CODE
     , KPI_PERIOD_CODE
     , YYYYMM
     , YEAR
     , MON
     , FACTORY_REGION1
     , GBU_CODE
     , GBU_NAME
     , DATE_CODE
     , WIP_LINE_CODE
     , WIP_LINE_DESC
     /* 2014.02.26 김준혁 아직 실적이 적재되지 않았을 경우 TOTAL 테이블의 가동율값을 보여준다 */
     , CASE WHEN VALUE(PRODUCTION_CAPA,0) = 0 THEN 0
            ELSE
                 CASE WHEN VALUE(PRODUCTION_QUANTITY,0) = 0 THEN RST.STANDARD_OPERATION_RATE / 100
                      ELSE PRODUCTION_QUANTITY / PRODUCTION_CAPA END
       END AS STANDARD_OPERATION_RATE
     /* 2014.03.03 김준혁 입력을 대 단위로 하므로 1/1,000해서 구현 부탁합니다. (소수점 절사하지 말고 끝으로 붙도록…) */
     , PRODUCTION_QUANTITY/1000 AS PRODUCTION_QUANTITY
     , PRODUCTION_CAPA/1000 AS PRODUCTION_CAPA
     , PEAK_OFF_SEASON
     , TOTAL_LINE_NUMBER
     , SHIFT_LINE_NUMBER1
     , SHIFT_LINE_NUMBER2
     , 0 AS LINE_COUNT
     , VALUE(LINE_COUNT_TOTAL,0) AS LINE_COUNT_TOTAL
     , VALUE(LINE_COUNT_USE,0) AS LINE_COUNT_USE
     , 0 AS LINE_COUNT_IDLE  --20150116 고상현 : 임시 저장된 데이터를 보여주지 않기 위해 수정
     , 0 AS OVERTIME
     , TOTAL_OVERTIME
     , TOTAL_HOLIDAY_WORK_TIME
     , OVERTIME_PER_PERSON
     , HOLIDAY_WORKTIME_PER_PERSON
     , WORKER_NUMBER_TOTAL
     /* PD_020의 ACTUAL_OPERATION_RATE=ACTUAL_PRODUCTION_QUANTITY / ACTUAL_PRODUCTION_CAPA 를 사용하지 않고 수식으로 계산하여 사용하므로 추가함  */
     /* 20140630 김준혁 분모가 0인경우 추가 , PRODUCTION_QUANTITY/ACTUAL_PRODUCTION_CAPA AS ACTUAL_OPERATION_RATE */
     , CASE WHEN VALUE(ACTUAL_PRODUCTION_CAPA,0) = 0 THEN 0 ELSE PRODUCTION_QUANTITY/ACTUAL_PRODUCTION_CAPA END AS ACTUAL_OPERATION_RATE
     , ACTUAL_PRODUCTION_CAPA
     , '' AS DUMMY1
     , '' AS DUMMY2
     , '' AS DUMMY3
     , '' AS DUMMY4
     , '' AS DUMMY5
     , 'STD' AS OPSMR_TYPE
     , '201603' AS BASE_YYYYMM
     , CASE WHEN KPI_PERIOD_CODE <= '201603' THEN 'AC0'
            WHEN KPI_PERIOD_CODE = '201604' THEN 'PR1'
            WHEN KPI_PERIOD_CODE = '201605' THEN 'PR2'
            WHEN KPI_PERIOD_CODE = '201606' THEN 'PR3' END AS SCENARIO_TYPE_CODE
/*
     , CASE WHEN KPI_PERIOD_CODE <= '201603' THEN 'AC0'
            WHEN KPI_PERIOD_CODE = TO_CHAR(TO_DATE(SUBSTR('201603',1,6),'YYYYMM') + 1 MONTH, 'YYYYMM') THEN 'PR1'
            WHEN KPI_PERIOD_CODE = TO_CHAR(TO_DATE(SUBSTR('201603',1,6),'YYYYMM') + 2 MONTH, 'YYYYMM') THEN 'PR2'
            WHEN KPI_PERIOD_CODE = TO_CHAR(TO_DATE(SUBSTR('201603',1,6),'YYYYMM') + 3 MONTH, 'YYYYMM') THEN 'PR3' END AS SCENARIO_TYPE_CODE
*/
  FROM (
          SELECT MONTH_RN
               , 'PD_002' AS TARGET_CODE
               , OHP.KPI_PERIOD_CODE
               , YYYYMM
               , YEAR
               , MON
               , OHP.FACTORY_REGION1
               , OHP.GBU_CODE
               , CASE WHEN OHP.GBU_CODE IN ('GLT','GPT') THEN 'TV' ELSE OHP.PRODUCT_GROUP3 END AS GBU_NAME
               , 'M' AS DATE_CODE
               , 'Total' AS WIP_LINE_CODE
               , 'Total' AS WIP_LINE_DESC
               , T.STANDARD_OPERATION_RATE
               , CASE WHEN OHP.INPUT_YN = 'Y' OR OHP.KPI_PERIOD_CODE = '201602' THEN  --20150116 고상현 : 임시 저장된 데이터를 보여주지 않기 위해 수정
                           CASE WHEN VALUE(C.PRODUCTION_QUANTITY,0) = 0 THEN    --20141218 고상현 : 교차생산라인 생산수량 포함
                         -- 2016/03/16 미래구간의 경우 0값이 있을 수 있어 value(...)부분을 제외함(라인쪽쿼리에 맞춤)
                                     -- CASE WHEN VALUE(T.PRODUCTION_QUANTITY ,0) + VALUE(LC.PRODUCTION_QUANTITY ,0) = 0 THEN F.KPI_VALUE_UP
                   CASE WHEN T.PRODUCTION_QUANTITY IS NULL AND LC.PRODUCTION_QUANTITY IS NULL THEN F.KPI_VALUE_UP
                                          ELSE VALUE(T.PRODUCTION_QUANTITY ,0) + VALUE(LC.PRODUCTION_QUANTITY ,0) END
                                ELSE C.PRODUCTION_QUANTITY END
                      ELSE
                           CASE WHEN VALUE(T.PRODUCTION_QUANTITY ,0) = 0 THEN F.KPI_VALUE_UP
                                ELSE VALUE(T.PRODUCTION_QUANTITY ,0) END
                 END AS PRODUCTION_QUANTITY
               /* 2014.02.13 김준혁 LINE의 SUM(PRODUCTION_CAPA)을 이용할 경우 1미만의 값은 가동율게산에 큰 영향이 있으므로 화면과 동일하게 하기 위하여 공식에 의하여 계산된 PRODUCTION_CAPA_CAL 컬럼을 사용함*/
               , VALUE(L.PRODUCTION_CAPA_CAL,0) AS PRODUCTION_CAPA
               , CASE UPPER(T.PEAK_OFF_SEASON) WHEN 'OFF' THEN 2 ELSE 1 END AS PEAK_OFF_SEASON
               , T.TOTAL_LINE_NUMBER
               /* 2014.02.14 김준혁 TOTAL의 값과 LINE의합이 맞지 않는 경우가 있다(LINE의 합이 실제 화면에 출력되므로 LINE합 사용) */
               , L.OPERATION_SHIFT_LINE_NO1 AS SHIFT_LINE_NUMBER1
               , L.OPERATION_SHIFT_LINE_NO2 AS SHIFT_LINE_NUMBER2
               , T.OVERTIME_PER_PERSON
               , T.TOTAL_OVERTIME
               , T.HOLIDAY_WORKTIME_PER_PERSON
               , T.TOTAL_HOLIDAY_WORK_TIME
               , T.WORKER_NUMBER_TOTAL
               , B.STANDARD_OPERATION_RATE/100 AS ACTUAL_OPERATION_RATE
               , B.PRODUCTION_CAPA ACTUAL_PRODUCTION_CAPA
               , OHP.INPUT_YN
               /*
                 2014.02.17 김준혁 총라인(등록된라인)과 실적이 들어가 있는 라인의 수
                 2014.02.17 김준혁 총라인은 설정된 테이블의 값으로 변경함(LINE 테이블에 등록된 내용이 없으면 나타나지 않음)
                            입력된 LINE 테이블의 라인데이터가 아닌 라인설정테이블의 값을 기준으로 변경되어 나타남,. 화면과 맞춘다면 이것으로 하는것이 맞는것으로 판단됨
                 2014.05.21 김준혁 총라인의 경우 CAPA가 있는 라인의 개수로 변경 , 라인테이블의 개수로 했던것을 각각 수작업,미래,라인테이블에서 계산하여 출력으로 다시 변경
               */
               , CASE WHEN OHP.INPUT_YN = 'Y' OR OHP.KPI_PERIOD_CODE = '201602' THEN --20150116 고상현 : 임시 저장된 데이터를 보여주지 않기 위해 수정
                           CASE WHEN VALUE(ATL.LINE_COUNT_TOTAL,0) = 0 THEN L.LINE_COUNT_TOTAL
                                ELSE ATL.LINE_COUNT_TOTAL END
                      ELSE 0
                 END AS LINE_COUNT_TOTAL

               , CASE WHEN OHP.INPUT_YN = 'Y' OR OHP.KPI_PERIOD_CODE = '201602' THEN --20150116 고상현 : 임시 저장된 데이터를 보여주지 않기 위해 수정
                           CASE WHEN VALUE(ATL.LINE_COUNT_USE,0) = 0 THEN
                                     CASE WHEN VALUE(L.LINE_COUNT_USE,0) = 0 THEN FL.LINE_COUNT_USE
                                          ELSE L.LINE_COUNT_USE END
                                ELSE ATL.LINE_COUNT_USE END
                      ELSE
                           L.LINE_COUNT_USE
                 END AS LINE_COUNT_USE

            FROM (
                    SELECT MASTER.FACTORY_REGION1
                         , MASTER.GBU_CODE
                         , MASTER.PRODUCT_GROUP3
                         , EYP.KPI_PERIOD_CODE
                         , KIT.INPUT_YN
                         , KIT.DATE_CODE
                         , EYP.YYYYMM
                         , EYP.YEAR
                         , EYP.MON
                         , MONTH_RN
                      FROM (
                              SELECT ROWNUMBER() OVER(ORDER BY T.YYYYMM_ORIG_ID ) AS MONTH_RN
                                   , T.YYYYMM_ORIG_ID AS KPI_PERIOD_CODE
                                   , MAX(T.YYYYMM_ORIG_ID) as YYYYMM
                                   , MAX(SUBSTR(T.YYYYMM_ORIG_ID,1,4)) AS YEAR
                                   , MAX(SUBSTR(T.YYYYMM_STD1_NAME,1,3)) AS MON
                                FROM ENTMT.ED_YYYYMMDD_PD T
                               WHERE T.YYYYMM_ORIG_ID BETWEEN '201602'  AND '201606'
                               GROUP BY T.YYYYMM_ORIG_ID
                           ) EYP,

                           (
                              SELECT OHP.GBU_CODE
                                   , OHP.FACTORY_REGION1 AS FACTORY_REGION1
                                   , MAX(OHP.PRODUCT_GROUP1) AS PRODUCT_GROUP1
                                   , MAX(OHP.PRODUCT_GROUP2) AS PRODUCT_GROUP2
                                   , MAX(OHP.PRODUCT_GROUP3) AS PRODUCT_GROUP3
                                   , MAX(OHP.FACTORY_REGION2) AS FACTORY_REGION2
                                   , MAX(OHP.FACTORY_REGION3) AS FACTORY_REGION3
                                   , MAX(OHP.COMPANY_CODE) AS COMPANY_CODE
                                FROM ENTMT.ED_INV_ORG_HIERARCHY_PD OHP
                               WHERE OHP.DISPLAY_FLAG ='Y'
                                 AND NOT EXISTS (SELECT *
                                                   FROM PDSC.OC_B100_XXLGE_LOOKUP_VALUES AS  XLV1
                                                  WHERE XLV1.LOOKUP_TYPE = 'PD_KPI_DISPLAY_FLAG'
                                                    AND XLV1.LOOKUP_CODE ='PD_002'
                                                    AND XLV1.ATTRIBUTE1 = 'X'
                                                    AND XLV1.GBU_CODE = OHP.GBU_CODE
                                                    AND XLV1.FACTORY_REGION = OHP.FACTORY_REGION1
                                                )
                               GROUP BY OHP.GBU_CODE
                                   , OHP.FACTORY_REGION1
                           ) AS MASTER
                         , PDSC.OC_B100_PD_KPI_INPUT_TEMPLETE KIT
                     WHERE KIT.FACTORY_REGION1 = MASTER.FACTORY_REGION1
                       AND KIT.GBU_CODE = MASTER.GBU_CODE
                       AND KIT.TEMPLET_CODE = 'SORM'
                       AND KIT.KPI_PERIOD_CODE = '201603'
                       AND KIT.DATE_CODE='M'

                 ) OHP

                 LEFT OUTER JOIN PDSC.OC_B100_PD_KPI_OPERATION_RATE_T T
              ON T.TARGET_CODE = 'PD_002'
             AND T.FACTORY_REGION1 = OHP.FACTORY_REGION1
             AND T.GBU_CODE = OHP.GBU_CODE
             AND T.KPI_PERIOD_CODE=OHP.KPI_PERIOD_CODE
             AND T.DATE_CODE=OHP.DATE_CODE

                 LEFT OUTER JOIN PDSC.OC_B100_PD_KPI_OPERATION_RATE_T B
              ON B.TARGET_CODE = 'PD_020'
             AND B.FACTORY_REGION1 = OHP.FACTORY_REGION1
             AND B.GBU_CODE = OHP.GBU_CODE
             AND B.KPI_PERIOD_CODE=OHP.KPI_PERIOD_CODE
             AND B.DATE_CODE=OHP.DATE_CODE

                 LEFT OUTER JOIN pdsc.OC_B100_PD_KPI_AT_OPERATION_RATE C
              ON C.TARGET_CODE = 'PD_002'
             AND C.FACTORY_REGION1 = OHP.FACTORY_REGION1
             AND C.GBU_CODE = OHP.GBU_CODE
             AND C.KPI_PERIOD_CODE = OHP.KPI_PERIOD_CODE
             AND C.DATE_CODE = OHP.DATE_CODE
             AND C.TOTAL_LINE_CODE = 'T'

                 LEFT OUTER JOIN PDSC.OC_B100_PD_KPI_FUTURE_VALUES F
              ON F.TARGET_CODE    = 'PD_002'
             AND F.FACTORY_REGION1  = OHP.FACTORY_REGION1
             AND F.GBU_CODE     = OHP.GBU_CODE
             AND F.KPI_PERIOD_CODE  = OHP.KPI_PERIOD_CODE
             AND F.KPI_PERIOD_STD = '201603'
             AND F.YMW_CODE   = OHP.DATE_CODE

                 LEFT OUTER JOIN
                 (
                    SELECT L.TARGET_CODE
                         , L.KPI_PERIOD_CODE
                         , L.FACTORY_REGION1
                         , L.GBU_CODE
                         , L.DATE_CODE
                         , SUM(L.PRODUCTION_QUANTITY) AS PRODUCTION_QUANTITY
                         , SUM(L.PRODUCTION_CAPA) AS PRODUCTION_CAPA
                         , SUM(CASE WHEN KWL.CROSS_LINE_YN = 'N' THEN L.LINE_QUANTITY_FOR_DAY * L.PRODUCT_WEIGHT/100 ELSE 0 END) AS OPERATION_SHIFT_LINE_NO1   --20150105 고상현 : 교차 생산 라인은 제외하여 집계
                         , SUM(CASE WHEN KWL.CROSS_LINE_YN = 'N' THEN L.LINE_QUANTITY_FOR_NIGHT * L.PRODUCT_WEIGHT/100 ELSE 0 END) AS OPERATION_SHIFT_LINE_NO2 --20150105 고상현 : 교차 생산 라인은 제외하여 집계
                         , SUM(
                         (((UPH*WORKING_HOUR*NORMAL_WORKING_DAY*TARGET_EFFICIENCY/100*LINE_QUANTITY_FOR_DAY)+(UPH*NORMAL_WORKING_HOUR*HOLIDAY_WORKING_DAY*TARGET_EFFICIENCY/100*LINE_QUANTITY_FOR_DAY))*1+((UPH*WORKING_HOUR*NORMAL_WORKING_DAY*TARGET_EFFICIENCY/100*LINE_QUANTITY_FOR_NIGHT)+(UPH*NORMAL_WORKING_HOUR*HOLIDAY_WORKING_DAY*TARGET_EFFICIENCY/100*LINE_QUANTITY_FOR_NIGHT))*2)*PRODUCT_WEIGHT/100
                         ) AS PRODUCTION_CAPA_CAL
                         , SUM(CASE WHEN KWL.CROSS_LINE_YN = 'Y' OR VALUE(L.PRODUCTION_CAPA,0)=0 THEN 0 ELSE 1 END) AS LINE_COUNT_TOTAL
                         , SUM(CASE WHEN KWL.CROSS_LINE_YN = 'Y' OR VALUE(L.PRODUCTION_QUANTITY,0)=0 THEN 0 ELSE 1 END) AS LINE_COUNT_USE
                      FROM KWL
                           LEFT OUTER JOIN PDSC.OC_B100_PD_KPI_OPERATION_RATE_L L
                        ON KWL.FACTORY_REGION1 = L.FACTORY_REGION1
                       AND KWL.GBU_CODE = L.GBU_CODE
                       AND KWL.WIP_LINE_CODE = L.LINE_NAME
                     WHERE 1 = 1
                     GROUP BY L.TARGET_CODE
                         , L.KPI_PERIOD_CODE
                         , L.FACTORY_REGION1
                         , L.GBU_CODE
                         , L.DATE_CODE
                 ) L
              ON L.TARGET_CODE     = 'PD_002'
             AND L.FACTORY_REGION1 = OHP.FACTORY_REGION1
             AND L.GBU_CODE        = OHP.GBU_CODE
             AND L.KPI_PERIOD_CODE = OHP.KPI_PERIOD_CODE
             AND L.DATE_CODE       = OHP.DATE_CODE

                 LEFT OUTER JOIN
                 (
                    SELECT ATL.TARGET_CODE
                         , ATL.KPI_PERIOD_CODE
                         , ATL.FACTORY_REGION1
                         , ATL.GBU_CODE
                         , ATL.DATE_CODE
                         , SUM(CASE WHEN KWL.CROSS_LINE_YN = 'Y' OR VALUE(ATL.PRODUCTION_CAPA,0)=0 THEN 0 ELSE 1 END) AS LINE_COUNT_TOTAL
                         , SUM(CASE WHEN KWL.CROSS_LINE_YN = 'Y' OR VALUE(ATL.PRODUCTION_QUANTITY,0)=0 THEN 0 ELSE 1 END) AS LINE_COUNT_USE
                      FROM KWL
                           LEFT OUTER JOIN PDSC.OC_B100_PD_KPI_AT_OPERATION_RATE ATL
                        ON KWL.FACTORY_REGION1 = ATL.FACTORY_REGION1
                       AND KWL.GBU_CODE = ATL.GBU_CODE
                       AND KWL.WIP_LINE_CODE = ATL.LINE_CODE
                       AND ATL.TOTAL_LINE_CODE='L'
                     WHERE 1 = 1
                     GROUP BY ATL.TARGET_CODE
                         , ATL.KPI_PERIOD_CODE
                         , ATL.FACTORY_REGION1
                         , ATL.GBU_CODE
                         , ATL.DATE_CODE
                 ) ATL
              ON ATL.TARGET_CODE     = 'PD_002'
             AND ATL.FACTORY_REGION1 = OHP.FACTORY_REGION1
             AND ATL.GBU_CODE        = OHP.GBU_CODE
             AND ATL.KPI_PERIOD_CODE = OHP.KPI_PERIOD_CODE
             AND ATL.DATE_CODE       = OHP.DATE_CODE

                 LEFT OUTER JOIN
                 (
                    SELECT FL.TARGET_CODE
                         , FL.KPI_PERIOD_CODE
                         , FL.FACTORY_REGION1
                         , FL.GBU_CODE
                         , FL.DATE_CODE
                         /* 2014/05/21 김준혁 미래구간의 CAPA는 LINE 테이블의 것을 사용하므로 해당 쿼리문 삭제(상기의 CASE문에서도 FL.LINE_COUNT_TOTAL은 삭제)*/
                         /*, COUNT(LINE_CODE) AS LINE_COUNT_TOTAL*/
                         /*, SUM(CASE WHEN VALUE(FL.PRODUCTION_CAPA,0)=0 THEN 0 ELSE 1 END) AS LINE_COUNT_TOTAL*/
                         , SUM(CASE WHEN KWL.CROSS_LINE_YN = 'Y' OR VALUE(FL.PRODUCTION_QUANTITY,0)=0 THEN 0 ELSE 1 END) AS LINE_COUNT_USE
                      FROM KWL
                           LEFT OUTER JOIN PDSC.OC_B100_PD_KPI_OPERATION_FUTURE FL
                        ON KWL.FACTORY_REGION1 = FL.FACTORY_REGION1
                       AND KWL.GBU_CODE = FL.GBU_CODE
                       AND KWL.WIP_LINE_CODE = FL.LINE_CODE
                       AND FL.KPI_PERIOD_STD = '201603'
                     WHERE 1 = 1
                     GROUP BY FL.TARGET_CODE
                         , FL.KPI_PERIOD_CODE
                         , FL.FACTORY_REGION1
                         , FL.GBU_CODE
                         , FL.DATE_CODE
                 ) FL
              ON FL.TARGET_CODE     = 'PD_002'
             AND FL.FACTORY_REGION1 = OHP.FACTORY_REGION1
             AND FL.GBU_CODE        = OHP.GBU_CODE
             AND FL.KPI_PERIOD_CODE = OHP.KPI_PERIOD_CODE
             AND FL.DATE_CODE       = OHP.DATE_CODE

                 --201418 고상현 : 교차생산라인에서 등록한 생산수량을 가져오기 위해 추가한 조인문
           --C20160106_53587 START 김준혁 : 교차생산라인의경우 수작업테이블에 저장하도록 수정하였음(라인테이블은 EDW적재시 존재하지않는 라인은 0으로 덮어씌우는문제있음)
                 LEFT OUTER JOIN
                 (
                    SELECT L.TARGET_CODE
                         , LV.FACTORY_REGION AS FACTORY_REGION1
                         , LV.GBU_CODE
                         , L.KPI_PERIOD_CODE
                         , L.DATE_CODE
                         , SUM(L.PRODUCTION_QUANTITY) AS PRODUCTION_QUANTITY
                      FROM PDSC.OC_B100_XXLGE_LOOKUP_VALUES LV
                           INNER JOIN PDSC.OC_B100_PD_KPI_AT_OPERATION_RATE L
                        ON LV.FACTORY_REGION = L.FACTORY_REGION1
                       AND LV.GBU_CODE = L.GBU_CODE
                       AND LV.MEANING = L.LINE_CODE
                     WHERE LV.LOOKUP_TYPE = 'PD_INPUT_TEMPLET_MANUAL_LINE'
                       AND L.DATE_CODE = 'M'
                       AND L.TOTAL_LINE_CODE='L'                -- C20160106_53587  김준혁 추가(수작업테이블의 라인정보조회용)
                       AND L.KPI_PERIOD_CODE BETWEEN '201602' AND '201606' --'201603'
                       AND LV.ATTRIBUTE2 = '201603'
                       --[중요: 조회 기간에 대한 의견]
                       --원래는 교차생산라인의 실적은 전월~당월 실적만 가져와야 함, 이동 계획에는 교차생산라인의 실적이 이미 포함되어 있기 때문
                       --그러나 현재는 과거 실적 조회 시 이동계획이라고 표시된 부분도 사실은 EDW 수량(실제 실적)을 가져오고 있으므로
                       --현재 구현되어 있는 상태에서의 일관성 유지를 위해 전월~이동계획 3개월 기간의 실적을 모두 가져옴
                       --추 후 이력 관리를 2015년01월에 구현 예정인데, 그 때에는 전월~당월 기간으로 다시 조정해야함
                     GROUP BY L.TARGET_CODE
                         , LV.FACTORY_REGION
                         , LV.GBU_CODE
                         , L.KPI_PERIOD_CODE
                         , L.DATE_CODE
          -- C20160106_53587 END
                 ) LC
              ON LC.TARGET_CODE     = 'PD_002'
             AND LC.FACTORY_REGION1 = OHP.FACTORY_REGION1
             AND LC.GBU_CODE        = OHP.GBU_CODE
             AND LC.KPI_PERIOD_CODE = OHP.KPI_PERIOD_CODE
             AND LC.DATE_CODE       = OHP.DATE_CODE

       ) AS RST
) A
WHERE A.KPI_PERIOD_CODE >= '201603'       
WITH UR