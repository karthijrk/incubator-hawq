DROP TABLE IF EXISTS test_parquet_types_cidr;
CREATE TABLE test_parquet_types_cidr (c0 cidr) with (appendonly=true, orientation=parquet, compresstype=none, rowgroupsize=8388608, pagesize=1048576, compresslevel=0);
INSERT INTO test_parquet_types_cidr values ('2001:db8:85a3:8d3:1319:8a2e:370:7344/128'),
('192.168.1.255/32'),
('172.20.143.0/24'),
(null);