CREATE OR REPLACE PACKAGE BODY &&SCHEMA.markets_pkg
IS
	eMyError	exception;
	eMyLock		exception;
    PRAGMA EXCEPTION_INIT (eMyLock, -54);

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
		in_id		IN	batches.id%type,
		in_lock		IN	boolean,
		out_code	OUT	number,
		out_message	OUT	varchar2
	) RETURN batches%rowtype
	IS
		lr_batches	batches%rowtype;
	BEGIN
		UTILS_PKG.init_out_params(out_code, out_message);
		
		IF in_lock
		THEN
			SELECT	b.*
			INTO	lr_batches
			FROM	batches b
			WHERE	b.id = in_id
			FOR UPDATE NOWAIT;
		ELSE
			SELECT	b.*
			INTO	lr_batches
			FROM	batches b
			WHERE	b.id = in_id;
		END IF;
		
		RETURN lr_batches;
	EXCEPTION
		WHEN eMyLock
		THEN
			out_code	:= -1;
            out_message	:= 'BatchID ' || in_id || ' is locked by another session';
		WHEN NO_DATA_FOUND
		THEN
			RETURN NULL;
	END get_batches_row;

	PROCEDURE get_active_endpoints (
        out_cursor	OUT	sys_refcursor,
		out_code	OUT	number,
		out_message	OUT	varchar2
    )
	IS
	BEGIN
		UTILS_PKG.init_out_params(out_code, out_message);
		
		OPEN out_cursor
		FOR
			SELECT	r.id AS request_id,
					r.parent_id AS request_parent_id,
					r.endpoint,
					r.params,
					e.code AS entity,
					m.code AS market
			FROM	requests r	INNER JOIN entities e
								ON	e.id = r.entity_id
								INNER JOIN markets m
								ON	m.id = r.market_id
			WHERE	r.active = 1
			ORDER BY	CASE e.code WHEN 'orders' THEN 1 WHEN 'trades' THEN 2 ELSE 3 END,
						r.market_id,
						NVL(r.parent_id, r.id),
						r.id;
	EXCEPTION
		WHEN eMyError
		THEN
			out_code 	:= 	CASE out_code WHEN 0 THEN -1 ELSE out_code END;
			out_message	:= 	ERRORS_PKG.log_error(
								ERRORS_PKG.add_number('out_code', out_code) || 
								ERRORS_PKG.add_varchar2('out_message', out_message)
							);
		WHEN OTHERS
		THEN
			out_code	:= -1;
            out_message	:= ERRORS_PKG.log_error(NULL);
	END get_active_endpoints;

	PROCEDURE create_batch (
		out_cursor	OUT	sys_refcursor,
		out_code	OUT	number,
		out_message	OUT	varchar2
	)
	IS
		l_created	batches.created%type;
		l_id		batches.id%type;
	BEGIN
		UTILS_PKG.init_out_params(out_code, out_message);
		
		l_created := SYSDATE;
		
		INSERT INTO batches (
			id, 
			created,
			ds,
			df,
			ds_unix_s, 
			df_unix_s,
			ds_unix_ms, 
			df_unix_ms,
			ds_ISO8601,
			df_ISO8601
		)
		VALUES (
			SQN_batches.NEXTVAL, 
			l_created,
			l_created - 1/24,
			l_created,
			UTILS_PKG.date_to_unix_seconds(l_created - 1/24),
			UTILS_PKG.date_to_unix_seconds(l_created),
			UTILS_PKG.date_to_unix_milliseconds(l_created - 1/24),
			UTILS_PKG.date_to_unix_milliseconds(l_created),
			to_char(l_created - 1/24, 'YYYY-MM-DD') || 'T' || to_char(l_created - 1/24, 'HH24:MI:SS'),
			to_char(l_created, 'YYYY-MM-DD') || 'T' || to_char(l_created, 'HH24:MI:SS')
		)
		RETURNING 	id
		INTO		l_id;
		
		OPEN out_cursor
		FOR
			SELECT	b.id,
					b.ds_unix_s,
					b.df_unix_s,
					b.ds_unix_ms,
					b.df_unix_ms,
					b.ds_unix_ms + 10000 AS ds_unix_ms_p10s,
					b.ds_ISO8601,
					b.df_ISO8601
			FROM	batches b
			WHERE	b.id = l_id;
		
	EXCEPTION
		WHEN eMyError
		THEN
			out_code 	:= 	CASE out_code WHEN 0 THEN -1 ELSE out_code END;
			out_message	:= 	ERRORS_PKG.log_error(
								ERRORS_PKG.add_number('out_code', out_code) || 
								ERRORS_PKG.add_varchar2('out_message', out_message)
							);
			
			ROLLBACK;
		WHEN OTHERS
		THEN
			out_code	:= -1;
            out_message	:= ERRORS_PKG.log_error(NULL);

			ROLLBACK;
	END create_batch;
	
	PROCEDURE insert_orders (
		in_batch_id		IN	orders.batch_id%type,
		in_request_id	IN	orders.request_id%type,	
		in_json			IN	clob,
		out_code		OUT	number,
		out_message		OUT	varchar2
	)
	IS
		lr_batches		batches%rowtype;
		lr_vw_requests	vw_requests%rowtype;
	BEGIN
		UTILS_PKG.init_out_params(out_code, out_message);

		lr_batches := get_batches_row(in_id => in_batch_id, in_lock => TRUE, out_code => out_code, out_message => out_message);
		IF out_code <> 0
		THEN
			RAISE eMyError;
		END IF;

		lr_vw_requests 	:= get_vw_requests_row(in_id => in_request_id);
		
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
									UNION ALL
								SELECT	1 AS side_id,
										t.price,
										t.quantity,
										SUM(t.quantity) OVER (ORDER BY t.rn ASC) AS quantity_CUM
								FROM	JSON_TABLE(
											in_json,
											'$.bid[*]'
											COLUMNS (
												rn 			FOR ORDINALITY,
												price		number	PATH '$.price',
												quantity	number	PATH '$.size'
											)
										) t
								WHERE	lr_vw_requests.market = 'hitbtc'
									UNION ALL
								SELECT	2 AS side_id,
										t.price,
										t.quantity,
										SUM(t.quantity) OVER (ORDER BY t.rn ASC) AS quantity_CUM
								FROM	JSON_TABLE(
											in_json,
											'$.ask[*]'
											COLUMNS (
												rn 			FOR ORDINALITY,
												price		number	PATH '$.price',
												quantity	number	PATH '$.size'
											)
										) t
								WHERE	lr_vw_requests.market = 'hitbtc'
									UNION ALL
								SELECT	1 AS side_id,
										t.price,
										t.quantity,
										SUM(t.quantity) OVER (ORDER BY t.rn ASC) AS quantity_CUM
								FROM	JSON_TABLE(
											in_json,
											'$.result.*.bids[*]'
											COLUMNS (
												rn 			FOR ORDINALITY,
												price		number	PATH '$[0]',
												quantity	number	PATH '$[1]'
											)
										) t
								WHERE	lr_vw_requests.market = 'kraken'
									UNION ALL
								SELECT	2 AS side_id,
										t.price,
										t.quantity,
										SUM(t.quantity) OVER (ORDER BY t.rn ASC) AS quantity_CUM
								FROM	JSON_TABLE(
											in_json,
											'$.result.*.asks[*]'
											COLUMNS (
												rn 			FOR ORDINALITY,
												price		number	PATH '$[0]',
												quantity	number	PATH '$[1]'
											)
										) t
								WHERE	lr_vw_requests.market = 'kraken'
							) d
				) d	INNER JOIN requests r
        			ON	r.id = in_request_id
					INNER JOIN big_sets bs
					ON	bs.symbol_id = r.symbol_id
					AND	bs.entity_id = r.entity_id
        WHERE	(d.quantity >= bs.quantity_base OR d.quantity * d.price > bs.quantity_quote);
		
		out_message := 'Inserted ' || SQL%ROWCOUNT || ' orders';
		
		COMMIT;
	EXCEPTION
		WHEN eMyError
		THEN
			out_code 	:= 	CASE out_code WHEN 0 THEN -1 ELSE out_code END;
			out_message	:= 	ERRORS_PKG.log_error(
								ERRORS_PKG.add_number('in_batch_id', in_batch_id) || 
								ERRORS_PKG.add_number('in_request_id', in_request_id) || 
								ERRORS_PKG.add_number('out_code', out_code) || 
								ERRORS_PKG.add_varchar2('out_message', out_message)
							);

			
			ROLLBACK;
		WHEN OTHERS
		THEN
			out_code	:= 	-1;
            out_message	:= 	ERRORS_PKG.log_error(
								ERRORS_PKG.add_number('in_batch_id', in_batch_id) || 
								ERRORS_PKG.add_number('in_request_id', in_request_id)
							);

			ROLLBACK;
	END insert_orders;

	PROCEDURE insert_trades_gtt (
		in_batch_id		IN	trades_gtt.batch_id%type,
		in_request_id	IN	trades_gtt.request_id%type,
		in_json			IN	clob,
		out_code		OUT	number,
		out_message		OUT	varchar2
	)
	IS
		lr_batches		batches%rowtype;
		lr_vw_requests	vw_requests%rowtype;
	BEGIN
		UTILS_PKG.init_out_params(out_code, out_message);
		
		lr_batches := get_batches_row(in_id => in_batch_id, in_lock => TRUE, out_code => out_code, out_message => out_message);
		IF out_code <> 0
		THEN
			RAISE eMyError;
		END IF;

		lr_vw_requests 	:= get_vw_requests_row(in_id => in_request_id);
		
		INSERT INTO trades_gtt (
			batch_id,
            request_id,
            side_id,
			trade_id,
			created,
			price,
			quantity
		)
		SELECT	in_batch_id AS batch_id,
				in_request_id AS request_id,
        		CASE t.is_buyer_maker WHEN 'false' THEN 3 WHEN 'true' THEN 4 END AS side_id,
				t.trade_id,
				(SELECT UTILS_PKG.unix_milliseconds_to_date(t.timestamp) FROM dual) AS created,
				t.price,
				t.quantity
		FROM	JSON_TABLE(
					in_json,
					'$[*]'
					COLUMNS (
						rn 				FOR ORDINALITY,
						trade_id		varchar2(15)	PATH '$.a',
						price			number			PATH '$.p',
						quantity		number			PATH '$.q',
						timestamp		number			PATH '$.T',
						is_buyer_maker	varchar2(5)		PATH '$.m'
					)
				) t
		WHERE	lr_vw_requests.market = 'binance'
        	UNION ALL
		SELECT	in_batch_id AS batch_id,
				in_request_id AS request_id,
        		CASE t.side WHEN 0 THEN 3 WHEN 1 THEN 4 END AS side_id,
				t.tid AS trade_id,
				(SELECT UTILS_PKG.unix_seconds_to_date(t.timestamp) FROM dual) AS created,
				t.price,
				t.quantity
		FROM	JSON_TABLE(
					in_json,
					'$[*]'
					COLUMNS (
						rn 			FOR ORDINALITY,
						tid			varchar2(15)	PATH '$.tid',
						timestamp	number			PATH '$.date',
						side		number			PATH '$.type',
						price		number			PATH '$.price',
						quantity	number			PATH '$.amount'
					)
				) t
		WHERE	lr_vw_requests.market = 'bitstamp'
			UNION ALL
		SELECT	in_batch_id AS batch_id,
				in_request_id AS request_id,
                CASE WHEN t.quantity >= 0 THEN 3 WHEN t.quantity < 0 THEN 4 END AS side_id,
				t.trade_id,
				(SELECT UTILS_PKG.unix_milliseconds_to_date(t.timestamp) FROM dual) AS created,
				t.price,
				ABS(t.quantity) AS quantity
		FROM	JSON_TABLE(
					in_json,
					'$[*]'
					COLUMNS (
						rn 			FOR ORDINALITY,
						trade_id	varchar2(15)	PATH '$[0]',
						timestamp	number			PATH '$[1]',
						price		number			PATH '$[3]',
						quantity	number			PATH '$[2]'
					)
				) t
		WHERE	lr_vw_requests.market = 'bitfinex'
			UNION ALL
		SELECT	in_batch_id AS batch_id,
				in_request_id AS request_id,
                CASE t.side WHEN 'buy' THEN 3 WHEN 'sell' THEN 4 END AS side_id,
				t.trade_id,
				to_date(REPLACE(SUBSTR(t.timestamp, 1, 19), 'T', ' '), 'YYYY-MM-DD HH24:MI:SS') AS created,
				t.price,
				ABS(t.quantity) AS quantity
		FROM	JSON_TABLE(
					in_json,
					'$[*]'
					COLUMNS (
						rn 			FOR ORDINALITY,
						trade_id	varchar2(15)	PATH '$.id',
						timestamp	varchar2(30)	PATH '$.timestamp',
						price		number			PATH '$.price',
						quantity	number			PATH '$.quantity',
						side		varchar2(4)		PATH '$.side'
					)
				) t
		WHERE	lr_vw_requests.market = 'hitbtc';

		out_message := 'Inserted ' || SQL%ROWCOUNT || ' trades';

		COMMIT;
	EXCEPTION
		WHEN eMyError
		THEN
			out_code 	:= 	CASE out_code WHEN 0 THEN -1 ELSE out_code END;
			out_message	:= 	ERRORS_PKG.log_error(
								ERRORS_PKG.add_number('in_batch_id', in_batch_id) || 
								ERRORS_PKG.add_number('in_request_id', in_request_id) || 
								ERRORS_PKG.add_number('out_code', out_code) || 
								ERRORS_PKG.add_varchar2('out_message', out_message)
							);
			
			ROLLBACK;
		WHEN OTHERS
		THEN
			out_code	:= 	-1;
            out_message	:= 	ERRORS_PKG.log_error(
								ERRORS_PKG.add_number('in_batch_id', in_batch_id) || 
								ERRORS_PKG.add_number('in_request_id', in_request_id)
							);

			ROLLBACK;
	END insert_trades_gtt;
        
	PROCEDURE insert_trades (
		in_batch_id	IN	trades.batch_id%type,
		out_code	OUT	number,
		out_message	OUT	varchar2
	)
	IS
		lr_batches	batches%rowtype;
	BEGIN
		UTILS_PKG.init_out_params(out_code, out_message);
		
		lr_batches := get_batches_row(in_id => in_batch_id, in_lock => TRUE, out_code => out_code, out_message => out_message);
		IF out_code <> 0
		THEN
			RAISE eMyError;
		END IF;
		
		INSERT INTO trades (
			id,
			batch_id,
			request_id,
			side_id,
			trade_id,
			created,
			price,
			quantity,
			cnt,
			aggregate
		)
		SELECT	SQN_trades.NEXTVAL AS id,
				d.batch_id,
				d.request_id,
				d.side_id,
				d.trade_id,
				d.created,
				d.price,
				d.quantity,
				1 AS cnt,
				NULL
		FROM	trades_gtt d	INNER JOIN requests r
								ON	r.id = d.request_id
								INNER JOIN big_sets bs
								ON	bs.symbol_id = r.symbol_id
								AND	bs.entity_id = r.entity_id
        WHERE	(d.quantity >= bs.quantity_base OR d.quantity * d.price > bs.quantity_quote)
        AND		d.batch_id = lr_batches.id
		AND		d.created BETWEEN lr_batches.ds AND lr_batches.df;

		out_message := out_message || 'Inserted ' || SQL%ROWCOUNT || ' trades; ';

		INSERT INTO trades (
			id,
			batch_id,
			request_id,
			side_id,
			trade_id,
			created,
			price,
			quantity,
			cnt,
			aggregate
		)
		SELECT	SQN_trades.NEXTVAL AS id,
				d.batch_id,
				d.request_id,
				d.side_id,
				d.trade_id,
				d.created,
				d.price,
				d.quantity,
				d.cnt,
				d.aggregate
		FROM	(
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							NULL AS price,
							SUM(d.quantity) AS quantity,
							COUNT(1) AS cnt,
							'ALL.QUANTITY.SUM' AS aggregate
					FROM	trades_gtt d
					WHERE	d.batch_id = lr_batches.id
					AND		d.created BETWEEN lr_batches.ds AND lr_batches.df
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
						UNION ALL
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							MIN(d.price) AS price,
							NULL AS quantity,
							NULL AS cnt,
							'ALL.PRICE.MIN' AS aggregate
					FROM	trades_gtt d
					WHERE	d.batch_id = lr_batches.id
					AND		d.created BETWEEN lr_batches.ds AND lr_batches.df
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
						UNION ALL
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							MAX(d.price) AS price,
							NULL AS quantity,
							NULL AS cnt,
							'ALL.PRICE.MAX' AS aggregate
					FROM	trades_gtt d
					WHERE	d.batch_id = lr_batches.id
					AND		d.created BETWEEN lr_batches.ds AND lr_batches.df
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
						UNION ALL
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							MIN(d.price) KEEP (DENSE_RANK FIRST ORDER BY d.created) AS price,
							NULL AS quantity,
							NULL AS cnt,
							'ALL.PRICE.FIRST' AS aggregate
					FROM	trades_gtt d
					WHERE	d.batch_id = lr_batches.id
					AND		d.created BETWEEN lr_batches.ds AND lr_batches.df
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
						UNION ALL
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							MAX(d.price) KEEP (DENSE_RANK LAST ORDER BY d.created) AS price,
							NULL AS quantity,
							NULL AS cnt,
							'ALL.PRICE.LAST' AS aggregate
					FROM	trades_gtt d
					WHERE	d.batch_id = lr_batches.id
					AND		d.created BETWEEN lr_batches.ds AND lr_batches.df
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
						UNION ALL
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							NULL AS price,
							SUM(d.quantity) AS quantity,
							COUNT(1) AS cnt,
							'BIG.QUANTITY.SUM' AS aggregate
					FROM	trades d
					WHERE	d.batch_id = lr_batches.id
					AND		d.aggregate IS NULL
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
						UNION ALL
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							MIN(d.price) AS price,
							NULL AS quantity,
							NULL AS cnt,
							'BIG.PRICE.MIN' AS aggregate
					FROM	trades d
					WHERE	d.batch_id = lr_batches.id
					AND		d.aggregate IS NULL
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
						UNION ALL
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							MAX(d.price) AS price,
							NULL AS quantity,
							NULL AS cnt,
							'BIG.PRICE.MAX' AS aggregate
					FROM	trades d
					WHERE	d.batch_id = lr_batches.id
					AND		d.aggregate IS NULL
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
						UNION ALL
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							MIN(d.price) KEEP (DENSE_RANK FIRST ORDER BY d.created) AS price,
							NULL AS quantity,
							NULL AS cnt,
							'BIG.PRICE.FIRST' AS aggregate
					FROM	trades d
					WHERE	d.batch_id = lr_batches.id
					AND		d.aggregate IS NULL
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
						UNION ALL
					SELECT	d.batch_id,
							d.request_id,
							d.side_id,
							NULL AS trade_id,
							NULL AS created,
							MAX(d.price) KEEP (DENSE_RANK LAST ORDER BY d.created) AS price,
							NULL AS quantity,
							NULL AS cnt,
							'BIG.PRICE.LAST' AS aggregate
					FROM	trades d
					WHERE	d.batch_id = lr_batches.id
					AND		d.aggregate IS NULL
					GROUP BY	d.batch_id,
								d.request_id,
								d.side_id
				) d;
		
		out_message := out_message || 'Inserted ' || SQL%ROWCOUNT || ' aggregates; ';
		
		COMMIT;
	EXCEPTION
		WHEN eMyError
		THEN
			out_code 	:= 	CASE out_code WHEN 0 THEN -1 ELSE out_code END;
			out_message	:= 	ERRORS_PKG.log_error(
								ERRORS_PKG.add_number('in_batch_id', in_batch_id) || 
								ERRORS_PKG.add_number('out_code', out_code) || 
								ERRORS_PKG.add_varchar2('out_message', out_message)
							);
			
			ROLLBACK;
		WHEN OTHERS
		THEN
			out_code	:= 	-1;
            out_message	:= 	ERRORS_PKG.log_error(
								ERRORS_PKG.add_number('in_batch_id', in_batch_id)
							);

			ROLLBACK;
	END insert_trades;	

END;
/