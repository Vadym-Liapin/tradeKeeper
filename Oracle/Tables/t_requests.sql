CREATE TABLE &&SCHEMA.t_requests (
    id				number,
	entity_id		number			CONSTRAINT t_requests_entity_id_nn		NOT NULL,
	market_id		number			CONSTRAINT t_requests_market_id_nn		NOT NULL,
	symbol_id		number 			CONSTRAINT t_requests_symbol_id_nn		NOT NULL,
	endpoint		varchar2(200)	CONSTRAINT t_requests_endpoint_nn		NOT NULL,
	active			number(1)		CONSTRAINT t_requests_active_nn			NOT NULL,
	min_quantity	number			CONSTRAINT t_requests_min_quantity_nn	NOT NULL,
    CONSTRAINT t_requests_pk				PRIMARY KEY (id),
	CONSTRAINT t_requests_uniq				UNIQUE (entity_id, market_id, symbol_id),
	CONSTRAINT t_requests_entity_id_fk		FOREIGN KEY (entity_id) REFERENCES &&SCHEMA.t_entities (id),
	CONSTRAINT t_requests_market_id_fk		FOREIGN KEY (market_id) REFERENCES &&SCHEMA.t_markets (id),
	CONSTRAINT t_requests_symbol_id_fk		FOREIGN KEY (symbol_id) REFERENCES &&SCHEMA.t_symbols (id),
	CONSTRAINT t_requests_active			CHECK (active IN (0, 1)),
	CONSTRAINT t_requests_min_quantity_chk	CHECK (min_quantity >= 0)
);

COMMENT ON TABLE &&SCHEMA.t_requests IS 'API Requests';

COMMENT ON COLUMN &&SCHEMA.t_requests.id   			IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_requests.entity_id		IS 'Entity ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.market_id		IS 'Market ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.symbol_id		IS 'Symbol ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.endpoint		IS 'Endpoint';
COMMENT ON COLUMN &&SCHEMA.t_requests.active		IS 'Active Flag: 0/1';
COMMENT ON COLUMN &&SCHEMA.t_requests.min_quantity	IS 'MIN Quantity';

TRUNCATE TABLE &&SCHEMA.t_requests;

INSERT INTO &&SCHEMA.t_requests (id, entity_id, market_id, symbol_id, endpoint, active, min_quantity)
-- orders binance BTC/USDT
SELECT	1 AS id,	1 AS entity_id,	1 AS market_id,	1 AS symbol_id,	'https://api.binance.com/api/v3/depth?symbol=BTCUSDT&' || 'limit=5000' 			AS endpoint, 1 AS active, 10 AS min_quantity	FROM dual 	UNION ALL
-- orders bitstamp BTC/USD
SELECT	2 AS id,	1 AS entity_id,	2 AS market_id,	2 AS symbol_id,	'https://www.bitstamp.net/api/v2/order_book/btcusd' 							AS endpoint, 1 AS active, 10 AS min_quantity	FROM dual	UNION ALL
-- orders bitfinex BTC/USD
SELECT	3 AS id,	1 AS entity_id,	3 AS market_id,	2 AS symbol_id,	'https://api.bitfinex.com/v1/book/BTCUSD?limit_asks=2500&' || 'limit_bids=2500'	AS endpoint, 1 AS active, 10 AS min_quantity	FROM dual	UNION ALL
-- trades bitstamp BTC/USD
SELECT	4 AS id,	2 AS entity_id,	2 AS market_id,	2 AS symbol_id,	'https://www.bitstamp.net/api/v2/transactions/btcusd/?time=hour'				AS endpoint, 1 AS active, 1 AS min_quantity		FROM dual	UNION ALL
-- trades bitfinex BTC/USD
SELECT	5 AS id,	2 AS entity_id,	3 AS market_id,	2 AS symbol_id,	'https://api-pub.bitfinex.com/v2/trades/tBTCUSD/hist?limit=10000&' || 
																	'start=%ds_unix_ms%&' || 'end=%df_unix_ms%&' || 'sort=1'						AS endpoint, 1 AS active, 1 AS min_quantity		FROM dual	UNION ALL
-- trades binance BTC/USD
SELECT	6 AS id,	2 AS entity_id,	1 AS market_id,	2 AS symbol_id,	'https://api.binance.com/api/v3/aggTrades?symbol=BTCUSDT&' || 
																	'startTime=%ds_unix_ms%&' || 'endTime=%df_unix_ms%&' || 'limit=1000'			AS endpoint, 1 AS active, 1 AS min_quantity		FROM dual
;

COMMIT;