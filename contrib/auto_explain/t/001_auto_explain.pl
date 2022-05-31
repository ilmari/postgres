
# Copyright (c) 2021-2022, PostgreSQL Global Development Group

use strict;
use warnings;

use PostgreSQL::Test::Cluster;
use PostgreSQL::Test::Utils;
use Test::More;

my $node = PostgreSQL::Test::Cluster->new('main');
$node->init;
$node->append_conf('postgresql.conf',
	"shared_preload_libraries = 'auto_explain'");
$node->append_conf('postgresql.conf', "auto_explain.log_min_duration = 0");
$node->append_conf('postgresql.conf', "auto_explain.log_parameter_max_length = -1");
$node->append_conf('postgresql.conf', "auto_explain.log_analyze = on");
$node->start;

# run a couple of queries
$node->safe_psql("postgres", "SELECT * FROM pg_class;");
$node->safe_psql("postgres",
	q{PREPARE get_proc(name) AS SELECT * FROM pg_proc WHERE proname = $1; EXECUTE get_proc('int4pl');});

# emit some json too
$node->append_conf('postgresql.conf', "auto_explain.log_format = json");
$node->reload;
$node->safe_psql("postgres", "SELECT * FROM pg_proc;");
$node->safe_psql("postgres",
	q{PREPARE get_class(name) AS SELECT * FROM pg_class WHERE relname = $1; EXECUTE get_class('pg_class');});

$node->stop('fast');

my $log = $node->logfile();

my $log_contents = slurp_file($log);

like(
	$log_contents,
	qr/Query Text: SELECT \* FROM pg_class;/,
	"query text logged, text mode");

like(
	$log_contents,
	qr/Query Parameters: \$1 = 'int4pl'/,
	"query parameters logged, text mode");

like(
	$log_contents,
	qr/Seq Scan on pg_class/,
	"sequential scan logged, text mode");

like(
	$log_contents,
	qr/Index Scan using pg_proc_proname_args_nsp_index on pg_proc/,
	"index scan logged, text mode");

like(
	$log_contents,
	qr/"Query Text": "SELECT \* FROM pg_proc;"/,
	"query text logged, json mode");

like(
	$log_contents,
	qr/"Query Parameters": "\$1 = 'pg_class'"/,
	"query parameters logged, json mode");

like(
	$log_contents,
	qr/"Node Type": "Seq Scan"[^}]*"Relation Name": "pg_proc"/s,
	"sequential scan logged, json mode");

like(
	$log_contents,
	qr/"Node Type": "Index Scan"[^}]*"Index Name": "pg_class_relname_nsp_index"/s,
	"index scan logged, json mode");

done_testing();
