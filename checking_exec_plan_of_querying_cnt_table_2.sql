REM
REM     Script:        checking_exec_plan_of_querying_cnt_table_2.sql
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
REM               'TEST2', 'TEST2_PK', 'TEST2_BI' and 'TEST2_PK_BI';
REM           (3) checking real execution plan and meanwhile generating 10053 trc file by querying
REM               COUNT(*|1|id|flag) on the previous 4 different tables;
REM        By the way those tables are going to be dynamically created by using several
REM        oracle PL/SQL procedures. I just use 'CTAS' (a very simple approach creating table)
REM        to create my TEST tables with two physical properties (SEGMENT CREATION IMMEDIATE and
REM        NOLOGGING) and a table property (PARALLEL).
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
PROMPT *  (1) test2: no primary key and bitmap index;                     *
PROMPT *  (2) test2_pk: only primary key  => test2_only_pk;               *
PROMPT *  (3) test2_bi: only bitmap index => test2_only_bi;               *
PROMPT *  (4) test2_pk_bi: primary key    => test2_pk,                    *
PROMPT *                   bitmap index   => test2_bi;                    *
PROMPT ********************************************************************

CONN qwz/qwz

SET TIMING ON

CREATE OR REPLACE PROCEDURE crt_tab_test2
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test2 PURGE';
   v_sql_2 := q'[CREATE TABLE test2 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 PARALLEL 10 
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
           TABNAME            => 'TEST2'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST2'
      );
END crt_tab_test2;
/

