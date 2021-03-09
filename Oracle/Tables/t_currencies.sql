CREATE TABLE &&SCHEMA.t_currencies (
    id		number,
	code	varchar2(15)	CONSTRAINT t_currencies_code_nn	NOT NULL,
	name	varchar2(50)	CONSTRAINT t_currencies_name_nn	NOT NULL,
    CONSTRAINT t_currencies_pk		PRIMARY KEY (id),
	CONSTRAINT t_currencies_uniq	UNIQUE (code)
);

COMMENT ON TABLE &&SCHEMA.t_currencies IS 'Currencies';

COMMENT ON COLUMN &&SCHEMA.t_currencies.id   	IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_currencies.code	IS 'Currency ISO Code';
COMMENT ON COLUMN &&SCHEMA.t_currencies.name	IS 'Currency Name';

TRUNCATE TABLE &&SCHEMA.t_currencies;
INSERT INTO &&SCHEMA.t_currencies (id, code, name)
SELECT	1 AS id,	'USD' 	AS code, 	'US Dollar' AS name	FROM dual	UNION ALL
SELECT	2 AS id,	'EUR' 	AS code,	'Euro' 		AS name	FROM dual	UNION ALL
SELECT	3 AS id,	'BTC' 	AS code,	'Bitcoin'	AS name	FROM dual	UNION ALL
SELECT	4 AS id,	'ETH' 	AS code,	'Ethereum'	AS name	FROM dual	UNION ALL
SELECT	5 AS id,	'XRP' 	AS code,	'Ripple'	AS name	FROM dual	UNION ALL
SELECT	6 AS id,	'USDT' 	AS code,	'Tether'	AS name	FROM dual
;

COMMIT;