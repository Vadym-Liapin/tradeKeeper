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

	PROCEDURE insert_trades_gtt (
		in_batch_id			IN	trades_gtt.batch_id%type,
		in_request_id		IN	trades_gtt.request_id%type,
		in_json				IN	clob,
        out_trade_id_MIN	OUT	trades_gtt.trade_id%type
	);
	
	PROCEDURE insert_trades (
		in_batch_id	IN	trades.batch_id%type,
		out_code	OUT	number,
		out_message	OUT	varchar2
	);
	
END;
/
