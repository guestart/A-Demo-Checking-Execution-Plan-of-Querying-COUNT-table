REM
REM     Script:        checking_exec_plan_of_querying_cnt_table_4.sql
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
REM               'TEST4', 'TEST4_PK', 'TEST4_BI' and 'TEST4_PK_BI';
REM           (3) checking real execution plan and meanwhile generating 10053 trc file by querying
REM               COUNT(*|1|id|flag) on the previous 4 different tables;
REM        By the way those tables are going to be dynamically created by using several
REM        oracle PL/SQL procedures. I just use the standard SQL syntax 'CREATE TABLE'
REM        to create my TEST4 tables with two physical properties (SEGMENT CREATION IMMEDIATE and
REM        NOLOGGING) and a table property (PARALLEL) and then also create corresponding
REM        PRIMARY KEY or BITMAP INDEX on those different TEST4 tables. Finally inserting
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
PROMPT *  (1) test4: no primary key and bitmap index;                     *
PROMPT *  (2) test4_pk: only primary key  => test4_only_pk;               *
PROMPT *  (3) test4_bi: only bitmap index => test4_only_bi;               *
PROMPT *  (4) test4_pk_bi: primary key    => test4_pk,                    *
PROMPT *                   bitmap index   => test4_bi;                    *
PROMPT ********************************************************************

CONN qwz/qwz

SET TIMING ON

CREATE OR REPLACE PROCEDURE crt_tab_test4
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
   v_sql_3 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test4 PURGE';
   v_sql_2 := q'[CREATE TABLE test4 ( 
                    id     NUMBER      NOT NULL 
                    , flag VARCHAR2(7) NOT NULL 
                 ) 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 PARALLEL 10
                ]';
   v_sql_3 := q'[INSERT /*+ append */ INTO test4 
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
           TABNAME            => 'TEST4'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE v_sql_3;
      COMMIT;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST4'
      );
END crt_tab_test4;
/

CREATE OR REPLACE PROCEDURE crt_tab_test4_pk
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
   v_sql_3 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test4_pk PURGE';
   v_sql_2 := q'[CREATE TABLE test4_pk ( 
                    id     NUMBER      NOT NULL CONSTRAINT test4_only_pk PRIMARY KEY 
                    , flag VARCHAR2(7) NOT NULL 
                 ) 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 PARALLEL 10
                ]';
   v_sql_3 := q'[INSERT /*+ append */ INTO test4_pk 
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
           TABNAME            => 'TEST4_PK'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE v_sql_3;
      COMMIT;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST4_PK'
      );
END crt_tab_test4_pk;
/

CREATE OR REPLACE PROCEDURE crt_tab_test4_bi
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
   v_sql_3 VARCHAR2(2000);
   v_sql_4 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test4_bi PURGE';
   v_sql_2 := q'[CREATE TABLE test4_bi ( 
                    id     NUMBER      NOT NULL 
                    , flag VARCHAR2(7) NOT NULL 
                 ) 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 PARALLEL 10
                ]';
   v_sql_3 := 'CREATE BITMAP INDEX test4_only_bi ON test4_bi (flag)';
   v_sql_4 := q'[INSERT /*+ append */ INTO test4_bi 
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
           TABNAME            => 'TEST4_BI'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE v_sql_3;
      EXECUTE IMMEDIATE v_sql_4;
      COMMIT;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST4_BI'
      );
END crt_tab_test4_bi;
/

CREATE OR REPLACE PROCEDURE crt_tab_test4_pk_bi
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
   v_sql_3 VARCHAR2(2000);
   v_sql_4 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test4_pk_bi PURGE';
   v_sql_2 := q'[CREATE TABLE test4_pk_bi ( 
                    id     NUMBER      NOT NULL CONSTRAINT test4_pk PRIMARY KEY 
                    , flag VARCHAR2(7) NOT NULL 
                 ) 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 PARALLEL 10
                ]';
   v_sql_3 := 'CREATE BITMAP INDEX test4_bi ON test4_pk_bi (flag)';
   v_sql_4 := q'[INSERT /*+ append */ INTO test4_pk_bi 
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
           TABNAME            => 'TEST4_PK_BI'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE v_sql_3;
      EXECUTE IMMEDIATE v_sql_4;
      COMMIT;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST4_PK_BI'
      );
