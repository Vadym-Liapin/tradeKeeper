CREATE OR REPLACE PACKAGE &&SCHEMA.markets_pkg
IS

	PROCEDURE get_active_endpoints (
        out_cursor	OUT	sys_refcursor,
		out_code	OUT	number,
		out_message	OUT	varchar2
    );

	PROCEDURE create_batch (
		out_cursor	OUT	sys_refcursor,
		out_code	OUT	number,
		out_message	OUT	varchar2
	);

	PROCEDURE insert_orders (
		in_batch_id		IN	orders.batch_id%type,
		in_request_id	IN	orders.request_id%type,	
		in_json			IN	clob,
		out_code		OUT	number,
		out_message		OUT	varchar2
	);

	PROCEDURE insert_trades_gtt (
		in_batch_id			IN	trades_gtt.batch_id%type,
		in_request_id		IN	trades_gtt.request_id%type,
		in_json				IN	clob,
        out_trade_id_LAST	OUT	trades_gtt.trade_id%type,
		out_code			OUT	number,
		out_message			OUT	varchar2
	);
	
	PROCEDURE insert_trades (
		in_batch_id	IN	trades.batch_id%type,
		out_code	OUT	number,
		out_message	OUT	varchar2
	);
	
END;
/
