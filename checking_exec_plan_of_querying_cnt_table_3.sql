REM
REM     Script:        checking_exec_plan_of_querying_cnt_table_3.sql
REM     Author:        Quanwen Zhao
REM     Dated:         Dec 25, 2019
REM
REM     Last tested:
REM             11.2.0.4
REM             18.3.0.0
REM             19.5.0.0 (Live SQL)
REM
REM     Purpose:
REM        This Demo script mainly contains three sections. They're as follows:
REM           (1) creating user 'QWZ';
REM           (2) using 4 separate procedures to quickly create 4 different tables,
REM               'TEST3', 'TEST3_PK', 'TEST3_BI' and 'TEST3_PK_BI';
REM           (3) checking real execution plan and meanwhile generating 10053 trc file by querying
REM               COUNT(*|1|id|flag) on the previous 4 different tables;
REM        By the way those tables are going to be dynamically created by using several
REM        oracle PL/SQL procedures. I just use the standard SQL syntax 'CREATE TABLE'
REM        to create my TEST3 tables with two physical properties (SEGMENT CREATION IMMEDIATE and
REM        NOLOGGING) and a table property (NO PARALLEL) and then also create corresponding
REM        PRIMARY KEY or BITMAP INDEX on those different TEST3 tables. Finally inserting
REM        several test data with '5e7' lines to my all TEST3 tables using the hint 'append'.
REM

PROMPT =====================
PROMPT version 11.2 and 18.3
PROMPT =====================

PROMPT ***************************************************************************************
PROMPT * Creating user 'QWZ', permanent tablespace 'QWZ', and temporary tablespace 'QWZ_TMP' *
PROMPT * Granting several related privileges for 'SYS', 'ROLE' and 'TAB' to user 'QWZ'.      *
PROMPT ***************************************************************************************

CONN / AS SYSDBA;

CREATE TABLESPACE qwz DATAFILE '/*+ specific location of your datafile on Oracle 11.2 or 18.3 */qwz_01.dbf' SIZE 5g AUTOEXTEND ON NEXT 5g MAXSIZE 25g;
CREATE TEMPORARY TABLESPACE qwz_tmp TEMPFILE '/opt/oracle/oradata/ORA18C/datafile/qwz_tmp_01.dbf' SIZE 500m;
CREATE USER qwz IDENTIFIED BY qwz DEFAULT TABLESPACE qwz TEMPORARY TABLESPACE qwz_tmp QUOTA UNLIMITED ON qwz;
GRANT alter session TO qwz;
GRANT create any table TO qwz;
GRANT connect, resource TO qwz;
GRANT select ON v_$sql_plan TO qwz;
GRANT select ON v_$session TO qwz;
GRANT select ON v_$sql_plan_statistics_all TO qwz;
GRANT select ON v_$sql TO qwz;

PROMPT ********************************************************************
PROMPT * Using 4 separate procedures to quickly create 4 different tables *
PROMPT *  (1) test3: no primary key and bitmap index;                     *
PROMPT *  (2) test3_pk: only primary key  => test3_only_pk;               *
PROMPT *  (3) test3_bi: only bitmap index => test3_only_bi;               *
PROMPT *  (4) test3_pk_bi: primary key    => test3_pk,                    *
PROMPT *                   bitmap index   => test3_bi;                    *
PROMPT ********************************************************************

CONN qwz/qwz

SET TIMING ON

