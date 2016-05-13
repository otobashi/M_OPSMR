ALTER TABLE dbo.m_opsmr_tb_op_rate_sub_mst ADD COLUMN 'sheet01_yn' varchar(1) DEFAULT NULL COMMENT 'enabled' AFTER `pre_column`; 



alter table m_opsmr_tb_op_rate_sub_mst add sheet01_yn       VARCHAR (1)



[출처] MySql Add Column|작성자 REX


[출처] MySql Add Column|작성자 REX


alter table m_opsmr_tb_op_rate_sub_mst add sheet01_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet02_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet03_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet04_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet05_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet06_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet07_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet08_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet09_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet10_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet11_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet12_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet13_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet14_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet15_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet16_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet17_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet18_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet19_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet20_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet21_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_sub_mst add sheet22_yn       VARCHAR (1)

alter table m_opsmr_tb_op_rate_prod_mst add sheet01_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet02_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet03_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet04_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet05_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet06_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet07_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet08_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet09_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet10_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet11_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet12_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet13_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet14_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet15_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet16_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet17_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet18_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet19_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet20_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet21_yn       VARCHAR (1)
alter table m_opsmr_tb_op_rate_prod_mst add sheet22_yn       VARCHAR (1)

update m_opsmr_tb_op_rate_sub_mst
set     sheet01_yn = use_flag
       ,sheet02_yn = use_flag
       ,sheet03_yn = use_flag
       ,sheet04_yn = use_flag
       ,sheet05_yn = use_flag
       ,sheet06_yn = use_flag
       ,sheet07_yn = use_flag
       ,sheet08_yn = use_flag
       ,sheet09_yn = use_flag
       ,sheet10_yn = use_flag
       ,sheet11_yn = use_flag
       ,sheet12_yn = use_flag
       ,sheet13_yn = use_flag
       ,sheet14_yn = use_flag
       ,sheet15_yn = use_flag
       ,sheet16_yn = use_flag
       ,sheet17_yn = use_flag
       ,sheet18_yn = use_flag
       ,sheet19_yn = use_flag
       ,sheet20_yn = use_flag
       ,sheet21_yn = use_flag
       ,sheet22_yn = use_flag

      