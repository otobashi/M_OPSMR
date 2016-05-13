ALTER PROCEDURE [dbo].[m_opsmr_sp_prod_sub_qty_sum]
(
  @opsmr_type    VARCHAR(5)
 ,@start_yyyymm  VARCHAR(6)
 ,@base_yyyymm   VARCHAR(6)
)
AS
/*************************************************************************
1. 프 로 젝 트 : M_OPSMR
2. 프로그램 ID : m_opsmr_sp_prod_sub_qty_sum
3. 기     능 : DB2 기준가동률 및 운영가동률을 m_opsmr_sp_prod_sub_qty_sum

--   EXEC m_opsmr_sp_prod_sub_qty_sum 'STD', '201602'  -- 기준가동율
--   EXEC m_opsmr_sp_prod_sub_qty_sum 'PROD', '201602' -- 운영가동율
             
4. 관 련 화 면 :

버전  작 성 자   일      자    내                                        용
----  ---------  ----------  -----------------------------------------------
1.0   shlee      2016.04.05  최초작성
1.1   shlee      2016.04.20  날짜조정
***************************************************************************/

DECLARE @vc_pre_13  AS VARCHAR(6);
DECLARE @vc_post_1  AS VARCHAR(6);
DECLARE @vc_post_3  AS VARCHAR(6);

SET NOCOUNT ON

SET @vc_pre_13 = CONVERT(VARCHAR(6), DATEADD(m, -12, CONVERT(DATETIME,@base_yyyymm+'01')), 112);    -- 직전13개월전
SET @vc_post_1 = CONVERT(VARCHAR(6), DATEADD(m,   1, CONVERT(DATETIME,@base_yyyymm+'01')), 112);    -- 직후1개월
SET @vc_post_3 = CONVERT(VARCHAR(6), DATEADD(m,   3, CONVERT(DATETIME,@base_yyyymm+'01')), 112);    -- 직후3개월

BEGIN

