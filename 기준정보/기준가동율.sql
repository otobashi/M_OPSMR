/*Total#3*/
/* 2014.05.21 ������ ���������� - CAPA�� 0�� �ƴ� ���� ���� */
/*           ����� - Product_Quantity �� 0 �� �ƴѶ��� ���� */

/* 2014.02.10 ������ ���� ���� (��ü��� ���������� ���� ������ �� actual �κ��� Ȯ���� */
/*
  LGEQA Chiller DTT 201401 : ����CAPA�� �������δ� 0.518.... ������ DB�� ����ÿ��� 1(UNIT)�� ���� DB���� ������ ���� 20/1 ������ �������δ� 21/0.518..
                  OC_B100_PD_KPI_OPERATION_RATE_T�� �� CAPA�� 20 ���� ����, �ٸ� ���̺��� 21�� �����(ȭ�鿡�� 21)
               , CASE WHEN VALUE(PRODUCTION_CAPA,0) = 0 THEN 0 ELSE PRODUCTION_QUANTITY * 100 / PRODUCTION_CAPA END AS STANDARD_OPERATION_RATE


�����
     - ���� : DB �� ������ ���(�������� ���� ������� �ʾ����� �������� �Է��� Most Likely ������ ���� ���)
     - ���۾����� : �������� �հ� ���
                         (�������� �����Է��ϵ��� �Ǿ� ������ �������� ������� �ʴ��� Most likely ������ ����
                          ������� �ʰ� �Ǿ��־� ������ ��Ÿ���� ����)
Most Likely ��
     - �������� �հ� ���

1. ���۾��� ��� PRODUCTION_QUANTITY�� ���۾����̺��� ���� ����ؾ���,TOTAL,LINE ���̺��� ��(EDW)�� ������ Ʋ�� ���� ����
2. PRODUCTION_CAPA�� _L, _AT �� ���� ���ƾ��ϳ�, LGEAT-201401 �� ���� ���� �����ľ����� ���� ���̰��߻��� �� �־� ������ ���� �����.
3. TV�� ����� GPT,GLT �� ����������(�����������ν����� ��������) �׷��Ƿ� Input Tempet�� ������� �ڵ�� �����Ͽ� ����ؾ���.
  - �ϴ� �׳� ����غ�.
  - ���� ����
4. ���� ������ �߰��Ǿ��µ� DUE_DATE ����(���� 1���� ���� Actual�� �����Ұ� ���°� ��) �Է��ϰ� �Ǹ� Actual�� ���� �Է��� �ȵǰ� Most Likely���� �����Է��� ��.
   LINE ���̺��� LAST_UPDATE_BY �÷����� ID�� �ƴ� ������Ʈ ���ΰ� ǥ�ð���


��� ȭ��� �����ϰ� ��Ÿ���� ���Ͽ� ó���� ������
* LGEIL(Pune) DMT PA5 ��� - �ű��߰� �����ε� DUE_DATE���� �Է��Ͽ� Actual�� ������� �ʴ� ���
* LGEQA DTT �� ��� PRODUCTION_CAPA�� DB���� 1(�����̴ϱ�)�� , ȭ�鿡�� 1(������ ���Ŀ� ���Ͽ� ���� �Ҽ����ڸ��� �Ǽ��� �� ����) QTY�� ������ �� ȭ��� DB���� ���̰� �־� DB������ �������� CAPA�� �����Ͽ� �Ҽ������� ����Ͽ� ������


1. ���� ������
  ENTMT.ED_YYYYMMDD_PD
  ENTMT.ED_INV_ORG_HIERARCHY_PD OHP
  PDSC.OC_B100_PD_KPI_INPUT_TEMPLETE
  �������� inner join ���� �Ȱ��� Primary �� ����Ѵ�.

2. input_yn='N' �ΰ�� Actual�� Production Quantity�� ����ϰ� ������ ��ĭ���� ���

3. Production Quantity�� �켱 ������
  1) AT ���۾� : pdsc.OC_B100_PD_KPI_AT_OPERATION_RATE - T,L
  2) TOTAL, LINE ���̺� A :
    - PDSC.OC_B100_PD_KPI_OPERATION_RATE_T
    - PDSC.OC_B100_PD_KPI_OPERATION_RATE_L
  3) FF �̷����� :
    - PDSC.OC_B100_PD_KPI_FUTURE_VALUES - T
    - PDSC.OC_B100_PD_KPI_OPERATION_FUTURE - L  (PRODUCTION_QUANTITY �� ����)

  - TOTAL <> SUM(LINE) ���� �ʴ�.

4. Production Capa
  - TOTAL, LINE ���̺� A : ���� ����Ѵ�.(���۾�,�Ϲ� ��� ����)
  - TOTAL = SUM(LINE) �� ����.

5. Standard_Operation_Rate

  - �⺻������ ����� ���� ��������ʰ� Production Quantity�� ���� �켱������ ����Ͽ� ����Ѵ�.
    (�Է¾�Ŀ����� T,L ���̺��� ���� ����ϳ� ������� �ʰ� �������� �ٽ� �����)

6. Input_yn�� ���� ó���� �������� ��ũ�η� ó���ؾ��Ұ� ����.
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

    --20141218 ����� : �Ʒ��� ���� ���� ���� ������ �����ϱ� ���� �߰���
    UNION ALL
   SELECT LV.FACTORY_REGION AS FACTORY_REGION1
        , LV.GBU_CODE
        , LV.MEANING AS WIP_LINE_CODE
        , LV.MEANING AS WIP_LINE_DESC
        , 'Y' AS CROSS_LINE_YN
     FROM PDSC.OC_B100_XXLGE_LOOKUP_VALUES LV
    WHERE LV.LOOKUP_TYPE = 'PD_INPUT_TEMPLET_MANUAL_LINE'
      AND LV.ATTRIBUTE2 = '201603'
        --ENABLED_FLAG = 'Y' �� ������� ������,
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
     /* 2014.02.26 ������ ���� ������ ������� �ʾ��� ��� TOTAL ���̺��� ���������� �����ش� */
     , CASE WHEN VALUE(PRODUCTION_CAPA,0) = 0 THEN 0
            ELSE
                 CASE WHEN VALUE(PRODUCTION_QUANTITY,0) = 0 THEN RST.STANDARD_OPERATION_RATE / 100
                      ELSE PRODUCTION_QUANTITY / PRODUCTION_CAPA END
       END AS STANDARD_OPERATION_RATE
     /* 2014.03.03 ������ �Է��� �� ������ �ϹǷ� 1/1,000�ؼ� ���� ��Ź�մϴ�. (�Ҽ��� �������� ���� ������ �ٵ��ϡ�) */
     , PRODUCTION_QUANTITY/1000 AS PRODUCTION_QUANTITY
     , PRODUCTION_CAPA/1000 AS PRODUCTION_CAPA
     , PEAK_OFF_SEASON
     , TOTAL_LINE_NUMBER
     , SHIFT_LINE_NUMBER1
     , SHIFT_LINE_NUMBER2
     , 0 AS LINE_COUNT
     , VALUE(LINE_COUNT_TOTAL,0) AS LINE_COUNT_TOTAL
     , VALUE(LINE_COUNT_USE,0) AS LINE_COUNT_USE
     , 0 AS LINE_COUNT_IDLE  --20150116 ����� : �ӽ� ����� �����͸� �������� �ʱ� ���� ����
     , 0 AS OVERTIME
     , TOTAL_OVERTIME
     , TOTAL_HOLIDAY_WORK_TIME
     , OVERTIME_PER_PERSON
     , HOLIDAY_WORKTIME_PER_PERSON
     , WORKER_NUMBER_TOTAL
     /* PD_020�� ACTUAL_OPERATION_RATE=ACTUAL_PRODUCTION_QUANTITY / ACTUAL_PRODUCTION_CAPA �� ������� �ʰ� �������� ����Ͽ� ����ϹǷ� �߰���  */
     /* 20140630 ������ �и� 0�ΰ�� �߰� , PRODUCTION_QUANTITY/ACTUAL_PRODUCTION_CAPA AS ACTUAL_OPERATION_RATE */
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
               , CASE WHEN OHP.INPUT_YN = 'Y' OR OHP.KPI_PERIOD_CODE = '201602' THEN  --20150116 ����� : �ӽ� ����� �����͸� �������� �ʱ� ���� ����
                           CASE WHEN VALUE(C.PRODUCTION_QUANTITY,0) = 0 THEN    --20141218 ����� : ����������� ������� ����
                         -- 2016/03/16 �̷������� ��� 0���� ���� �� �־� value(...)�κ��� ������(������������ ����)
                                     -- CASE WHEN VALUE(T.PRODUCTION_QUANTITY ,0) + VALUE(LC.PRODUCTION_QUANTITY ,0) = 0 THEN F.KPI_VALUE_UP
                   CASE WHEN T.PRODUCTION_QUANTITY IS NULL AND LC.PRODUCTION_QUANTITY IS NULL THEN F.KPI_VALUE_UP
                                          ELSE VALUE(T.PRODUCTION_QUANTITY ,0) + VALUE(LC.PRODUCTION_QUANTITY ,0) END
                                ELSE C.PRODUCTION_QUANTITY END
                      ELSE
                           CASE WHEN VALUE(T.PRODUCTION_QUANTITY ,0) = 0 THEN F.KPI_VALUE_UP
                                ELSE VALUE(T.PRODUCTION_QUANTITY ,0) END
                 END AS PRODUCTION_QUANTITY
               /* 2014.02.13 ������ LINE�� SUM(PRODUCTION_CAPA)�� �̿��� ��� 1�̸��� ���� �������Ի꿡 ū ������ �����Ƿ� ȭ��� �����ϰ� �ϱ� ���Ͽ� ���Ŀ� ���Ͽ� ���� PRODUCTION_CAPA_CAL �÷��� �����*/
               , VALUE(L.PRODUCTION_CAPA_CAL,0) AS PRODUCTION_CAPA
               , CASE UPPER(T.PEAK_OFF_SEASON) WHEN 'OFF' THEN 2 ELSE 1 END AS PEAK_OFF_SEASON
               , T.TOTAL_LINE_NUMBER
               /* 2014.02.14 ������ TOTAL�� ���� LINE������ ���� �ʴ� ��찡 �ִ�(LINE�� ���� ���� ȭ�鿡 ��µǹǷ� LINE�� ���) */
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
                 2014.02.17 ������ �Ѷ���(��ϵȶ���)�� ������ �� �ִ� ������ ��
                 2014.02.17 ������ �Ѷ����� ������ ���̺��� ������ ������(LINE ���̺� ��ϵ� ������ ������ ��Ÿ���� ����)
                            �Էµ� LINE ���̺��� ���ε����Ͱ� �ƴ� ���μ������̺��� ���� �������� ����Ǿ� ��Ÿ��,. ȭ��� ����ٸ� �̰����� �ϴ°��� �´°����� �Ǵܵ�
                 2014.05.21 ������ �Ѷ����� ��� CAPA�� �ִ� ������ ������ ���� , �������̺��� ������ �ߴ����� ���� ���۾�,�̷�,�������̺��� ����Ͽ� ������� �ٽ� ����
               */
               , CASE WHEN OHP.INPUT_YN = 'Y' OR OHP.KPI_PERIOD_CODE = '201602' THEN --20150116 ����� : �ӽ� ����� �����͸� �������� �ʱ� ���� ����
                           CASE WHEN VALUE(ATL.LINE_COUNT_TOTAL,0) = 0 THEN L.LINE_COUNT_TOTAL
                                ELSE ATL.LINE_COUNT_TOTAL END
                      ELSE 0
                 END AS LINE_COUNT_TOTAL

               , CASE WHEN OHP.INPUT_YN = 'Y' OR OHP.KPI_PERIOD_CODE = '201602' THEN --20150116 ����� : �ӽ� ����� �����͸� �������� �ʱ� ���� ����
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
                         , SUM(CASE WHEN KWL.CROSS_LINE_YN = 'N' THEN L.LINE_QUANTITY_FOR_DAY * L.PRODUCT_WEIGHT/100 ELSE 0 END) AS OPERATION_SHIFT_LINE_NO1   --20150105 ����� : ���� ���� ������ �����Ͽ� ����
                         , SUM(CASE WHEN KWL.CROSS_LINE_YN = 'N' THEN L.LINE_QUANTITY_FOR_NIGHT * L.PRODUCT_WEIGHT/100 ELSE 0 END) AS OPERATION_SHIFT_LINE_NO2 --20150105 ����� : ���� ���� ������ �����Ͽ� ����
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
                         /* 2014/05/21 ������ �̷������� CAPA�� LINE ���̺��� ���� ����ϹǷ� �ش� ������ ����(����� CASE�������� FL.LINE_COUNT_TOTAL�� ����)*/
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

                 --201418 ����� : ����������ο��� ����� ��������� �������� ���� �߰��� ���ι�
           --C20160106_53587 START ������ : ������������ǰ�� ���۾����̺� �����ϵ��� �����Ͽ���(�������̺��� EDW����� ���������ʴ� ������ 0���� �����¹�������)
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
                       AND L.TOTAL_LINE_CODE='L'                -- C20160106_53587  ������ �߰�(���۾����̺��� ����������ȸ��)
                       AND L.KPI_PERIOD_CODE BETWEEN '201602' AND '201606' --'201603'
                       AND LV.ATTRIBUTE2 = '201603'
                       --[�߿�: ��ȸ �Ⱓ�� ���� �ǰ�]
                       --������ ������������� ������ ����~��� ������ �����;� ��, �̵� ��ȹ���� ������������� ������ �̹� ���ԵǾ� �ֱ� ����
                       --�׷��� ����� ���� ���� ��ȸ �� �̵���ȹ�̶�� ǥ�õ� �κе� ����� EDW ����(���� ����)�� �������� �����Ƿ�
                       --���� �����Ǿ� �ִ� ���¿����� �ϰ��� ������ ���� ����~�̵���ȹ 3���� �Ⱓ�� ������ ��� ������
                       --�� �� �̷� ������ 2015��01���� ���� �����ε�, �� ������ ����~��� �Ⱓ���� �ٽ� �����ؾ���
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