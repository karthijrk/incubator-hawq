DROP TABLE IF EXISTS test_parquet_types_char10;
CREATE TABLE test_parquet_types_char10 (c0 char(10)) with (appendonly=true, orientation=parquet, compresstype=none, rowgroupsize=8388608, pagesize=1048576, compresslevel=0);
INSERT INTO test_parquet_types_char10 values ('123456789a'),
('bbccddeeff'),
('aaaa'),
(null);