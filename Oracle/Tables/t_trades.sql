CREATE TABLE &&SCHEMA.t_trades (
    id				number,
	batch_id		number 			CONSTRAINT t_trades_batch_id_nn		NOT NULL,
	request_id		number			CONSTRAINT t_trades_request_id_nn	NOT NULL,
	side_id			number			CONSTRAINT t_trades_side_id_nn		NOT NULL,
	trade_id		varchar2(15),	
	created			date			CONSTRAINT t_trades_created_nn		NOT NULL,
	price			number			CONSTRAINT t_trades_price_nn		NOT NULL,
	quantity		number			CONSTRAINT t_trades_quantity_nn		NOT NULL,
    CONSTRAINT t_trades_pk				PRIMARY KEY (id),
	CONSTRAINT t_trades_batch_id_fk		FOREIGN KEY (batch_id) REFERENCES &&SCHEMA.t_batches (id),
	CONSTRAINT t_trades_request_id_fk	FOREIGN KEY (request_id) REFERENCES &&SCHEMA.t_requests (id),
	CONSTRAINT t_trades_side_id_fk		FOREIGN KEY (side_id) REFERENCES &&SCHEMA.t_sides (id)
)
PARTITION BY REFERENCE (t_trades_batch_id_fk);

COMMENT ON TABLE &&SCHEMA.t_trades IS 'Trades';

COMMENT ON COLUMN &&SCHEMA.t_trades.id			IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_trades.batch_id	IS 'Batch ID';
COMMENT ON COLUMN &&SCHEMA.t_trades.request_id	IS 'Request ID';
COMMENT ON COLUMN &&SCHEMA.t_trades.side_id		IS 'Side ID';
COMMENT ON COLUMN &&SCHEMA.t_trades.trade_id	IS 'Trade ID';
COMMENT ON COLUMN &&SCHEMA.t_trades.created		IS 'Created Date';
COMMENT ON COLUMN &&SCHEMA.t_trades.price		IS 'Price';
COMMENT ON COLUMN &&SCHEMA.t_trades.quantity	IS 'Quantity';