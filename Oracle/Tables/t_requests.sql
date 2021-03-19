CREATE TABLE &&SCHEMA.t_requests (
    id			number,
	parent_id	number,
	entity_id	number			CONSTRAINT t_requests_entity_id_nn		NOT NULL,
	market_id	number			CONSTRAINT t_requests_market_id_nn		NOT NULL,
	symbol_id	number 			CONSTRAINT t_requests_symbol_id_nn		NOT NULL,
	endpoint	varchar2(100)	CONSTRAINT t_requests_endpoint_nn		NOT NULL,
	params		varchar2(100),
	active		number(1)		CONSTRAINT t_requests_active_nn			NOT NULL,
    CONSTRAINT t_requests_pk			PRIMARY KEY (id),
	CONSTRAINT t_requests_uniq			UNIQUE (entity_id, market_id, symbol_id, parent_id),
	CONSTRAINT t_requests_parent_id_fk	FOREIGN KEY (parent_id) REFERENCES &&SCHEMA.t_requests (id),
	CONSTRAINT t_requests_entity_id_fk	FOREIGN KEY (entity_id) REFERENCES &&SCHEMA.t_entities (id),
	CONSTRAINT t_requests_market_id_fk	FOREIGN KEY (market_id) REFERENCES &&SCHEMA.t_markets (id),
	CONSTRAINT t_requests_symbol_id_fk	FOREIGN KEY (symbol_id) REFERENCES &&SCHEMA.t_symbols (id),
	CONSTRAINT t_requests_active		CHECK (active IN (0, 1))
);

COMMENT ON TABLE &&SCHEMA.t_requests IS 'API Requests';

COMMENT ON COLUMN &&SCHEMA.t_requests.id   		IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_requests.parent_id	IS 'Parent ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.entity_id	IS 'Entity ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.market_id	IS 'Market ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.symbol_id	IS 'Symbol ID';
COMMENT ON COLUMN &&SCHEMA.t_requests.endpoint	IS 'Endpoint';
COMMENT ON COLUMN &&SCHEMA.t_requests.params	IS 'Parameters';
COMMENT ON COLUMN &&SCHEMA.t_requests.active	IS 'Active Flag: 0/1';

TRUNCATE TABLE &&SCHEMA.t_requests;

INSERT INTO &&SCHEMA.t_requests (id, parent_id, entity_id, market_id, symbol_id, endpoint, params, active)
-- orders binance BTC/USDT
SELECT	1 AS id,
		NULL AS parent_id,
		1 AS entity_id,	
		1 AS market_id,	
		1 AS symbol_id,	
		'https://api.binance.com/api/v3/depth' AS endpoint, 
		'?symbol=BTCUSDT&' || 'limit=5000' AS params, 
		1 AS active
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
		1 AS active
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
		1 AS active
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
		1 AS active
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
		1 AS active
FROM dual	
	UNION ALL
-- trades binance BTC/USDT
SELECT	6 AS id,
		NULL AS parent_id,
		2 AS entity_id,	
		1 AS market_id,	
		1 AS symbol_id,	
		'https://api.binance.com/api/v3/aggTrades' AS endpoint,
		'?symbol=BTCUSDT&' || 'startTime=%ds_unix_ms%&' || 'endTime=%ds_unix_ms_p10s%&' || 'limit=1000' AS params,
		1 AS active
FROM 	dual
	UNION ALL
-- child trades binance BTC/USDT
SELECT	7 AS id,
		6 AS parent_id,
		2 AS entity_id,	
		1 AS market_id,	
		1 AS symbol_id,	
		'https://api.binance.com/api/v3/aggTrades' AS endpoint,
		'?symbol=BTCUSDT&' || 'fromId=%fromId%&' || 'limit=1000' AS params,
		1 AS active
FROM 	dual
	UNION ALL
-- orders hitbtc BTC/USD
SELECT	8 AS id,
		NULL AS parent_id,
		1 AS entity_id,	
		4 AS market_id,	
		2 AS symbol_id,	
		'https://api.hitbtc.com/api/2/public/orderbook/btcusd'	AS endpoint, 
		'?limit=0' AS params,
		1 AS active
FROM 	dual
	UNION ALL
-- trades hitbtc BTC/USD
SELECT	9 AS id,
		NULL AS parent_id,
		2 AS entity_id,	
		4 AS market_id,	
		2 AS symbol_id,	
		'https://api.hitbtc.com/api/2/public/trades/BTCUSD' AS endpoint,
		'?sort=ASC&' || 'limit=1000&' || 'from=%ds_ISO8601%&' || 'till=%df_ISO8601%' AS params,
		1 AS active
FROM 	dual
	UNION ALL
-- child trades binance BTC/USD
SELECT	10 AS id,
		9 AS parent_id,
		2 AS entity_id,	
		4 AS market_id,	
		2 AS symbol_id,	
		'https://api.hitbtc.com/api/2/public/trades/BTCUSD' AS endpoint,
		'?sort=ASC&' || 'limit=1000&' || 'from=%ds_ISO8601%&' || 'till=%df_ISO8601%&' || 'offset=%offset%' AS params,
		1 AS active
FROM 	dual
	UNION ALL
-- orders kraken BTC/USD
SELECT	11 AS id,
		NULL AS parent_id,
		1 AS entity_id,	
		5 AS market_id,	
		2 AS symbol_id,	
		'https://api.kraken.com/0/public/Depth'	AS endpoint, 
		'?pair=BTCUSD&' || 'count=1000' AS params,
		1 AS active
FROM 	dual
;

COMMIT;