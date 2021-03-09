CREATE TABLE &&SCHEMA.t_symbols (
    id					number,
	currency_id_base	number	CONSTRAINT t_currency_id_base_nn	NOT NULL,
	currency_id_quote	number	CONSTRAINT t_currency_id_quote_nn	NOT NULL,
    CONSTRAINT t_symbols_pk					PRIMARY KEY (id),
	CONSTRAINT t_symbols_uniq				UNIQUE (currency_id_base, currency_id_quote),
	CONSTRAINT t_symbols_ccy_id_base_fk		FOREIGN KEY (currency_id_base) REFERENCES &&SCHEMA.t_currencies (id),
	CONSTRAINT t_symbols_ccy_id_quote_fk	FOREIGN KEY (currency_id_quote) REFERENCES &&SCHEMA.t_currencies (id)
);

COMMENT ON TABLE &&SCHEMA.t_symbols IS 'Symbols';

COMMENT ON COLUMN &&SCHEMA.t_symbols.id   				IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_symbols.currency_id_base	IS 'Base Currency ID';
COMMENT ON COLUMN &&SCHEMA.t_symbols.currency_id_quote	IS 'Quote Currency ID';

TRUNCATE TABLE &&SCHEMA.t_symbols;
INSERT INTO &&SCHEMA.t_symbols (id, currency_id_base, currency_id_quote)
SELECT	1 AS id,	3 	AS currency_id_base, 	6	AS currency_id_quote	FROM dual UNION ALL -- BTC/USDT
SELECT	2 AS id,	3 	AS currency_id_base, 	1	AS currency_id_quote	FROM dual 			-- BTC/USD
;

COMMIT;