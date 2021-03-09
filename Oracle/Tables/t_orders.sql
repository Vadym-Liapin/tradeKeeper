CREATE TABLE &&SCHEMA.t_orders (
    id				number,
	batch_id		number 	CONSTRAINT t_orders_batch_id_nn		NOT NULL,
	request_id		number	CONSTRAINT t_orders_request_id_nn	NOT NULL,
	side_id			number	CONSTRAINT t_orders_side_id_nn		NOT NULL,
	price			number	CONSTRAINT t_orders_price_nn		NOT NULL,
	quantity		number	CONSTRAINT t_orders_quantity_nn		NOT NULL,
	quantity_CUM	number	CONSTRAINT t_orders_quantity_cum_nn	NOT NULL,
    CONSTRAINT t_orders_pk				PRIMARY KEY (id),
	CONSTRAINT t_orders_batch_id_fk		FOREIGN KEY (batch_id) REFERENCES &&SCHEMA.t_batches (id),
	CONSTRAINT t_orders_request_id_fk	FOREIGN KEY (request_id) REFERENCES &&SCHEMA.t_requests (id),
	CONSTRAINT t_orders_side_id_fk		FOREIGN KEY (side_id) REFERENCES &&SCHEMA.t_sides (id)
)
PARTITION BY REFERENCE (t_orders_batch_id_fk);

COMMENT ON TABLE &&SCHEMA.t_orders IS 'Orders';

COMMENT ON COLUMN &&SCHEMA.t_orders.id				IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_orders.batch_id		IS 'Batch ID';
COMMENT ON COLUMN &&SCHEMA.t_orders.request_id		IS 'Request ID';
COMMENT ON COLUMN &&SCHEMA.t_orders.side_id			IS 'Side ID';
COMMENT ON COLUMN &&SCHEMA.t_orders.price			IS 'Price';
COMMENT ON COLUMN &&SCHEMA.t_orders.quantity		IS 'Quantity';
COMMENT ON COLUMN &&SCHEMA.t_orders.quantity_CUM	IS 'Cumulative Quantity';