SELECT *
FROM  (
-- 월별수량	
SELECT '01.월별수량' AS cat_cd
      ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,kpi_period_code
	    ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code between @start_yyyymm and @vc_post_3
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet03_yn = 'Y'
AND    prod.sheet03_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name
	      ,kpi_period_code

UNION ALL
-- 생산수량 당월누적
SELECT '02.생산수량 당월' AS cat_cd
      ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'당월누적' AS kpi_period_code
	    ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet03_yn = 'Y'
AND    prod.sheet03_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name

UNION ALL
-- 생산수량 차월누적
SELECT '021.생산수량 차월' AS cat_cd
      ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'차월누적' AS kpi_period_code
	    ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @vc_post_1
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet03_yn = 'Y'
AND    prod.sheet03_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name

UNION ALL
-- 생산수량 직전13개월
SELECT '022.생산수량 직전13개월' AS cat_cd
      ,prod.display_name AS prod
	    ,sub.display_name AS sub
      ,MIN(sub.display_enm) as sub_enm
      ,MIN(sub.display_knm) as sub_knm
      ,MIN(prod.display_enm) as prod_enm
      ,MIN(prod.display_knm) as prod_knm
	    ,'직전13개월' AS kpi_period_code
	    ,SUM(a.production_quantity) AS val
FROM   m_opsmr_tb_op_rate(nolock) a
      ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
      ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
WHERE  a.opsmr_type = @opsmr_type
AND    a.target_code = 'PD_002'
AND    a.base_yyyymm = @base_yyyymm
AND    a.kpi_period_code BETWEEN @vc_pre_13 AND @base_yyyymm
AND    a.factory_region1 = sub.mapping_code
AND    a.gbu_code = prod.mapping_code
AND    sub.sheet03_yn = 'Y'
AND    prod.sheet03_yn = 'Y'
GROUP BY prod.display_name
  	    ,sub.display_name

UNION ALL
SELECT '03.생산비중' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'당월누적' AS kpi_period_code
      ,CASE WHEN SUM(b.qty) = 0 THEN 0
          ELSE SUM(a.qty)/SUM(b.qty) END AS val
FROM  ( SELECT prod.display_name AS prod
        	    ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,MIN(prod.display_enm) as prod_enm
              ,MIN(prod.display_knm) as prod_knm
        	    ,SUM(a.production_quantity) as qty
        FROM   m_opsmr_tb_op_rate(nolock) a
              ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
        WHERE  a.opsmr_type = @opsmr_type
        AND    a.target_code = 'PD_002'
        AND    a.base_yyyymm = @base_yyyymm
        AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
        AND    a.factory_region1 = sub.mapping_code
        AND    a.gbu_code = prod.mapping_code
        AND    sub.sheet03_yn = 'Y'
        AND    prod.sheet03_yn = 'Y'
        GROUP BY prod.display_name
          	    ,sub.display_name
       ) A
       LEFT JOIN
      ( SELECT prod.display_name AS prod
       	      ,SUM(a.production_quantity) as qty
        FROM   m_opsmr_tb_op_rate(nolock) a
              ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
        WHERE  a.opsmr_type = @opsmr_type
        AND    target_code = 'PD_002'
        AND    a.base_yyyymm = @base_yyyymm
        AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
        AND    a.factory_region1 = sub.mapping_code
        AND    a.gbu_code = prod.mapping_code
        AND    sub.sheet03_yn = 'Y'
        AND    prod.sheet03_yn = 'Y'
        GROUP BY prod.display_name
       ) B
       ON A.prod = B.prod
GROUP BY a.prod
        ,a.sub

UNION ALL
SELECT '04.제품TOTAL' AS cat_cd
      ,a.prod AS prod
      ,a.sub AS sub
      ,MAX(a.sub_enm) as sub_enm
      ,MAX(a.sub_knm) as sub_knm
      ,MAX(a.prod_enm) as prod_enm
      ,MAX(a.prod_knm) as prod_knm
      ,'당월누적' AS kpi_period_code
      ,SUM(b.qty) AS val
FROM  ( SELECT prod.display_name AS prod
        	    ,sub.display_name AS sub
              ,MIN(sub.display_enm) as sub_enm
              ,MIN(sub.display_knm) as sub_knm
              ,MIN(prod.display_enm) as prod_enm
              ,MIN(prod.display_knm) as prod_knm
        	    ,SUM(a.production_quantity) as qty
        FROM   m_opsmr_tb_op_rate(nolock) a
              ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
        WHERE  a.opsmr_type = @opsmr_type
        AND    a.target_code = 'PD_002'
        AND    a.base_yyyymm = @base_yyyymm
        AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
        AND    a.factory_region1 = sub.mapping_code
        AND    a.gbu_code = prod.mapping_code
        AND    sub.sheet03_yn = 'Y'
        AND    prod.sheet03_yn = 'Y'
        GROUP BY prod.display_name
          	    ,sub.display_name

       ) A
       LEFT JOIN
      ( SELECT prod.display_name AS prod
       	      ,SUM(a.production_quantity) as qty
        FROM   m_opsmr_tb_op_rate(nolock) a
              ,m_opsmr_tb_op_rate_sub_mst(nolock) sub
              ,m_opsmr_tb_op_rate_prod_mst(nolock) prod
        WHERE  a.opsmr_type = @opsmr_type
        AND    a.target_code = 'PD_002'
        AND    a.base_yyyymm = @base_yyyymm
        AND    a.kpi_period_code BETWEEN SUBSTRING(@base_yyyymm,1,4)+'01' AND @base_yyyymm
        AND    a.factory_region1 = sub.mapping_code
        AND    a.gbu_code = prod.mapping_code
        AND    sub.sheet03_yn = 'Y'
        AND    prod.sheet03_yn = 'Y'
        GROUP BY prod.display_name
       ) B
       ON A.prod = B.prod
GROUP BY a.prod
        ,a.sub
) A
WHERE a.prod+a.sub NOT IN ('BdMSLGEKR'
,'CACLGEVH'
,'CommercialWaterLGEKR'
,'LTV교차KR'
,'MGTLGEKR'
,'MotorLGEIL(Noida)'
,'MWOLGEIL(Noida)'
,'PhotoPrinterLGEHZ'
,'PhotoPrinterLGEKR'
,'PTVLGEAK'
,'PTVLGEAZ'
,'PTVLGEMA'
,'PTVLGESA'
,'RAC교차KR'
)        

;

END