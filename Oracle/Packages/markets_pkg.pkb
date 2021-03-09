CREATE OR REPLACE PACKAGE BODY &&SCHEMA.markets_pkg
IS
	FUNCTION get_vw_requests_row (
		in_id	IN	vw_requests.id%type
	) RETURN vw_requests%rowtype
	IS
		lr_requests	vw_requests%rowtype;
	BEGIN
		SELECT	r.*
		INTO	lr_requests
		FROM	vw_requests r
		WHERE	r.id = in_id;
		
		RETURN lr_requests;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			RETURN NULL;
	END get_vw_requests_row;
	
	FUNCTION get_batches_row (
		in_id	IN	batches.id%type
	) RETURN batches%rowtype
	IS
		lr_batches	batches%rowtype;
	BEGIN
		SELECT	b.*
		INTO	lr_batches
		FROM	batches b
		WHERE	b.id = in_id;
		
		RETURN lr_batches;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			RETURN NULL;
	END get_batches_row;

	PROCEDURE get_active_endpoints (
		in_batch_id	IN	batches.id%type,
        out_cursor	OUT	sys_refcursor
    )
	IS
		lr_batches	batches%rowtype;
		
		out_rc_txt	varchar2(4000);
	BEGIN
		lr_batches := get_batches_row(in_id => in_batch_id);
		
		OPEN out_cursor
		FOR
			SELECT	r.id AS request_id,
					REPLACE(
						REPLACE(
							r.endpoint, 
							'%ds_unix_ms%', 
							lr_batches.ds_unix_ms
						),
						'%df_unix_ms%',
						lr_batches.df_unix_ms
					) AS endpoint,
					e.code AS entity,
					m.code AS market
			FROM	requests r	INNER JOIN entities e
								ON	e.id = r.entity_id
								INNER JOIN markets m
								ON	m.id = r.market_id
			WHERE	r.active = 1
			ORDER BY	r.entity_id,
						r.market_id,
						r.id;
	EXCEPTION
		WHEN OTHERS
		THEN
            out_rc_txt := ERRORS_PKG.log_error(in_params => 'in_batch_id=' || in_batch_id);
	END get_active_endpoints;

	FUNCTION create_batch
	RETURN batches.id%type
	IS
		l_batch_id	batches.id%type;
		out_rc_txt	varchar2(4000);
		l_created	batches.created%type;
	BEGIN
		l_created := SYSDATE;
		
		INSERT INTO batches (
			id, 
			created, 
			ds_unix_s, 
			df_unix_s,
			ds_unix_ms, 
			df_unix_ms
		)
		VALUES (
			SQN_batches.NEXTVAL, 
			l_created,
			UTILS_PKG.date_to_unix_seconds(l_created - 1/24),
			UTILS_PKG.date_to_unix_seconds(l_created),
			UTILS_PKG.date_to_unix_milliseconds(l_created - 1/24),
			UTILS_PKG.date_to_unix_milliseconds(l_created)
		)
		RETURNING 	id
		INTO		l_batch_id;
		
		RETURN l_batch_id;
	EXCEPTION
		WHEN OTHERS
		THEN
            out_rc_txt := ERRORS_PKG.log_error(in_params => NULL);

			ROLLBACK;
	END create_batch;
	
	PROCEDURE insert_orders (
		in_batch_id		IN	orders.batch_id%type,
		in_request_id	IN	orders.request_id%type,	
		in_json			IN	clob
	)
	IS
		lr_vw_requests	vw_requests%rowtype;
		
		out_rc_txt	varchar2(4000);
	BEGIN
		lr_vw_requests := get_vw_requests_row(in_id => in_request_id);
		
		INSERT INTO orders (
			id,
			batch_id,
			request_id,
			side_id,
			price,
			quantity,
			quantity_CUM
		)
		SELECT	SQN_orders.NEXTVAL AS id,
				in_batch_id AS batch_id,
				in_request_id AS request_id,
				d.side_id,
				d.price,
				d.quantity,
				d.quantity_CUM
		FROM	(
					SELECT	d.side_id,
							d.price,
							d.quantity,
							d.quantity_CUM
					FROM	(
								SELECT	1 AS side_id,
										t.price,
										t.quantity,
										SUM(t.quantity) OVER (ORDER BY t.rn ASC) AS quantity_CUM
								FROM	JSON_TABLE(
											in_json,
											'$.bids[*]'
											COLUMNS (
												rn 			FOR ORDINALITY,
												price		number	PATH '$[0]',
												quantity	number	PATH '$[1]'
											)
										) t
								WHERE	lr_vw_requests.market IN ('binance', 'bitstamp')
									UNION ALL
								SELECT	2 AS side_id,
										t.price,
										t.quantity,
										SUM(t.quantity) OVER (ORDER BY t.rn ASC) AS quantity_CUM
								FROM	JSON_TABLE(
											in_json,
											'$.asks[*]'
											COLUMNS (
												rn 			FOR ORDINALITY,
												price		number	PATH '$[0]',
												quantity	number	PATH '$[1]'
											)
										) t
								WHERE	lr_vw_requests.market IN ('binance', 'bitstamp')
									UNION ALL
								SELECT	1 AS side_id,
										t.price,
										t.quantity,
										SUM(t.quantity) OVER (ORDER BY t.rn ASC) AS quantity_CUM
								FROM	JSON_TABLE(
											in_json,
											'$.bids[*]'
											COLUMNS (
												rn 			FOR ORDINALITY,
												price		number	PATH '$.price',
												quantity	number	PATH '$.amount'
											)
										) t
								WHERE	lr_vw_requests.market = 'bitfinex'
									UNION ALL
								SELECT	2 AS side_id,
										t.price,
										t.quantity,
										SUM(t.quantity) OVER (ORDER BY t.rn ASC) AS quantity_CUM
								FROM	JSON_TABLE(
											in_json,
											'$.asks[*]'
											COLUMNS (
												rn 			FOR ORDINALITY,
												price		number	PATH '$.price',
												quantity	number	PATH '$.amount'
											)
										) t
								WHERE	lr_vw_requests.market = 'bitfinex'
							) d
				) d	INNER JOIN requests r
        			ON	r.id = in_request_id
        WHERE	d.quantity >= r.min_quantity;
		
		COMMIT;
	EXCEPTION
		WHEN OTHERS
		THEN
            out_rc_txt := ERRORS_PKG.log_error(in_params => 'batch_id=' || in_batch_id || ', request_id=' || in_request_id);

			ROLLBACK;
	END insert_orders;
	
	PROCEDURE insert_trades (
		in_batch_id		IN	trades.batch_id%type,
		in_request_id	IN	trades.request_id%type,	
		in_json			IN	clob
	)
	IS
		lr_vw_requests	vw_requests%rowtype;
		
		out_rc_txt	varchar2(4000);
	BEGIN
		lr_vw_requests := get_vw_requests_row(in_id => in_request_id);

		INSERT INTO trades_gtt (
			side_id,
			trade_id,
			created,
			price,
			quantity
		)
		SELECT	CASE t.side WHEN 0 THEN 3 WHEN 1 THEN 4 END AS side_id,
				t.tid AS trade_id,
				(SELECT UTILS_PKG.unix_seconds_to_date(t.unix_seconds) FROM dual) AS created,
				t.price,
				t.quantity
		FROM	JSON_TABLE(
					in_json,
					'$[*]'
					COLUMNS (
						rn 				FOR ORDINALITY,
						tid				varchar2(15)	PATH '$.tid',
						unix_seconds	number			PATH '$.date',
						side			number			PATH '$.type',
						price			number			PATH '$.price',
						quantity		number			PATH '$.amount'
					)
				) t
		WHERE	lr_vw_requests.market = 'bitstamp'
			UNION ALL
		SELECT	CASE WHEN t.quantity >= 0 THEN 3 WHEN t.quantity < 0 THEN 4 END AS side_id,
				t.trade_id,
				(SELECT UTILS_PKG.unix_milliseconds_to_date(t.unix_milliseconds) FROM dual) AS created,
				t.price,
				ABS(t.quantity) AS quantity
		FROM	JSON_TABLE(
					in_json,
					'$[*]'
					COLUMNS (
						rn 					FOR ORDINALITY,
						trade_id			varchar2(15)	PATH '$[0]',
						unix_milliseconds	number			PATH '$[1]',
						price				number			PATH '$[3]',
						quantity			number			PATH '$[2]'
					)
				) t
		WHERE	lr_vw_requests.market = 'bitfinex';
								
		INSERT INTO trades (
			id,
			batch_id,
			request_id,
			side_id,
			trade_id,
			created,
			price,
			quantity
		)
		SELECT	SQN_trades.NEXTVAL AS id,
				in_batch_id AS batch_id,
				in_request_id AS request_id,
				d.side_id,
				d.trade_id,
				d.created,
				d.price,
				d.quantity
		FROM	trades_gtt d	INNER JOIN requests r
								ON	r.id = in_request_id
        WHERE	d.quantity >= r.min_quantity;
		
		COMMIT;
	EXCEPTION
		WHEN OTHERS
		THEN
            out_rc_txt := ERRORS_PKG.log_error(in_params => 'batch_id=' || in_batch_id || ', request_id=' || in_request_id);

			ROLLBACK;
	END insert_trades;	
	
	PROCEDURE insert_trades_binance (
		in_batch_id		IN	trades.batch_id%type,
		in_request_id	IN	trades.request_id%type,	
		in_json			IN	clob
	)
	IS
		lr_vw_requests	vw_requests%rowtype;
		
		out_rc_txt	varchar2(4000);
	BEGIN
		lr_vw_requests := get_vw_requests_row(in_id => in_request_id);
		
		INSERT INTO trades_gtt (
			side_id,
			trade_id,
			created,
			price,
			quantity
		)
		SELECT	CASE t.is_buyer_maker WHEN 'false' THEN 3 WHEN 'true' THEN 4 END AS side_id,
				t.trade_id,
				(SELECT UTILS_PKG.unix_milliseconds_to_date(t.unix_milliseconds) FROM dual) AS created,
				t.price,
				t.quantity
		FROM	JSON_TABLE(
					in_json,
					'$[*]'
					COLUMNS (
						rn 					FOR ORDINALITY,
						trade_id			varchar2(15)	PATH '$.a',
						price				number			PATH '$.p',
						quantity			number			PATH '$.q',
						unix_milliseconds	number			PATH '$.T',
						is_buyer_maker		varchar2(5)		PATH '$.m'
					)
				) t
		WHERE	lr_vw_requests.market = 'binance';

		INSERT INTO trades (
			id,
			batch_id,
			request_id,
			side_id,
			trade_id,
			created,
			price,
			quantity
		)
		SELECT	SQN_trades.NEXTVAL AS id,
				in_batch_id AS batch_id,
				in_request_id AS request_id,
				d.side_id,
				d.trade_id,
				d.created,
				d.price,
				d.quantity
		FROM	trades_gtt d	INNER JOIN requests r
								ON	r.id = in_request_id
        WHERE	d.quantity >= r.min_quantity;
		
		COMMIT;
	EXCEPTION
		WHEN OTHERS
		THEN
            out_rc_txt := ERRORS_PKG.log_error(in_params => 'batch_id=' || in_batch_id || ', request_id=' || in_request_id);

			ROLLBACK;
	END insert_trades_binance;		
END;
/