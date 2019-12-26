REM
REM     Script:        checking_exec_plan_of_querying_cnt_table.sql
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
REM               'TEST', 'TEST_PK', 'TEST_BI' and 'TEST_PK_BI';
REM           (3) checking real execution plan and meanwhile generating 10053 trc file by querying
REM               COUNT(*|1|id|flag) on the previous 4 different tables;
REM        By the way those tables are going to be dynamically created by using several
REM        oracle PL/SQL procedures. I just use 'CTAS' (a very simple approach creating table)
REM        to create my TEST tables with two physical properties (SEGMENT CREATION IMMEDIATE and
REM        NOLOGGING) and a table property (NO PARALLEL).
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
PROMPT *  (1) test: no primary key and bitmap index;                      *
PROMPT *  (2) test_pk: only primary key  => test_only_pk;                 *
PROMPT *  (3) test_bi: only bitmap index => test_only_bi;                 *
PROMPT *  (4) test_pk_bi: primary key    => test_pk,                      *
PROMPT *                  bitmap index   => test_bi;                      *
PROMPT ********************************************************************

CONN qwz/qwz

SET TIMING ON

CREATE OR REPLACE PROCEDURE crt_tab_test
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test PURGE';
   v_sql_2 := q'[CREATE TABLE test 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 -- PARALLEL 10 
                 AS SELECT ROWNUM id 
                           , CASE WHEN ROWNUM BETWEEN  1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[              WHEN ROWNUM BETWEEN  2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[              WHEN ROWNUM BETWEEN  4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[              ELSE 'unknown' 
                             END flag 
                    FROM XMLTABLE('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST'
      );
END crt_tab_test;
/

CREATE OR REPLACE PROCEDURE crt_tab_test_pk
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test_pk PURGE';
   v_sql_2 := q'[CREATE TABLE test_pk 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 -- PARALLEL 10 
                 AS SELECT ROWNUM id 
                           , CASE WHEN ROWNUM BETWEEN  1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[              WHEN ROWNUM BETWEEN  2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[              WHEN ROWNUM BETWEEN  4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[              ELSE 'unknown' 
                             END flag 
                    FROM XMLTABLE('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE 'ALTER TABLE test_pk ADD CONSTRAINT test_only_pk PRIMARY KEY (id)';
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST_PK'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE 'ALTER TABLE test_pk ADD CONSTRAINT test_only_pk PRIMARY KEY (id)';
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST_PK'
      );
END crt_tab_test_pk;
/

CREATE OR REPLACE PROCEDURE crt_tab_test_bi
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test_bi PURGE';
   v_sql_2 := q'[CREATE TABLE test_bi 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 -- PARALLEL 10 
                 AS SELECT ROWNUM id 
                           , CASE WHEN ROWNUM BETWEEN  1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[              WHEN ROWNUM BETWEEN  2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[              WHEN ROWNUM BETWEEN  4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[              ELSE 'unknown' 
                             END flag 
                    FROM XMLTABLE('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE 'CREATE BITMAP INDEX test_only_bi ON test_bi (flag)';
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST_BI'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE 'CREATE BITMAP INDEX test_only_bi ON test_bi (flag)';
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST_BI'
      );
END crt_tab_test_bi;
/

CREATE OR REPLACE PROCEDURE crt_tab_test_pk_bi
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test_pk_bi PURGE';
   v_sql_2 := q'[CREATE TABLE test_pk_bi 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 -- PARALLEL 10 
                 AS SELECT ROWNUM id 
                           , CASE WHEN ROWNUM BETWEEN  1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[              WHEN ROWNUM BETWEEN  2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[              WHEN ROWNUM BETWEEN  4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[              ELSE 'unknown' 
                             END flag 
                    FROM XMLTABLE('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE 'ALTER TABLE test_pk_bi ADD CONSTRAINT test_pk PRIMARY KEY (id)';
   EXECUTE IMMEDIATE 'CREATE BITMAP INDEX test_bi ON test_pk_bi (flag)';
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST_PK_BI'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE 'ALTER TABLE test_pk_bi ADD CONSTRAINT test_pk PRIMARY KEY (id)';
      EXECUTE IMMEDIATE 'CREATE BITMAP INDEX test_bi ON test_pk_bi (flag)';
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST_PK_BI'
      );
END crt_tab_test_pk_bi;
/

EXECUTE crt_tab_test;
EXECUTE crt_tab_test_pk;
EXECUTE crt_tab_test_bi;
EXECUTE crt_tab_test_pk_bi;

PROMPT ************************************************************************************
PROMPT * Checking real execution plan and meanwhile generating 10053 trc file by querying *
PROMPT * COUNT(*|1|id|flag) on 4 different tables 'TEST', 'TEST_PK', 'TEST_BI', and       *
PROMPT * 'TEST_PK_BI' on the same session (SQL*Plus window).                              *
PROMPT ************************************************************************************

SET LINESIZE 150
SET PAGESIZE 150
SET SERVEROUTPUT OFF

-- At the session level, enabling to check the real execution plan
ALTER SESSION SET statistics_level = all;

-- At the session level, enabling to open 10053 event
ALTER SESSION SET max_dump_file_size = 'UNLIMITED';
ALTER SESSION SET tracefile_identifier = '10053_test';
ALTER SESSION SET EVENTS '10053 trace name context forever, level 1';

-- Querying count(*|1|id|flag) from table 'TEST' and next to checking their row source execution plan
SELECT COUNT(*) FROM test;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_PK' and next to checking their row source execution plan
SELECT COUNT(*) FROM test_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_BI' and next to checking their row source execution plan
SELECT COUNT(*) FROM test_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_PK_BI' and next to checking their row source execution plan
SELECT COUNT(*) FROM test_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- At the session level, enabling to close 10053 event
ALTER SESSION SET EVENTS '10053 trace name context off';
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';

PROMPT ===============================
PROMPT the real execution plan of 18.3
PROMPT ===============================

-- SQL_ID  068c88cnk1xkm, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test
-- 
-- Plan hash value: 1950795681
-- 
-- -------------------------------------------------------------------------------------
-- | Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |      |      1 |        |      1 |00:00:01.02 |     116K|
-- |   1 |  SORT AGGREGATE    |      |      1 |      1 |      1 |00:00:01.02 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST |      1 |     50M|     50M|00:00:01.01 |     116K|
-- -------------------------------------------------------------------------------------
-- 
-- SQL_ID  1axq6b0shb1q2, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test
-- 
-- Plan hash value: 1950795681
-- 
-- -------------------------------------------------------------------------------------
-- | Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |      |      1 |        |      1 |00:00:00.82 |     116K|
-- |   1 |  SORT AGGREGATE    |      |      1 |      1 |      1 |00:00:00.82 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST |      1 |     50M|     50M|00:00:00.82 |     116K|
-- -------------------------------------------------------------------------------------
-- 
-- SQL_ID  aycmyd7304cnf, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test
-- 
-- Plan hash value: 1950795681
-- 
-- -------------------------------------------------------------------------------------
-- | Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |      |      1 |        |      1 |00:00:01.34 |     116K|
-- |   1 |  SORT AGGREGATE    |      |      1 |      1 |      1 |00:00:01.34 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST |      1 |     50M|     50M|00:00:01.25 |     116K|
-- -------------------------------------------------------------------------------------
-- 
-- SQL_ID  5rupd7t2fc8dw, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test
-- 
-- Plan hash value: 1950795681
-- 
-- -------------------------------------------------------------------------------------
-- | Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |      |      1 |        |      1 |00:00:01.39 |     116K|
-- |   1 |  SORT AGGREGATE    |      |      1 |      1 |      1 |00:00:01.39 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST |      1 |     50M|     50M|00:00:01.31 |     116K|
-- -------------------------------------------------------------------------------------
-- 
-- SQL_ID  7u8r76f06gscq, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test_pk
-- 
-- Plan hash value: 1614421910
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |              |      1 |        |      1 |00:00:07.38 |     111K|    103K|
-- |   1 |  SORT AGGREGATE       |              |      1 |      1 |      1 |00:00:07.38 |     111K|    103K|
-- |   2 |   INDEX FAST FULL SCAN| TEST_ONLY_PK |      1 |     50M|     50M|00:00:05.40 |     111K|    103K|
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  gu1kdcchtdc2d, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test_pk
-- 
-- Plan hash value: 1614421910
-- 
-- ------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |              |      1 |        |      1 |00:00:05.85 |     111K|
-- |   1 |  SORT AGGREGATE       |              |      1 |      1 |      1 |00:00:05.85 |     111K|
-- |   2 |   INDEX FAST FULL SCAN| TEST_ONLY_PK |      1 |     50M|     50M|00:00:03.96 |     111K|
-- ------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  1a55zxg4za05m, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test_pk
-- 
-- Plan hash value: 1614421910
-- 
-- ------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |              |      1 |        |      1 |00:00:05.86 |     111K|
-- |   1 |  SORT AGGREGATE       |              |      1 |      1 |      1 |00:00:05.86 |     111K|
-- |   2 |   INDEX FAST FULL SCAN| TEST_ONLY_PK |      1 |     50M|     50M|00:00:03.97 |     111K|
-- ------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  1ca9t4kpd04zh, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test_pk
-- 
-- Plan hash value: 262554536
-- 
-- ----------------------------------------------------------------------------------------
-- | Id  | Operation          | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |         |      1 |        |      1 |00:00:01.91 |     116K|
-- |   1 |  SORT AGGREGATE    |         |      1 |      1 |      1 |00:00:01.91 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST_PK |      1 |     50M|     50M|00:00:01.82 |     116K|
-- ----------------------------------------------------------------------------------------
-- 
-- SQL_ID  c6313xfz7kyn6, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test_bi
-- 
-- Plan hash value: 389383459
-- 
-- --------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |              |      1 |        |      1 |00:00:00.02 |    1046 |
-- |   1 |  SORT AGGREGATE               |              |      1 |      1 |      1 |00:00:00.02 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |              |      1 |     50M|   2065 |00:00:00.02 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_ONLY_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- --------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  6br8rnjjc4xvb, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test_bi
-- 
-- Plan hash value: 389383459
-- 
-- --------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |              |      1 |        |      1 |00:00:00.02 |    1046 |
-- |   1 |  SORT AGGREGATE               |              |      1 |      1 |      1 |00:00:00.02 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |              |      1 |     50M|   2065 |00:00:00.02 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_ONLY_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- --------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  a7gq7x9hyhcg0, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test_bi
-- 
-- Plan hash value: 950576497
-- 
-- ----------------------------------------------------------------------------------------
-- | Id  | Operation          | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |         |      1 |        |      1 |00:00:01.87 |     116K|
-- |   1 |  SORT AGGREGATE    |         |      1 |      1 |      1 |00:00:01.87 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST_BI |      1 |     50M|     50M|00:00:01.78 |     116K|
-- ----------------------------------------------------------------------------------------
-- 
-- SQL_ID  1xkds9uk68hmq, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test_bi
-- 
-- Plan hash value: 2896346787
-- 
-- --------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |              |      1 |        |      1 |00:00:05.50 |    1046 |
-- |   1 |  SORT AGGREGATE               |              |      1 |      1 |      1 |00:00:05.50 |    1046 |
-- |   2 |   BITMAP CONVERSION TO ROWIDS |              |      1 |     50M|     50M|00:00:03.07 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_ONLY_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- --------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  djgsn24c8hpb2, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test_pk_bi
-- 
-- Plan hash value: 114976402
-- 
-- ---------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |         |      1 |        |      1 |00:00:00.02 |    1046 |
-- |   1 |  SORT AGGREGATE               |         |      1 |      1 |      1 |00:00:00.02 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |         |      1 |     50M|   2065 |00:00:00.02 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- ---------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  93s6bvzpqgxbt, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test_pk_bi
-- 
-- Plan hash value: 114976402
-- 
-- ---------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |         |      1 |        |      1 |00:00:00.03 |    1046 |
-- |   1 |  SORT AGGREGATE               |         |      1 |      1 |      1 |00:00:00.03 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |         |      1 |     50M|   2065 |00:00:00.03 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- ---------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  bsu77u1gch17z, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test_pk_bi
-- 
-- Plan hash value: 114976402
-- 
-- ---------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |         |      1 |        |      1 |00:00:00.03 |    1046 |
-- |   1 |  SORT AGGREGATE               |         |      1 |      1 |      1 |00:00:00.03 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |         |      1 |     50M|   2065 |00:00:00.03 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- ---------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  3awj9bwtsbms9, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test_pk_bi
-- 
-- Plan hash value: 427023172
-- 
-- ---------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |         |      1 |        |      1 |00:00:05.74 |    1046 |
-- |   1 |  SORT AGGREGATE               |         |      1 |      1 |      1 |00:00:05.74 |    1046 |
-- |   2 |   BITMAP CONVERSION TO ROWIDS |         |      1 |     50M|     50M|00:00:03.23 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- ---------------------------------------------------------------------------------------------------

PROMPT ===============================
PROMPT the real execution plan of 11.2
PROMPT ===============================

-- SQL_ID  068c88cnk1xkm, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test
-- 
-- Plan hash value: 1950795681
-- 
-- -------------------------------------------------------------------------------------
-- | Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |      |      1 |        |      1 |00:00:08.20 |     116K|
-- |   1 |  SORT AGGREGATE    |      |      1 |      1 |      1 |00:00:08.20 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST |      1 |     50M|     50M|00:00:04.89 |     116K|
-- -------------------------------------------------------------------------------------
-- 
-- SQL_ID  1axq6b0shb1q2, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test
-- 
-- Plan hash value: 1950795681
-- 
-- -------------------------------------------------------------------------------------
-- | Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |      |      1 |        |      1 |00:00:07.82 |     116K|
-- |   1 |  SORT AGGREGATE    |      |      1 |      1 |      1 |00:00:07.82 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST |      1 |     50M|     50M|00:00:04.64 |     116K|
-- -------------------------------------------------------------------------------------
-- 
-- SQL_ID  aycmyd7304cnf, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test
-- 
-- Plan hash value: 1950795681
-- 
-- -------------------------------------------------------------------------------------
-- | Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |      |      1 |        |      1 |00:00:09.00 |     116K|
-- |   1 |  SORT AGGREGATE    |      |      1 |      1 |      1 |00:00:09.00 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST |      1 |     50M|     50M|00:00:05.11 |     116K|
-- -------------------------------------------------------------------------------------
-- 
-- SQL_ID  5rupd7t2fc8dw, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test
-- 
-- Plan hash value: 1950795681
-- 
-- -------------------------------------------------------------------------------------
-- | Id  | Operation          | Name | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- -------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |      |      1 |        |      1 |00:00:09.14 |     116K|
-- |   1 |  SORT AGGREGATE    |      |      1 |      1 |      1 |00:00:09.14 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST |      1 |     50M|     50M|00:00:05.25 |     116K|
-- -------------------------------------------------------------------------------------
-- 
-- SQL_ID  7u8r76f06gscq, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test_pk
-- 
-- Plan hash value: 1614421910
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |              |      1 |        |      1 |00:00:10.98 |     111K|    103K|
-- |   1 |  SORT AGGREGATE       |              |      1 |      1 |      1 |00:00:10.98 |     111K|    103K|
-- |   2 |   INDEX FAST FULL SCAN| TEST_ONLY_PK |      1 |     50M|     50M|00:00:07.56 |     111K|    103K|
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  gu1kdcchtdc2d, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test_pk
-- 
-- Plan hash value: 1614421910
-- 
-- ------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |              |      1 |        |      1 |00:00:08.88 |     111K|
-- |   1 |  SORT AGGREGATE       |              |      1 |      1 |      1 |00:00:08.88 |     111K|
-- |   2 |   INDEX FAST FULL SCAN| TEST_ONLY_PK |      1 |     50M|     50M|00:00:05.70 |     111K|
-- ------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  1a55zxg4za05m, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test_pk
-- 
-- Plan hash value: 1614421910
-- 
-- ------------------------------------------------------------------------------------------------
-- | Id  | Operation             | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT      |              |      1 |        |      1 |00:00:08.67 |     111K|
-- |   1 |  SORT AGGREGATE       |              |      1 |      1 |      1 |00:00:08.67 |     111K|
-- |   2 |   INDEX FAST FULL SCAN| TEST_ONLY_PK |      1 |     50M|     50M|00:00:05.48 |     111K|
-- ------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  1ca9t4kpd04zh, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test_pk
-- 
-- Plan hash value: 262554536
-- 
-- ----------------------------------------------------------------------------------------
-- | Id  | Operation          | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |         |      1 |        |      1 |00:00:09.74 |     116K|
-- |   1 |  SORT AGGREGATE    |         |      1 |      1 |      1 |00:00:09.74 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST_PK |      1 |     50M|     50M|00:00:05.83 |     116K|
-- ----------------------------------------------------------------------------------------
-- 
-- SQL_ID  c6313xfz7kyn6, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test_bi
-- 
-- Plan hash value: 389383459
-- 
-- --------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |              |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |              |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |              |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_ONLY_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- --------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  6br8rnjjc4xvb, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test_bi
-- 
-- Plan hash value: 389383459
-- 
-- --------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |              |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |              |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |              |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_ONLY_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- --------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  a7gq7x9hyhcg0, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test_bi
-- 
-- Plan hash value: 950576497
-- 
-- ----------------------------------------------------------------------------------------
-- | Id  | Operation          | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT   |         |      1 |        |      1 |00:00:09.55 |     116K|
-- |   1 |  SORT AGGREGATE    |         |      1 |      1 |      1 |00:00:09.55 |     116K|
-- |   2 |   TABLE ACCESS FULL| TEST_BI |      1 |     50M|     50M|00:00:05.65 |     116K|
-- ----------------------------------------------------------------------------------------
-- 
-- SQL_ID  1xkds9uk68hmq, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test_bi
-- 
-- Plan hash value: 2896346787
-- 
-- --------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- --------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |              |      1 |        |      1 |00:00:08.56 |    1045 |
-- |   1 |  SORT AGGREGATE               |              |      1 |      1 |      1 |00:00:08.56 |    1045 |
-- |   2 |   BITMAP CONVERSION TO ROWIDS |              |      1 |     50M|     50M|00:00:04.70 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_ONLY_BI |      1 |        |   2065 |00:00:00.02 |    1045 |
-- --------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  djgsn24c8hpb2, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test_pk_bi
-- 
-- Plan hash value: 114976402
-- 
-- ---------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |         |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |         |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |         |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- ---------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  93s6bvzpqgxbt, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test_pk_bi
-- 
-- Plan hash value: 114976402
-- 
-- ---------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |         |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |         |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |         |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- ---------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  bsu77u1gch17z, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test_pk_bi
-- 
-- Plan hash value: 114976402
-- 
-- ---------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |         |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |         |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |         |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- ---------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  3awj9bwtsbms9, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test_pk_bi
-- 
-- Plan hash value: 427023172
-- 
-- ---------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name    | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |         |      1 |        |      1 |00:00:08.60 |    1045 |
-- |   1 |  SORT AGGREGATE               |         |      1 |      1 |      1 |00:00:08.60 |    1045 |
-- |   2 |   BITMAP CONVERSION TO ROWIDS |         |      1 |     50M|     50M|00:00:04.76 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST_BI |      1 |        |   2065 |00:00:00.02 |    1045 |
-- ---------------------------------------------------------------------------------------------------
