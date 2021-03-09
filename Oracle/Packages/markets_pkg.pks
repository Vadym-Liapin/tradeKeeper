CREATE OR REPLACE PACKAGE &&SCHEMA.markets_pkg
IS

	PROCEDURE get_active_endpoints (
		in_batch_id	IN	batches.id%type,
        out_cursor	OUT	sys_refcursor
    );

	FUNCTION create_batch
	RETURN batches.id%type;

	PROCEDURE insert_orders (
		in_batch_id		IN	orders.batch_id%type,
		in_request_id	IN	orders.request_id%type,	
		in_json			IN	clob
	);

	PROCEDURE insert_trades (
		in_batch_id		IN	trades.batch_id%type,
		in_request_id	IN	trades.request_id%type,	
		in_json			IN	clob
	);

	PROCEDURE insert_trades_binance (
		in_batch_id		IN	trades.batch_id%type,
		in_request_id	IN	trades.request_id%type,	
		in_json			IN	clob
	);
	
END;
/
