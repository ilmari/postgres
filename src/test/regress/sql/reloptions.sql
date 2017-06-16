
-- Simple create
CREATE TABLE reloptions_test(i INT) WITH (fillfactor=30,autovacuum_enabled = false, autovacuum_analyze_scale_factor = 0.2);

SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test'::regclass;

-- Test сase insensitive
CREATE TABLE reloptions_test3(i INT) WITH (FiLlFaCtoR=40);

SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test3'::regclass;

-- Fail on min/max values check
CREATE TABLE reloptions_test2(i INT) WITH (fillfactor=2);

CREATE TABLE reloptions_test2(i INT) WITH (fillfactor=110);

CREATE TABLE reloptions_test2(i INT) WITH (autovacuum_analyze_scale_factor = -10.0);

CREATE TABLE reloptions_test2(i INT) WITH (autovacuum_analyze_scale_factor = 110.0);

-- Fail when option and namespase do not exist

CREATE TABLE reloptions_test2(i INT) WITH (not_existing_option=2);

CREATE TABLE reloptions_test2(i INT) WITH (not_existing_namespace.fillfactor=2);

-- Fail while setting unproper value

CREATE TABLE reloptions_test2(i INT) WITH (fillfactor=30.5);

CREATE TABLE reloptions_test2(i INT) WITH (fillfactor='string');

CREATE TABLE reloptions_test2(i INT) WITH (fillfactor=true);

CREATE TABLE reloptions_test2(i INT) WITH (autovacuum_enabled=12);

CREATE TABLE reloptions_test2(i INT) WITH (autovacuum_enabled=30.5);

CREATE TABLE reloptions_test2(i INT) WITH (autovacuum_enabled='string');

CREATE TABLE reloptions_test2(i INT) WITH (autovacuum_analyze_scale_factor='string');

CREATE TABLE reloptions_test2(i INT) WITH (autovacuum_analyze_scale_factor=true);

-- Specifing name only should fail as if there was =ture after it
CREATE TABLE reloptions_test2(i INT) WITH (fillfactor); 

-- Simple ALTER TABLE

ALTER TABLE reloptions_test SET (fillfactor=31, autovacuum_analyze_scale_factor = 0.3);

SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test'::regclass;

-- Check that we cat set boolean option to true just by mentioning it

ALTER TABLE reloptions_test SET (autovacuum_enabled, fillfactor=32);

SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test'::regclass;

-- Check that RESET works well

ALTER TABLE reloptions_test RESET (fillfactor);

SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test'::regclass;

-- Check that RESETting all values make NULL reloptions record in pg_class
ALTER TABLE reloptions_test RESET (autovacuum_enabled, autovacuum_analyze_scale_factor);
SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test'::regclass AND reloptions IS NULL;

-- Check RESET fails on att=value

ALTER TABLE reloptions_test RESET (fillfactor=12);

-- Check oids options is ignored
DROP TABLE reloptions_test;
CREATE TABLE reloptions_test(i INT) WITH (fillfactor=20, oids=true);
SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test'::regclass;

-- Now testing toast.* options
DROP TABLE reloptions_test;

CREATE TABLE reloptions_test (s VARCHAR) WITH (toast.autovacuum_vacuum_cost_delay = 23 );

SELECT reloptions FROM pg_class WHERE oid = (SELECT reltoastrelid FROM pg_class WHERE oid = 'reloptions_test'::regclass);

ALTER TABLE reloptions_test SET (toast.autovacuum_vacuum_cost_delay = 24);

SELECT reloptions FROM pg_class WHERE oid = (SELECT reltoastrelid FROM pg_class WHERE oid = 'reloptions_test'::regclass);

ALTER TABLE reloptions_test RESET (toast.autovacuum_vacuum_cost_delay);

SELECT reloptions FROM pg_class WHERE oid = (SELECT reltoastrelid FROM pg_class WHERE oid = 'reloptions_test'::regclass);

-- Fail on unexisting options in toast namespace
CREATE TABLE reloptions_test2 (i int) WITH (toast.not_existing_option = 42 );

-- Fail on setting reloption to a table that does not have a TOAST relation
CREATE TABLE reloptions_test2 (i int) WITH (toast.autovacuum_vacuum_cost_delay = 23 );
DROP TABLE reloptions_test;

CREATE TABLE reloptions_test(i INT);
ALTER TABLE reloptions_test SET (toast.autovacuum_vacuum_cost_delay = 23);
ALTER TABLE reloptions_test RESET (toast.autovacuum_vacuum_cost_delay);

-- autovacuum_analyze_scale_factor and autovacuum_analyze_threshold should be
-- accepted by heap but rejected by toast (special case)
DROP TABLE reloptions_test;
CREATE TABLE reloptions_test (s VARCHAR) WITH (autovacuum_analyze_scale_factor=1, autovacuum_analyze_threshold=1);

CREATE TABLE reloptions_test2 (s VARCHAR) WITH (toast.autovacuum_analyze_scale_factor=1);
CREATE TABLE reloptions_test2 (s VARCHAR) WITH (toast.autovacuum_analyze_threshold=1);

-- And now mixed toast + heap
DROP TABLE reloptions_test;

CREATE TABLE reloptions_test (s VARCHAR) WITH (toast.autovacuum_vacuum_cost_delay = 23, autovacuum_vacuum_cost_delay = 24, fillfactor = 40);

SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test'::regclass;
SELECT reloptions FROM pg_class WHERE oid = (SELECT reltoastrelid FROM pg_class WHERE oid = 'reloptions_test'::regclass);

-- Same FOR CREATE and ALTER INDEX for btree indexes

CREATE INDEX reloptions_test_idx ON reloptions_test (s) WITH (fillfactor=30);

SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test_idx'::regclass;

-- Fail when option and namespase do not exist

CREATE INDEX reloptions_test_idx ON reloptions_test (s) WITH (not_existing_option=2);

CREATE INDEX reloptions_test_idx ON reloptions_test (s) WITH (not_existing_option.fillfactor=2);

-- Check ranges

CREATE INDEX reloptions_test_idx2 ON reloptions_test (s) WITH (fillfactor=1);

CREATE INDEX reloptions_test_idx2 ON reloptions_test (s) WITH (fillfactor=130);

-- Check alter

ALTER INDEX reloptions_test_idx SET (fillfactor=40);

SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test_idx'::regclass;

-- Check alter on empty relop list

CREATE INDEX reloptions_test_idx3 ON reloptions_test (s);

ALTER INDEX reloptions_test_idx3 SET (fillfactor=40);

SELECT reloptions FROM pg_class WHERE oid = 'reloptions_test_idx3'::regclass;