CREATE OR REPLACE PROCEDURE crt_tab_test3
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
   v_sql_3 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test3 PURGE';
   v_sql_2 := q'[CREATE TABLE test3 ( 
                    id     NUMBER      NOT NULL 
                    , flag VARCHAR2(7) NOT NULL 
                 ) 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 -- PARALLEL 10
                ]';
   v_sql_3 := q'[INSERT /*+ append */ INTO test3 
                 SELECT ROWNUM id 
                        , CASE WHEN ROWNUM BETWEEN 1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[           WHEN ROWNUM BETWEEN 2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[           WHEN ROWNUM BETWEEN 4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[           ELSE 'unknown' 
                          END flag 
                 FROM XMLTABLE ('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE v_sql_3;
   COMMIT;
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST3'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE v_sql_3;
      COMMIT;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST3'
      );
END crt_tab_test3;
/

CREATE OR REPLACE PROCEDURE crt_tab_test3_pk
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
   v_sql_3 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test3_pk PURGE';
   v_sql_2 := q'[CREATE TABLE test3_pk ( 
                    id     NUMBER      NOT NULL CONSTRAINT test3_only_pk PRIMARY KEY 
                    , flag VARCHAR2(7) NOT NULL 
                 ) 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 -- PARALLEL 10
                ]';
   v_sql_3 := q'[INSERT /*+ append */ INTO test3_pk 
                 SELECT ROWNUM id 
                        , CASE WHEN ROWNUM BETWEEN 1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[           WHEN ROWNUM BETWEEN 2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[           WHEN ROWNUM BETWEEN 4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[           ELSE 'unknown' 
                          END flag 
                 FROM XMLTABLE ('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE v_sql_3;
   COMMIT;
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST3_PK'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE v_sql_3;
      COMMIT;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST3_PK'
      );
END crt_tab_test3_pk;
/

CREATE OR REPLACE PROCEDURE crt_tab_test3_bi
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
   v_sql_3 VARCHAR2(2000);
   v_sql_4 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test3_bi PURGE';
   v_sql_2 := q'[CREATE TABLE test3_bi ( 
                    id     NUMBER      NOT NULL 
                    , flag VARCHAR2(7) NOT NULL 
                 ) 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 -- PARALLEL 10
                ]';
   v_sql_3 := 'CREATE BITMAP INDEX test3_only_bi ON test3_bi (flag)';
   v_sql_4 := q'[INSERT /*+ append */ INTO test3_bi 
                 SELECT ROWNUM id 
                        , CASE WHEN ROWNUM BETWEEN 1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[           WHEN ROWNUM BETWEEN 2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[           WHEN ROWNUM BETWEEN 4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[           ELSE 'unknown' 
                          END flag 
                 FROM XMLTABLE ('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE v_sql_3;
   EXECUTE IMMEDIATE v_sql_4;
   COMMIT;
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST3_BI'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE v_sql_3;
      EXECUTE IMMEDIATE v_sql_4;
      COMMIT;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST3_BI'
      );
END crt_tab_test3_bi;
/

CREATE OR REPLACE PROCEDURE crt_tab_test3_pk_bi
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
   v_sql_3 VARCHAR2(2000);
   v_sql_4 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test3_pk_bi PURGE';
   v_sql_2 := q'[CREATE TABLE test3_pk_bi ( 
                    id     NUMBER      NOT NULL CONSTRAINT test3_pk PRIMARY KEY 
                    , flag VARCHAR2(7) NOT NULL 
                 ) 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 -- PARALLEL 10
                ]';
   v_sql_3 := 'CREATE BITMAP INDEX test3_bi ON test3_pk_bi (flag)';
   v_sql_4 := q'[INSERT /*+ append */ INTO test3_pk_bi 
                 SELECT ROWNUM id 
                        , CASE WHEN ROWNUM BETWEEN 1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[           WHEN ROWNUM BETWEEN 2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[           WHEN ROWNUM BETWEEN 4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[           ELSE 'unknown' 
                          END flag 
                 FROM XMLTABLE ('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE v_sql_3;
   EXECUTE IMMEDIATE v_sql_4;
   COMMIT;
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST3_PK_BI'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE v_sql_3;
      EXECUTE IMMEDIATE v_sql_4;
      COMMIT;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST3_PK_BI'
      );
END crt_tab_test3_pk_bi;
/

EXECUTE crt_tab_test3;
EXECUTE crt_tab_test3_pk;
EXECUTE crt_tab_test3_bi;
EXECUTE crt_tab_test3_pk_bi;

PROMPT ************************************************************************************
PROMPT * Checking real execution plan and meanwhile generating 10053 trc file by querying *
PROMPT * COUNT(*|1|id|flag) on 4 different tables 'TEST3', 'TEST3_PK', 'TEST3_BI', and    *
PROMPT * 'TEST3_PK_BI' on the same session (SQL*Plus window).                             *
PROMPT ************************************************************************************

SET LINESIZE 150
SET PAGESIZE 150
SET SERVEROUTPUT OFF

-- At the session level, enabling to check the real execution plan
ALTER SESSION SET statistics_level = all;

-- At the session level, enabling to open 10053 event
ALTER SESSION SET max_dump_file_size = 'UNLIMITED';
ALTER SESSION SET tracefile_identifier = '10053_test3';
ALTER SESSION SET EVENTS '10053 trace name context forever, level 1';

-- Querying count(*|1|id|flag) from table 'TEST' and next to checking their row source execution plan
SELECT COUNT(*) FROM test3;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test3;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test3;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test3;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_PK' and next to checking their row source execution plan
SELECT COUNT(*) FROM test3_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test3_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test3_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test3_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_BI' and next to checking their row source execution plan
SELECT COUNT(*) FROM test3_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test3_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test3_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test3_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_PK_BI' and next to checking their row source execution plan
SELECT COUNT(*) FROM test3_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test3_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test3_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test3_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- At the session level, enabling to close 10053 event
ALTER SESSION SET EVENTS '10053 trace name context off';
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';

PROMPT ===============================
PROMPT the real execution plan on 18.3
PROMPT ===============================

-- SQL_ID  1xys06g1u8fau, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test3
-- 
-- Plan hash value: 1832809687
-- 
-- --------------------------------------------------------------------------------------
-- | Id  | Operation          | Name  | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |       |      1 |        |      1 |00:00:01.61 |     116K|
-- |   1 |  SORT AGGREGATE    |       |      1 |      1 |      1 |00:00:01.61 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST3 |      1 |     50M|     50M|00:00:01.59 |     116K|
-- --------------------------------------------------------------------------------------
-- 
-- SQL_ID  96vs2qqbpn851, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test3
-- 
-- Plan hash value: 1832809687
-- 
-- --------------------------------------------------------------------------------------
-- | Id  | Operation          | Name  | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |       |      1 |        |      1 |00:00:00.86 |     116K|
-- |   1 |  SORT AGGREGATE    |       |      1 |      1 |      1 |00:00:00.86 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST3 |      1 |     50M|     50M|00:00:00.85 |     116K|
-- --------------------------------------------------------------------------------------
-- 
-- SQL_ID  cb76psjm19apj, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test3
-- 
-- Plan hash value: 1832809687
-- 
-- --------------------------------------------------------------------------------------
-- | Id  | Operation          | Name  | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |       |      1 |        |      1 |00:00:00.86 |     116K|
-- |   1 |  SORT AGGREGATE    |       |      1 |      1 |      1 |00:00:00.86 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST3 |      1 |     50M|     50M|00:00:00.85 |     116K|
-- --------------------------------------------------------------------------------------
-- 
-- SQL_ID  cnystxdkt6hnr, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test3
-- 
-- Plan hash value: 1832809687
-- 
-- --------------------------------------------------------------------------------------
-- | Id  | Operation          | Name  | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |       |      1 |        |      1 |00:00:01.02 |     116K|
-- |   1 |  SORT AGGREGATE    |       |      1 |      1 |      1 |00:00:01.02 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST3 |      1 |     50M|     50M|00:00:01.01 |     116K|
-- --------------------------------------------------------------------------------------
-- 
-- SQL_ID  5nj3m2nc7zsu6, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test3_pk
-- 
-- Plan hash value: 925588815
-- 
-- -------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |               |      1 |        |      1 |00:00:05.70 |     100K|
-- |   1 |  SORT AGGREGATE       |               |      1 |      1 |      1 |00:00:05.70 |     100K|
-- |   2 |   INDEX FAST FULL SCAN| TEST3_ONLY_PK |      1 |     50M|     50M|00:00:03.88 |     100K|
-- -------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  9k9w7b09vhngu, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test3_pk
-- 
-- Plan hash value: 925588815
-- 
-- -------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |               |      1 |        |      1 |00:00:05.71 |     100K|
-- |   1 |  SORT AGGREGATE       |               |      1 |      1 |      1 |00:00:05.71 |     100K|
-- |   2 |   INDEX FAST FULL SCAN| TEST3_ONLY_PK |      1 |     50M|     50M|00:00:03.89 |     100K|
-- -------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  58ug4x5xv43mj, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test3_pk
-- 
-- Plan hash value: 925588815
-- 
-- -------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |               |      1 |        |      1 |00:00:05.69 |     100K|
-- |   1 |  SORT AGGREGATE       |               |      1 |      1 |      1 |00:00:05.69 |     100K|
-- |   2 |   INDEX FAST FULL SCAN| TEST3_ONLY_PK |      1 |     50M|     50M|00:00:03.87 |     100K|
-- -------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  8wc75gkh1bjby, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test3_pk
-- 
-- Plan hash value: 925588815
-- 
-- -------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |               |      1 |        |      1 |00:00:05.68 |     100K|
-- |   1 |  SORT AGGREGATE       |               |      1 |      1 |      1 |00:00:05.68 |     100K|
-- |   2 |   INDEX FAST FULL SCAN| TEST3_ONLY_PK |      1 |     50M|     50M|00:00:03.86 |     100K|
-- -------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  2atw0gtqdvafv, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test3_bi
-- 
-- Plan hash value: 841407947
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     957 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  96r1juyt2442b, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test3_bi
-- 
-- Plan hash value: 841407947
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     957 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.01 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  0rb3dg0z4w617, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test3_bi
-- 
-- Plan hash value: 841407947
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     957 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  2z5x70fm43au0, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test3_bi
-- 
-- Plan hash value: 841407947
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     957 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  5fhcjg9rs3utt, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test3_pk_bi
-- 
-- Plan hash value: 3257137296
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     957 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  6wzpvgz8kvt4p, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test3_pk_bi
-- 
-- Plan hash value: 3257137296
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.01 |     957 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.01 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.01 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  3a6g8zga0pmgf, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test3_pk_bi
-- 
-- Plan hash value: 3257137296
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.01 |     957 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.01 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.01 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  0bpcywdvhzg2c, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test3_pk_bi
-- 
-- Plan hash value: 3257137296
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.01 |     957 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.01 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.01 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ----------------------------------------------------------------------------------------------------

PROMPT ===============================
PROMPT the real execution plan on 11.2
PROMPT ===============================

-- SQL_ID  1xys06g1u8fau, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test3
-- 
-- Plan hash value: 1832809687
-- 
-- --------------------------------------------------------------------------------------
-- | Id  | Operation          | Name  | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |       |      1 |        |      1 |00:00:08.47 |     116K|
-- |   1 |  SORT AGGREGATE    |       |      1 |      1 |      1 |00:00:08.47 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST3 |      1 |     50M|     50M|00:00:05.17 |     116K|
-- --------------------------------------------------------------------------------------
-- 
-- SQL_ID  96vs2qqbpn851, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test3
-- 
-- Plan hash value: 1832809687
-- 
-- --------------------------------------------------------------------------------------
-- | Id  | Operation          | Name  | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |       |      1 |        |      1 |00:00:08.08 |     116K|
-- |   1 |  SORT AGGREGATE    |       |      1 |      1 |      1 |00:00:08.08 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST3 |      1 |     50M|     50M|00:00:04.76 |     116K|
-- --------------------------------------------------------------------------------------
-- 
-- SQL_ID  cb76psjm19apj, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test3
-- 
-- Plan hash value: 1832809687
-- 
-- --------------------------------------------------------------------------------------
-- | Id  | Operation          | Name  | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |       |      1 |        |      1 |00:00:07.79 |     116K|
-- |   1 |  SORT AGGREGATE    |       |      1 |      1 |      1 |00:00:07.79 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST3 |      1 |     50M|     50M|00:00:04.60 |     116K|
-- --------------------------------------------------------------------------------------
-- 
-- SQL_ID  cnystxdkt6hnr, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test3
-- 
-- Plan hash value: 1832809687
-- 
-- --------------------------------------------------------------------------------------
-- | Id  | Operation          | Name  | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |       |      1 |        |      1 |00:00:08.27 |     116K|
-- |   1 |  SORT AGGREGATE    |       |      1 |      1 |      1 |00:00:08.27 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST3 |      1 |     50M|     50M|00:00:04.85 |     116K|
-- --------------------------------------------------------------------------------------
-- 
-- SQL_ID  5nj3m2nc7zsu6, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test3_pk
-- 
-- Plan hash value: 925588815
-- 
-- -------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |               |      1 |        |      1 |00:00:08.62 |     101K|
-- |   1 |  SORT AGGREGATE       |               |      1 |      1 |      1 |00:00:08.62 |     101K|
-- |   2 |   INDEX FAST FULL SCAN| TEST3_ONLY_PK |      1 |     50M|     50M|00:00:05.40 |     101K|
-- -------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  9k9w7b09vhngu, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test3_pk
-- 
-- Plan hash value: 925588815
-- 
-- -------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |               |      1 |        |      1 |00:00:08.65 |     100K|
-- |   1 |  SORT AGGREGATE       |               |      1 |      1 |      1 |00:00:08.65 |     100K|
-- |   2 |   INDEX FAST FULL SCAN| TEST3_ONLY_PK |      1 |     50M|     50M|00:00:05.32 |     100K|
-- -------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  58ug4x5xv43mj, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test3_pk
-- 
-- Plan hash value: 925588815
-- 
-- -------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |               |      1 |        |      1 |00:00:08.32 |     100K|
-- |   1 |  SORT AGGREGATE       |               |      1 |      1 |      1 |00:00:08.32 |     100K|
-- |   2 |   INDEX FAST FULL SCAN| TEST3_ONLY_PK |      1 |     50M|     50M|00:00:05.12 |     100K|
-- -------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  8wc75gkh1bjby, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test3_pk
-- 
-- Plan hash value: 925588815
-- 
-- -------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |               |      1 |        |      1 |00:00:08.35 |     100K|
-- |   1 |  SORT AGGREGATE       |               |      1 |      1 |      1 |00:00:08.35 |     100K|
-- |   2 |   INDEX FAST FULL SCAN| TEST3_ONLY_PK |      1 |     50M|     50M|00:00:05.14 |     100K|
-- -------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  2atw0gtqdvafv, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test3_bi
-- 
-- Plan hash value: 841407947
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  96r1juyt2442b, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test3_bi
-- 
-- Plan hash value: 841407947
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  0rb3dg0z4w617, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test3_bi
-- 
-- Plan hash value: 841407947
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  2z5x70fm43au0, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test3_bi
-- 
-- Plan hash value: 841407947
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  5fhcjg9rs3utt, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test3_pk_bi
-- 
-- Plan hash value: 3257137296
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  6wzpvgz8kvt4p, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test3_pk_bi
-- 
-- Plan hash value: 3257137296
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  3a6g8zga0pmgf, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test3_pk_bi
-- 
-- Plan hash value: 3257137296
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  0bpcywdvhzg2c, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test3_pk_bi
-- 
-- Plan hash value: 3257137296
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST3_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ----------------------------------------------------------------------------------------------------
