CREATE GLOBAL TEMPORARY TABLE &&SCHEMA.t_trades_gtt (
	batch_id	number,
    request_id	number,
    side_id		number,
	trade_id	varchar2(20),	
	created		date,
	price		number,
	quantity	number
)
ON COMMIT PRESERVE ROWS;

COMMENT ON TABLE &&SCHEMA.t_trades_gtt IS 'Temporary Trades';

COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.batch_id	IS 'Batch ID';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.request_id	IS 'Request ID';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.side_id		IS 'Side ID';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.trade_id	IS 'Trade ID';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.created		IS 'Created Date';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.price		IS 'Price';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.quantity	IS 'Quantity';