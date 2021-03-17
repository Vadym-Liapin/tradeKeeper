CREATE TABLE &&SCHEMA.t_big_sets (
    id				number,
	symbol_id		number	CONSTRAINT t_big_sets_symbol_id_nn	NOT NULL,
	entity_id		number	CONSTRAINT t_big_sets_entity_id_nn	NOT NULL,
	quantity_base	number,
	quantity_quote	number,
    CONSTRAINT t_big_sets_pk					PRIMARY KEY (id),
	CONSTRAINT t_big_sets_uniq					UNIQUE (symbol_id, entity_id),
	CONSTRAINT t_big_sets_symbol_id_fk			FOREIGN KEY (symbol_id) REFERENCES &&SCHEMA.t_symbols (id),
	CONSTRAINT t_big_sets_entity_id_fk			FOREIGN KEY (entity_id) REFERENCES &&SCHEMA.t_entities (id),
	CONSTRAINT t_big_sets_quantity_all_chk		CHECK((quantity_base IS NULL AND quantity_quote IS NOT NULL) OR (quantity_base IS NOT NULL AND quantity_quote IS NULL)),
	CONSTRAINT t_big_sets_quantity_base_chk		CHECK(quantity_base > 0),
	CONSTRAINT t_big_sets_quantity_quote_chk	CHECK(quantity_quote > 0)
);

COMMENT ON TABLE &&SCHEMA.t_big_sets IS 'Big Settings';

COMMENT ON COLUMN &&SCHEMA.t_big_sets.id   				IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_big_sets.symbol_id			IS 'Symbol ID';
COMMENT ON COLUMN &&SCHEMA.t_big_sets.entity_id			IS 'Entity ID';
COMMENT ON COLUMN &&SCHEMA.t_big_sets.quantity_base		IS 'Big Quantity in Base Symbol Currency';
COMMENT ON COLUMN &&SCHEMA.t_big_sets.quantity_quote	IS 'Big Quantity in Quote Symbol Currency';

TRUNCATE TABLE &&SCHEMA.t_big_sets;
INSERT INTO &&SCHEMA.t_big_sets (id, symbol_id, entity_id, quantity_base, quantity_quote)
SELECT	1 AS id,	1 AS symbol_id, 1 AS entity_id,	NULL AS quantity_base,	500000 AS quantity_quote	FROM dual UNION ALL -- BTC/USDT orders
SELECT	2 AS id,	1 AS symbol_id, 2 AS entity_id,	NULL AS quantity_base,	100000 AS quantity_quote	FROM dual UNION ALL -- BTC/USDT trades
SELECT	3 AS id,	2 AS symbol_id,	1 AS entity_id,	NULL AS quantity_base,	500000 AS quantity_quote	FROM dual UNION ALL	-- BTC/USD orders
SELECT	4 AS id,	2 AS symbol_id, 2 AS entity_id,	NULL AS quantity_base,	100000 AS quantity_quote	FROM dual  			-- BTC/USD trades
;

COMMIT;