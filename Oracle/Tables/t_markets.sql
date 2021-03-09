CREATE TABLE &&SCHEMA.t_markets (
    id		number,
	code	varchar2(50)	CONSTRAINT t_markets_code_nn	NOT NULL,
    CONSTRAINT t_markets_pk		PRIMARY KEY (id),
	CONSTRAINT t_markets_uniq	UNIQUE (code)
);

COMMENT ON TABLE &&SCHEMA.t_markets IS 'Markets';

COMMENT ON COLUMN &&SCHEMA.t_markets.id     IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_markets.code	IS 'Market Code';

TRUNCATE TABLE &&SCHEMA.t_markets;
INSERT INTO &&SCHEMA.t_markets (id, code)
SELECT	1 AS id,	'binance' AS code	FROM dual	UNION ALL
SELECT	2 AS id,	'bitstamp' AS code	FROM dual	UNION ALL
SELECT	3 AS id,	'bitfinex' AS code	FROM dual
;

COMMIT;