CREATE OR REPLACE PROCEDURE crt_tab_test2_pk
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test2_pk PURGE';
   v_sql_2 := q'[CREATE TABLE test2_pk 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 PARALLEL 10 
                 AS SELECT ROWNUM id 
                           , CASE WHEN ROWNUM BETWEEN  1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[              WHEN ROWNUM BETWEEN  2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[              WHEN ROWNUM BETWEEN  4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[              ELSE 'unknown' 
                             END flag 
                    FROM XMLTABLE('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE 'ALTER TABLE test2_pk ADD CONSTRAINT test2_only_pk PRIMARY KEY (id)';
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST2_PK'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE 'ALTER TABLE test2_pk ADD CONSTRAINT test2_only_pk PRIMARY KEY (id)';
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST2_PK'
      );
END crt_tab_test2_pk;
/

CREATE OR REPLACE PROCEDURE crt_tab_test2_bi
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test2_bi PURGE';
   v_sql_2 := q'[CREATE TABLE test2_bi 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 PARALLEL 10 
                 AS SELECT ROWNUM id 
                           , CASE WHEN ROWNUM BETWEEN  1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[              WHEN ROWNUM BETWEEN  2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[              WHEN ROWNUM BETWEEN  4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[              ELSE 'unknown' 
                             END flag 
                    FROM XMLTABLE('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE 'CREATE BITMAP INDEX test2_only_bi ON test2_bi (flag)';
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST2_BI'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE 'CREATE BITMAP INDEX test2_only_bi ON test2_bi (flag)';
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST2_BI'
      );
END crt_tab_test2_bi;
/

CREATE OR REPLACE PROCEDURE crt_tab_test2_pk_bi
AS
   v_num   NUMBER;
   v_sql_1 VARCHAR2(2000);
   v_sql_2 VARCHAR2(2000);
BEGIN
   v_num := 5e7;
   v_sql_1 := 'DROP TABLE test2_pk_bi PURGE';
   v_sql_2 := q'[CREATE TABLE test2_pk_bi 
                 SEGMENT CREATION IMMEDIATE 
                 NOLOGGING 
                 PARALLEL 10 
                 AS SELECT ROWNUM id 
                           , CASE WHEN ROWNUM BETWEEN  1                      AND 1/5*]' || v_num || q'[ THEN 'low' ]'
              || q'[              WHEN ROWNUM BETWEEN  2/5*]' || v_num || q'[ AND 3/5*]' || v_num || q'[ THEN 'mid' ]'
              || q'[              WHEN ROWNUM BETWEEN  4/5*]' || v_num || q'[ AND     ]' || v_num || q'[ THEN 'high' ]'
              || q'[              ELSE 'unknown' 
                             END flag 
                    FROM XMLTABLE('1 to ]' || v_num || q'[')]';
   EXECUTE IMMEDIATE v_sql_1;
   EXECUTE IMMEDIATE v_sql_2;
   EXECUTE IMMEDIATE 'ALTER TABLE test2_pk_bi ADD CONSTRAINT test2_pk PRIMARY KEY (id)';
   EXECUTE IMMEDIATE 'CREATE BITMAP INDEX test2_bi ON test2_pk_bi (flag)';
   DBMS_STATS.gather_table_stats(
           OWNNAME            => user,
           TABNAME            => 'TEST2_PK_BI'
   );
EXCEPTION
   WHEN OTHERS THEN
      EXECUTE IMMEDIATE v_sql_2;
      EXECUTE IMMEDIATE 'ALTER TABLE test2_pk_bi ADD CONSTRAINT test2_pk PRIMARY KEY (id)';
      EXECUTE IMMEDIATE 'CREATE BITMAP INDEX test2_bi ON test2_pk_bi (flag)';
      DBMS_STATS.gather_table_stats(
              OWNNAME            => user,
              TABNAME            => 'TEST2_PK_BI'
      );
END crt_tab_test2_pk_bi;
/

EXECUTE crt_tab_test2;
EXECUTE crt_tab_test2_pk;
EXECUTE crt_tab_test2_bi;
EXECUTE crt_tab_test2_pk_bi;

PROMPT ************************************************************************************
PROMPT * Checking real execution plan and meanwhile generating 10053 trc file by querying *
PROMPT * COUNT(*|1|id|flag) on 4 different tables 'TEST2', 'TEST2_PK', 'TEST2_BI', and    *
PROMPT * 'TEST2_PK_BI' on the same session (SQL*Plus window).                             *
PROMPT ************************************************************************************

SET LINESIZE 150
SET PAGESIZE 150
SET SERVEROUTPUT OFF

-- At the session level, enabling to check the real execution plan
ALTER SESSION SET statistics_level = all;

-- At the session level, enabling to open 10053 event
ALTER SESSION SET max_dump_file_size = 'UNLIMITED';
ALTER SESSION SET tracefile_identifier = '10053_test2';
ALTER SESSION SET EVENTS '10053 trace name context forever, level 1';

-- Querying count(*|1|id|flag) from table 'TEST' and next to checking their row source execution plan
SELECT COUNT(*) FROM test2;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test2;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test2;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test2;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_PK' and next to checking their row source execution plan
SELECT COUNT(*) FROM test2_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test2_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test2_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test2_pk;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_BI' and next to checking their row source execution plan
SELECT COUNT(*) FROM test2_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test2_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test2_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test2_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- Querying count(*|1|id|flag) from table 'TEST_PK_BI' and next to checking their row source execution plan
SELECT COUNT(*) FROM test2_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(1) FROM test2_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(id) FROM test2_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));
SELECT COUNT(flag) FROM test2_pk_bi;
SELECT * FROM table(DBMS_XPLAN.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- At the session level, enabling to close 10053 event
ALTER SESSION SET EVENTS '10053 trace name context off';
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';

PROMPT ===============================
PROMPT the real execution plan of 18.3
PROMPT ===============================

-- SQL_ID  13up2mtv0xk4u, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test2
-- 
-- Plan hash value: 2571823673
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.29 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.29 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.29 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2    |      0 |     50M|      0 |00:00:00.01 |       0 |
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
-- SQL_ID  23fx6mu3w1p7n, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test2
-- 
-- Plan hash value: 2571823673
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.26 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.26 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.26 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2    |      0 |     50M|      0 |00:00:00.01 |       0 |
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
-- SELECT COUNT(id) FROM test2
-- 
-- Plan hash value: 2571823673
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.41 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.41 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.41 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2    |      0 |     50M|      0 |00:00:00.01 |       0 |
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
-- SQL_ID  6wqwhgdcqc1pr, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test2
-- 
-- Plan hash value: 2571823673
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.38 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.38 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.38 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2    |      0 |     50M|      0 |00:00:00.01 |       0 |
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
-- SQL_ID  batpzhxg6bf3b, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test2_pk
-- 
-- Plan hash value: 4037883998
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.30 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.30 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.30 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
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
-- SQL_ID  7pwsbf4vra7bn, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test2_pk
-- 
-- Plan hash value: 4037883998
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.29 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.29 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.29 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
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
-- SQL_ID  2h23yk1cbaaay, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test2_pk
-- 
-- Plan hash value: 4037883998
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
-- |*  6 |       TABLE ACCESS FULL| TEST2_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
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
-- SQL_ID  dy620tvvb6v5d, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test2_pk
-- 
-- Plan hash value: 4037883998
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.42 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.42 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.42 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
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
-- SQL_ID  6mwy20jnc0zfn, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test2_bi
-- 
-- Plan hash value: 738733133
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.05 |    1046 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.05 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   2065 |00:00:00.05 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_ONLY_BI |      1 |        |   2065 |00:00:00.03 |    1046 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  2wd4b19fkvgg9, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test2_bi
-- 
-- Plan hash value: 738733133
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.03 |    1046 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.03 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   2065 |00:00:00.03 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_ONLY_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  df4y75ywv542p, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test2_bi
-- 
-- Plan hash value: 3635498818
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:00.43 |       5 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:00.43 |       5 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:00.43 |       5 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2_BI |      0 |     50M|      0 |00:00:00.01 |       0 |
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
-- SQL_ID  fz85hq2kcgqd1, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test2_bi
-- 
-- Plan hash value: 3885697993
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:05.75 |    1046 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:05.75 |    1046 |
-- |   2 |   BITMAP CONVERSION TO ROWIDS |               |      1 |     50M|     50M|00:00:03.16 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_ONLY_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  8rkbpypsgs4g6, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test2_pk_bi
-- 
-- Plan hash value: 1790107405
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.05 |    1046 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.05 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   2065 |00:00:00.05 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_BI |      1 |        |   2065 |00:00:00.03 |    1046 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  2s24tugphg2gk, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test2_pk_bi
-- 
-- Plan hash value: 1790107405
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.03 |    1046 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.03 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   2065 |00:00:00.03 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  1a4c2wjg9r80v, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test2_pk_bi
-- 
-- Plan hash value: 1790107405
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.03 |    1046 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.03 |    1046 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   2065 |00:00:00.03 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  gfujq4km7sb4z, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test2_pk_bi
-- 
-- Plan hash value: 3275165930
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:05.55 |    1046 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:05.55 |    1046 |
-- |   2 |   BITMAP CONVERSION TO ROWIDS |          |      1 |     50M|     50M|00:00:03.06 |    1046 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_BI |      1 |        |   2065 |00:00:00.01 |    1046 |
-- ----------------------------------------------------------------------------------------------------

PROMPT ===============================
PROMPT the real execution plan of 11.2
PROMPT ===============================

-- SQL_ID  13up2mtv0xk4u, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test2
-- 
-- Plan hash value: 2571823673
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:02.45 |       9 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:02.45 |       9 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:02.45 |       9 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  23fx6mu3w1p7n, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test2
-- 
-- Plan hash value: 2571823673
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.89 |       9 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.89 |       9 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.89 |       9 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  3hsfmajxxy7s8, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test2
-- 
-- Plan hash value: 2571823673
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.86 |       9 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.86 |       9 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.86 |       9 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  6wqwhgdcqc1pr, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test2
-- 
-- Plan hash value: 2571823673
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.85 |       9 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.85 |       9 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.85 |       9 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2    |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  batpzhxg6bf3b, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test2_pk
-- 
-- Plan hash value: 4037883998
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.83 |       9 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.83 |       9 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.83 |       9 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  7pwsbf4vra7bn, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test2_pk
-- 
-- Plan hash value: 4037883998
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.77 |       9 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.77 |       9 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.77 |       9 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  2h23yk1cbaaay, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test2_pk
-- 
-- Plan hash value: 4037883998
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.77 |       9 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.77 |       9 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.77 |       9 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  dy620tvvb6v5d, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test2_pk
-- 
-- Plan hash value: 4037883998
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.82 |       9 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.82 |       9 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.82 |       9 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2_PK |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)               
-- 
-- SQL_ID  6mwy20jnc0zfn, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test2_bi
-- 
-- Plan hash value: 738733133
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_ONLY_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  2wd4b19fkvgg9, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test2_bi
-- 
-- Plan hash value: 738733133
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |               |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_ONLY_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  df4y75ywv542p, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test2_bi
-- 
-- Plan hash value: 3635498818
-- 
-- ---------------------------------------------------------------------------------------------
-- | Id  | Operation              | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT       |          |      1 |        |      1 |00:00:01.86 |       9 |
-- |   1 |  SORT AGGREGATE        |          |      1 |      1 |      1 |00:00:01.86 |       9 |
-- |   2 |   PX COORDINATOR       |          |      1 |        |     10 |00:00:01.86 |       9 |
-- |   3 |    PX SEND QC (RANDOM) | :TQ10000 |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   4 |     SORT AGGREGATE     |          |      0 |      1 |      0 |00:00:00.01 |       0 |
-- |   5 |      PX BLOCK ITERATOR |          |      0 |     50M|      0 |00:00:00.01 |       0 |
-- |*  6 |       TABLE ACCESS FULL| TEST2_BI |      0 |     50M|      0 |00:00:00.01 |       0 |
-- ---------------------------------------------------------------------------------------------
-- 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
-- 
--    6 - access(:Z>=:Z AND :Z<=:Z)
-- 
-- SQL_ID  fz85hq2kcgqd1, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test2_bi
-- 
-- Plan hash value: 3885697993
-- 
-- ---------------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ---------------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |               |      1 |        |      1 |00:00:08.61 |    1045 |
-- |   1 |  SORT AGGREGATE               |               |      1 |      1 |      1 |00:00:08.61 |    1045 |
-- |   2 |   BITMAP CONVERSION TO ROWIDS |               |      1 |     50M|     50M|00:00:04.75 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_ONLY_BI |      1 |        |   2065 |00:00:00.02 |    1045 |
-- ---------------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  8rkbpypsgs4g6, child number 0
-- -------------------------------------
-- SELECT COUNT(*) FROM test2_pk_bi
-- 
-- Plan hash value: 1790107405
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  2s24tugphg2gk, child number 0
-- -------------------------------------
-- SELECT COUNT(1) FROM test2_pk_bi
-- 
-- Plan hash value: 1790107405
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  1a4c2wjg9r80v, child number 0
-- -------------------------------------
-- SELECT COUNT(id) FROM test2_pk_bi
-- 
-- Plan hash value: 1790107405
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:00.02 |    1045 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:00.02 |    1045 |
-- |   2 |   BITMAP CONVERSION COUNT     |          |      1 |     50M|   2065 |00:00:00.02 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_BI |      1 |        |   2065 |00:00:00.01 |    1045 |
-- ----------------------------------------------------------------------------------------------------
-- 
-- SQL_ID  gfujq4km7sb4z, child number 0
-- -------------------------------------
-- SELECT COUNT(flag) FROM test2_pk_bi
-- 
-- Plan hash value: 3275165930
-- 
-- ----------------------------------------------------------------------------------------------------
-- | Id  | Operation                     | Name     | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-- ----------------------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT              |          |      1 |        |      1 |00:00:08.58 |    1045 |
-- |   1 |  SORT AGGREGATE               |          |      1 |      1 |      1 |00:00:08.58 |    1045 |
-- |   2 |   BITMAP CONVERSION TO ROWIDS |          |      1 |     50M|     50M|00:00:04.72 |    1045 |
-- |   3 |    BITMAP INDEX FAST FULL SCAN| TEST2_BI |      1 |        |   2065 |00:00:00.02 |    1045 |
-- ----------------------------------------------------------------------------------------------------
