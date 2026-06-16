-- Tags: no-parallel-replicas, long

DROP TABLE IF EXISTS source;
DROP TABLE IF EXISTS target;
DROP VIEW IF EXISTS mv_1;
DROP VIEW IF EXISTS mv_2;
DROP VIEW IF EXISTS mv_3;

CREATE TABLE source (message String) ENGINE = MergeTree ORDER BY tuple();
CREATE TABLE target (message String, `from` String, `now` DateTime64(9), s UInt8)
    ENGINE = MergeTree ORDER BY tuple();

CREATE MATERIALIZED VIEW mv_1 TO target
    AS SELECT message, 'mv1' AS `from`, now64(9) AS `now`, sleep(1) AS s FROM source;
CREATE MATERIALIZED VIEW mv_2 TO target
    AS SELECT message, 'mv2' AS `from`, now64(9) AS `now`, sleep(1) AS s FROM source;
CREATE MATERIALIZED VIEW mv_3 TO target
    AS SELECT message, 'mv3' AS `from`, now64(9) AS `now`, sleep(1) AS s FROM source;

-- Test 1: parallel_view_processing=0 → sequential → timestamps ~1s apart
SET max_threads = 4;
SET parallel_view_processing = 0;
INSERT INTO source VALUES ('test');

SELECT countIf(diff > 0.9) = 2 AS is_sequential
FROM (
    SELECT toFloat64(neighbor(`now`, 1)) - toFloat64(`now`) AS diff
    FROM (SELECT `now` FROM target ORDER BY `now`)
    WHERE diff > 0
);

TRUNCATE TABLE target;

-- Test 2: parallel_view_processing=1 → parallel → timestamps all bunched
SET parallel_view_processing = 1;
INSERT INTO source VALUES ('test');

SELECT countIf(diff > 0.5) = 0 AS is_parallel
FROM (
    SELECT toFloat64(neighbor(`now`, 1)) - toFloat64(`now`) AS diff
    FROM (SELECT `now` FROM target ORDER BY `now`)
    WHERE diff > 0
);

DROP TABLE source;
DROP TABLE target;
DROP VIEW mv_1;
DROP VIEW mv_2;
DROP VIEW mv_3;
