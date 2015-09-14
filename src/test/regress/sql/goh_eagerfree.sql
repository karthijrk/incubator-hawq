\c hdfs

drop table if exists smallt;

create table smallt (i int, t text, d date);
insert into smallt select i%10, 'text ' || (i%15), '2011-01-01'::date + ((i%20) || ' days')::interval
from generate_series(0, 99) i;

drop table if exists bigt;

create table bigt (i int, t text, d date);
insert into bigt select i/10, 'text ' || (i/15), '2011-01-01'::date + ((i/20) || ' days')::interval
from generate_series(0, 999999) i;

drop table if exists smallt2;
create table smallt2 (i int, t text, d date);
insert into smallt2 select i%5, 'text ' || (i%10), '2011-01-01'::date + ((i%15) || ' days')::interval
from generate_series(0, 49) i;

-- HashAgg, Agg
select d, count(*) from smallt group by d;
explain analyze select d, count(*) from smallt group by d;

set statement_mem=2560;
select count(*) from (select i, t, d, count(*) from bigt group by i, t, d) tmp;
explain analyze select count(*) from (select i, t, d, count(*) from bigt group by i, t, d) tmp;
set statement_mem=128000;

-- DQA
set gp_enable_agg_distinct=off;
set gp_eager_one_phase_agg=on;
select count(distinct d) from smallt;
explain analyze select count(distinct d) from smallt;

set statement_mem=2560;
select count(distinct d) from bigt;
explain analyze select count(distinct d) from bigt;
set statement_mem=128000;

set gp_enable_agg_distinct=on;
set gp_eager_one_phase_agg=off;

-- Rescan on Agg (with Material in the inner side of nestloop)
set enable_nestloop=on;
set enable_hashjoin=off;
select t1.*, t2.* from
(select d, count(*) from smallt group by d) as t1, (select d, sum(i) from smallt group by d) as t2
where t1.d = t2.d;
explain analyze select t1.*, t2.* from
(select d, count(*) from smallt group by d) as t1, (select d, sum(i) from smallt group by d) as t2
where t1.d = t2.d;
set enable_nestloop=off;
set enable_hashjoin=on;

-- Rescan on Agg (with Material in the inner side of nestloop)
set enable_nestloop=on;
set enable_hashjoin=off;
select t1.*, t2.* from
(select i, count(*) from smallt group by i) as t1, (select i, sum(i) from smallt group by i) as t2
where t1.i = t2.i;
explain analyze select t1.*, t2.* from
(select i, count(*) from smallt group by i) as t1, (select i, sum(i) from smallt group by i) as t2
where t1.i = t2.i;
set enable_nestloop=off;
set enable_hashjoin=on;

-- Limit on Agg
select d, count(*) from smallt group by d limit 5; --ignore
explain analyze select d, count(*) from smallt group by d limit 5;

-- HashJoin
select t1.* from smallt as t1, smallt as t2 where t1.i = t2.i;
explain analyze select t1.* from smallt as t1, smallt as t2 where t1.i = t2.i;

-- Rescan on HashJoin
--select t1.* from (select t11.* from smallt as t11, smallt as t22 where t11.i = t22.i and t11.i < 2) as t1,
--   (select t11.* from smallt as t11, smallt as t22 where t11.d = t22.d and t11.i < 5) as t2;

-- Material in SubPlan
select smallt2.* from smallt2
where i < (select count(*) from smallt where smallt.i = smallt2.i);
explain select smallt2.* from smallt2
where i < (select count(*) from smallt where smallt.i = smallt2.i);

-- Append + Material in SubPlan
drop table if exists smallt_part;
drop table if exists smallt2_part;

create table smallt_part (i int, t text, d date)
partition by range (d) (start ('2011-01-01'::date) end ('2011-01-21'::date) every ('5 days'::interval));

create table smallt2_part (i int, t text, d date)
partition by range (d) (start ('2011-01-01'::date) end ('2011-01-16'::date) every ('4 days'::interval));

insert into smallt_part select i%10, 'text ' || (i%15), '2011-01-01'::date + ((i%20) || ' days')::interval
from generate_series(0, 99) i;

insert into smallt2_part select i%5, 'text ' || (i%10), '2011-01-01'::date + ((i%15) || ' days')::interval
from generate_series(0, 49) i;

select * from smallt_part where i < any (select count(*) from smallt2_part where smallt_part.i = smallt2_part.i group by d);
explain analyze select * from smallt_part where i < any (select count(*) from smallt2_part where smallt_part.i = smallt2_part.i group by d);

-- Sort in MergeJoin
set enable_hashjoin=off;
set enable_mergejoin=on;
select t1.* from smallt as t1, smallt as t2 where t1.i = t2.i and t1.i < 2;
explain analyze select t1.* from smallt as t1, smallt as t2 where t1.i = t2.i and t1.i < 2;

select t1.* from smallt as t1, smallt as t2 where t1.d = t2.d and t1.i < 2;
--start_ignore
explain analyze select t1.* from smallt as t1, smallt as t2 where t1.d = t2.d and t1.i < 2;
--end_ignore
set enable_hashjoin=on;
set enable_mergejoin=off;

-- ShareInputScan
--with my_group_max(i, maximum) as (select i, max(d) from smallt group by i)
--select smallt2.* from my_group_max, smallt2 where my_group_max.i = smallt2.i
--and smallt2.i < any (select maximum from my_group_max);
--explain analyze with my_group_max(i, maximum) as (select i, max(d) from smallt group by i)
--select smallt2.* from my_group_max, smallt2 where my_group_max.i = smallt2.i
--and smallt2.i < any (select maximum from my_group_max);

-- IndexScan
create index smallt_d_idx on smallt (d);
create index smallt2_d_idx on smallt2 (d);

set enable_hashjoin=off;
set enable_nestloop=on;
set enable_seqscan=off;
set enable_bitmapscan=off;
select smallt.* from smallt, smallt2 where smallt.i = smallt2.i and smallt2.d = '2011-01-04'::date
and smallt.d = '2011-01-04'::date;
explain analyze select smallt.* from smallt, smallt2 where smallt.i = smallt2.i and smallt2.d = '2011-01-04'::date
and smallt.d = '2011-01-04'::date;

-- BitmapScan
set enable_indexscan=off;
set enable_bitmapscan=on;
select smallt.* from smallt, smallt2 where smallt.i = smallt2.i and smallt2.d = '2011-01-04'::date
and smallt.d = '2011-01-04'::date;
explain analyze select smallt.* from smallt, smallt2 where smallt.i = smallt2.i and smallt2.d = '2011-01-04'::date
and smallt.d = '2011-01-04'::date;
set enable_hashjoin=on;
set enable_nestloop=off;
set enable_seqscan=on;
set enable_indexscan=on;

-- SubPlan
with my_group_sum(d, total) as (select d, sum(i) from smallt group by d)
select smallt2.* from smallt2
where i < all (select total from my_group_sum, smallt, smallt2 as tmp where my_group_sum.d = smallt.d and smallt.d = tmp.d and my_group_sum.d = smallt2.d)
and i = 0 order by 1,2,3; --order 1,2,3

select smallt2.* from smallt2
where i < all (select total from (select d, sum(i) as total from smallt group by d) as my_group_sum, smallt, smallt2 as tmp
    where my_group_sum.d = smallt.d and smallt.d = tmp.d and my_group_sum.d = smallt2.d)
and i = 0 order by 1,2,3; --order 1,2,3