END crt_tab_test4_pk_bi;
/

EXECUTE crt_tab_test4;
EXECUTE crt_tab_test4_pk;
EXECUTE crt_tab_test4_bi;
EXECUTE crt_tab_test4_pk_bi;

PROMPT ************************************************************************************
PROMPT * Checking real execution plan and meanwhile generating 10053 trc file by querying *
PROMPT * COUNT(*|1|id|flag) on 4 different tables 'TEST4', 'TEST4_PK', 'TEST4_BI', and    *
PROMPT * 'TEST4_PK_BI' on the same session (SQL*Plus window).                             *
PROMPT ************************************************************************************

SET LINESIZE 150
SET PAGESIZE 150
SET SERVEROUTPUT OFF

-- At the session level, enabling to check the real execution plan
ALTER SESSION SET statistics_level = all;

-- At the session level, enabling to open 10053 event
ALTER SESSION SET max_dump_file_size = 'UNLIMITED';
ALTER SESSION SET tracefile_identifier = '10053_test4';
ALTER SESSION SET EVENTS '10053 trace name context forever, level 1';

-- Querying count(*|1|id|flag) from table 'TEST' and next to checking their row source execution plan
SELECT COUNT(*) FROM test4;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test4;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test4;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test4;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_PK' and next to checking their row source execution plan
SELECT COUNT(*) FROM test4_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test4_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test4_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test4_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_BI' and next to checking their row source execution plan
SELECT COUNT(*) FROM test4_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test4_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test4_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test4_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_PK_BI' and next to checking their row source execution plan
SELECT COUNT(*) FROM test4_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test4_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test4_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test4_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- At the session level, enabling to close 10053 event
ALTER SESSION SET EVENTS '10053 trace name context off';
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';

PROMPT ===============================
PROMPT the real execution plan of 18.3
PROMPT ===============================

