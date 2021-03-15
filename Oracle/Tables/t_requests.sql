CREATE TABLE &&SCHEMA.t_requests (
    id				number,
	parent_id		number,
	entity_id		number			CONSTRAINT t_requests_entity_id_nn		NOT NULL,
	market_id		number			CONSTRAINT t_requests_market_id_nn		NOT NULL,
	symbol_id		number 			CONSTRAINT t_requests_symbol_id_nn		NOT NULL,
	endpoint		varchar2(100)	CONSTRAINT t_requests_endpoint_nn		NOT NULL,
	params			varchar2(100),
	active			number(1)		CONSTRAINT t_requests_active_nn			NOT NULL,
	min_quantity	number			CONSTRAINT t_requests_min_quantity_nn	NOT NULL,
    CONSTRAINT t_requests_pk				PRIMARY KEY (id),
	CONSTRAINT t_requests_uniq				UNIQUE (entity_id, market_id, symbol_id, parent_id),
	CONSTRAINT t_requests_parent_id_fk		FOREIGN KEY (parent_id) REFERENCES &&SCHEMA.t_requests (id),
	CONSTRAINT t_requests_entity_id_fk		FOREIGN KEY (entity_id) REFERENCES &&SCHEMA.t_entities (id),
	CONSTRAINT t_requests_market_id_fk		FOREIGN KEY (market_id) REFERENCES &&SCHEMA.t_markets (id),
	CONSTRAINT t_requests_symbol_id_fk		FOREIGN KEY (symbol_id) REFERENCES &&SCHEMA.t_symbols (id),
	CONSTRAINT t_requests_active			CHECK (active IN (0, 1)),
	CONSTRAINT t_requests_min_quantity_chk	CHECK (min_quantity >= 0)
);

COMMENT ON TABLE &&SCHEMA.t_requests IS 'API Requests';

COMMENT ON COLUMN &&SCHEMA.t_requests.id   			IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_requests.parent_id		IS 'Parent ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.entity_id		IS 'Entity ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.market_id		IS 'Market ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.symbol_id		IS 'Symbol ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.endpoint		IS 'Endpoint';
COMMENT ON COLUMN &&SCHEMA.t_requests.params		IS 'Parameters';
COMMENT ON COLUMN &&SCHEMA.t_requests.active		IS 'Active Flag: 0/1';
COMMENT ON COLUMN &&SCHEMA.t_requests.min_quantity	IS 'MIN Quantity';

TRUNCATE TABLE &&SCHEMA.t_requests;

INSERT INTO &&SCHEMA.t_requests (id, parent_id, entity_id, market_id, symbol_id, endpoint, params, active, min_quantity)
-- orders binance BTC/USDT
SELECT	1 AS id,
		NULL AS parent_id,
		1 AS entity_id,	
		1 AS market_id,	
		1 AS symbol_id,	
		'https://api.binance.com/api/v3/depth' AS endpoint, 
		'?symbol=BTCUSDT&' || 'limit=5000' AS params, 
		1 AS active, 
		10 AS min_quantity	
FROM 	dual 	
	UNION ALL
-- orders bitstamp BTC/USD
SELECT	2 AS id,
		NULL AS parent_id,
		1 AS entity_id,	
		2 AS market_id,	
		2 AS symbol_id,	
		'https://www.bitstamp.net/api/v2/order_book/btcusd'	AS endpoint, 
		NULL AS params,
		1 AS active, 
		10 AS min_quantity	
FROM 	dual	
	UNION ALL
-- orders bitfinex BTC/USD
SELECT	3 AS id,
		NULL AS parent_id,
		1 AS entity_id,	
		3 AS market_id,	
		2 AS symbol_id,	
		'https://api.bitfinex.com/v1/book/BTCUSD' AS endpoint, 
		'?limit_asks=2500&' || 'limit_bids=2500' AS params,
		1 AS active, 
		10 AS min_quantity	
FROM 	dual	
	UNION ALL
-- trades bitstamp BTC/USD
SELECT	4 AS id,
		NULL AS parent_id,
		2 AS entity_id,	
		2 AS market_id,	
		2 AS symbol_id,	
		'https://www.bitstamp.net/api/v2/transactions/btcusd/' AS endpoint,
		'?time=hour' AS params,
		1 AS active, 
		1 AS min_quantity		
FROM 	dual	
	UNION ALL
-- trades bitfinex BTC/USD
SELECT	5 AS id,
		NULL AS parent_id,
		2 AS entity_id,	
		3 AS market_id,	
		2 AS symbol_id,	
		'https://api-pub.bitfinex.com/v2/trades/tBTCUSD/hist' AS endpoint,
		'?limit=10000&' || 'start=%ds_unix_ms%&' || 'end=%df_unix_ms%&' || 'sort=1'	AS params,
		1 AS active, 
		1 AS min_quantity		
FROM dual	
	UNION ALL
-- trades binance BTC/USD
SELECT	6 AS id,
		NULL AS parent_id,
		2 AS entity_id,	
		1 AS market_id,	
		2 AS symbol_id,	
		'https://api.binance.com/api/v3/aggTrades' AS endpoint,
		'?symbol=BTCUSDT&' || 'startTime=%ds_unix_ms_m10s%&' || 'endTime=%ds_unix_ms%&' || 'limit=1000' AS params,
		1 AS active, 
		1 AS min_quantity		
FROM 	dual
	UNION ALL
-- parent trades binance BTC/USD
SELECT	7 AS id,
		6 AS parent_id,
		2 AS entity_id,	
		1 AS market_id,	
		2 AS symbol_id,	
		'https://api.binance.com/api/v3/aggTrades' AS endpoint,
		'?symbol=BTCUSDT&' || 'fromId=%trade_id_LAST%&' || 'limit=1000' AS params,
		1 AS active, 
		1 AS min_quantity		
FROM 	dual
;

COMMIT;