CREATE GLOBAL TEMPORARY TABLE &&SCHEMA.t_trades_gtt (
	side_id		number,
	trade_id	varchar2(15),	
	created		date,
	price		number,
	quantity	number
)
ON COMMIT DELETE ROWS;

COMMENT ON TABLE &&SCHEMA.t_trades_gtt IS 'Temporary Trades';

COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.side_id		IS 'Side ID';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.trade_id	IS 'Trade ID';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.created		IS 'Created Date';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.price		IS 'Price';
COMMENT ON COLUMN &&SCHEMA.t_trades_gtt.quantity	IS 'Quantity';