-- SQL_ID  ff2tqgyvac68p, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test4
-- 
-- Plan hash value: 2402724102
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.27 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.27 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.27 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- Note
-- -----
--    - Degree of Parallelism is 10 because of table property
-- 
-- SQL_ID  4y7f40wkd76mw, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test4
-- 
-- Plan hash value: 2402724102
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.20 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.20 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.20 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- Note
-- -----
--    - Degree of Parallelism is 10 because of table property   
-- 
-- SQL_ID  fa5h9t69sza7d, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test4
-- 
-- Plan hash value: 2402724102
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.21 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.21 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.21 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- Note
-- -----
--    - Degree of Parallelism is 10 because of table property
-- 
-- SQL_ID  699r0r0q5uydx, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test4
-- 
-- Plan hash value: 2402724102
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.20 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.20 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.20 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- Note
-- -----
--    - Degree of Parallelism is 10 because of table property
-- 
-- SQL_ID  9fbrr83p1bn72, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test4_pk
-- 
-- Plan hash value: 3300041866
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.27 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.27 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.27 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- Note
-- -----
--    - Degree of Parallelism is 10 because of table property   
-- 
-- SQL_ID  bbgac5gajhxvc, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test4_pk
-- 
-- Plan hash value: 3300041866
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.28 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.28 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.28 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- Note
-- -----
--    - Degree of Parallelism is 10 because of table property
-- 
-- SQL_ID  7d8u9xr3tzykz, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test4_pk
-- 
-- Plan hash value: 3300041866
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.27 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.27 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.27 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- Note
-- -----
--    - Degree of Parallelism is 10 because of table property   
-- 
-- SQL_ID  1sym8uq7290z0, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test4_pk
-- 
-- Plan hash value: 3300041866
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.24 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.24 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.24 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- Note
-- -----
--    - Degree of Parallelism is 10 because of table property
-- 
-- SQL_ID  3ggkp8vk6nwu7, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test4_bi
-- 
-- Plan hash value: 1510060295
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.04 |     957 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.04 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.04 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_ONLY_BI |      1 |        |   1849 |00:00:00.02 |     957 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  8pk0c4ydvjw0x, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test4_bi
-- 
-- Plan hash value: 1510060295
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.03 |     957 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.03 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.03 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  1khycmqr6d8t8, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test4_bi
-- 
-- Plan hash value: 1510060295
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.03 |     957 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.03 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.03 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  b39pfyxap7s7u, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test4_bi
-- 
-- Plan hash value: 1510060295
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.03 |     957 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.03 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.03 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  9zv8rr2qqpn7y, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test4_pk_bi
-- 
-- Plan hash value: 1466733283
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     957 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  0qv5g3zujdau4, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test4_pk_bi
-- 
-- Plan hash value: 1466733283
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.01 |     957 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.01 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.01 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  fjf5zq4mjvq7h, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test4_pk_bi
-- 
-- Plan hash value: 1466733283
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.01 |     957 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.01 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.01 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  63k83umnpft2g, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test4_pk_bi
-- 
-- Plan hash value: 1466733283
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.01 |     957 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.01 |     957 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.01 |     957 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_BI |      1 |        |   1849 |00:00:00.01 |     957 |
-------------------------------------------------------------------------------------------------------

PROMPT ===============================
PROMPT the real execution plan of 11.2
PROMPT ===============================

-- SQL_ID  ff2tqgyvac68p, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test4
-- 
-- Plan hash value: 2402724102
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:02.09 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:02.09 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:02.09 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  4y7f40wkd76mw, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test4
-- 
-- Plan hash value: 2402724102
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.83 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.83 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.83 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  fa5h9t69sza7d, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test4
-- 
-- Plan hash value: 2402724102
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.78 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.78 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.78 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  699r0r0q5uydx, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test4
-- 
-- Plan hash value: 2402724102
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.76 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.76 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.76 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  9fbrr83p1bn72, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test4_pk
-- 
-- Plan hash value: 3300041866
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.85 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.85 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.85 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  bbgac5gajhxvc, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test4_pk
-- 
-- Plan hash value: 3300041866
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.78 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.78 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.78 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  7d8u9xr3tzykz, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test4_pk
-- 
-- Plan hash value: 3300041866
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.72 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.72 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.72 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  1sym8uq7290z0, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test4_pk
-- 
-- Plan hash value: 3300041866
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.74 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.74 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.74 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST4_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  3ggkp8vk6nwu7, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test4_bi
-- 
-- Plan hash value: 1510060295
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  8pk0c4ydvjw0x, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test4_bi
-- 
-- Plan hash value: 1510060295
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  1khycmqr6d8t8, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test4_bi
-- 
-- Plan hash value: 1510060295
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  b39pfyxap7s7u, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test4_bi
-- 
-- Plan hash value: 1510060295
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_ONLY_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  9zv8rr2qqpn7y, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test4_pk_bi
-- 
-- Plan hash value: 1466733283
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  0qv5g3zujdau4, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test4_pk_bi
-- 
-- Plan hash value: 1466733283
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  fjf5zq4mjvq7h, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test4_pk_bi
-- 
-- Plan hash value: 1466733283
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  63k83umnpft2g, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test4_pk_bi
-- 
-- Plan hash value: 1466733283
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |     956 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |     956 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   1849 |00:00:00.02 |     956 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST4_BI |      1 |        |   1849 |00:00:00.01 |     956 |
-- ----------------------------------------------------------------------------------------------------
