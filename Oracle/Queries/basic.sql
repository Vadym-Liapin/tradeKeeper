SELECT	to_char(b.created, 'dd.mm.yyyy hh24:mi:ss') AS batch,
		m.code AS market,
		s.code AS side,
		o.price,
		o.quantity,
		o.quantity_CUM
FROM	&&SCHEMA.orders o	INNER JOIN &&SCHEMA.sides s
								ON	s.id = o.side_id
								INNER JOIN &&SCHEMA.requests r
								ON	r.id = o.request_id
								INNER JOIN &&SCHEMA.markets m
								ON	m.id = r.market_id
								INNER JOIN &&SCHEMA.batches b
								ON	b.id = o.batch_id
AND		o.batch_id = (
    		SELECT	MAX(b.id)
    		FROM	&&SCHEMA.batches b
    	)
AND		o.quantity >= 50
AND		o.price BETWEEN 30000 AND 70000
ORDER BY	CASE o.side_id WHEN 2 THEN 1 WHEN 1 THEN 2 END,
    		- o.price;

SELECT	to_char(b.created, 'dd.mm.yyyy hh24:mi:ss') AS batch,
		m.code AS market,
		s.code AS side,
		t.trade_id,
		to_char(t.created, 'dd.mm.yyyy hh24:mi:ss') AS created,
		t.price,
		t.quantity
FROM	&&SCHEMA.trades t		INNER JOIN &&SCHEMA.sides s
								ON	s.id = t.side_id
								INNER JOIN &&SCHEMA.requests r
								ON	r.id = t.request_id
								INNER JOIN &&SCHEMA.markets m
								ON	m.id = r.market_id
								INNER JOIN &&SCHEMA.batches b
								ON	b.id = t.batch_id
AND		t.batch_id = (
    		SELECT	MAX(b.id)
    		FROM	&&SCHEMA.batches b
    	)
AND		(
			t.quantity >= 1
			OR
			t.trade_id IS NULL
		)
ORDER BY	t.side_id,
			t.created DESC;

SELECT	to_char(b.created, 'dd.mm.yyyy hh24:mi:ss') AS batch,
		m.code AS market,
		sm.code AS symbol,
		s.code AS side,
		t.quantity,
		t.aggregate
FROM	&&SCHEMA.trades t		INNER JOIN &&SCHEMA.sides s
								ON	s.id = t.side_id
								INNER JOIN &&SCHEMA.requests r
								ON	r.id = t.request_id
								INNER JOIN &&SCHEMA.markets m
								ON	m.id = r.market_id
								INNER JOIN &&SCHEMA.batches b
								ON	b.id = t.batch_id
								INNER JOIN &&SCHEMA.vw_symbols sm
								ON	sm.id = r.symbol_id
AND		t.batch_id = (
    		SELECT	MAX(b.id)
    		FROM	&&SCHEMA.batches b
    	)
AND		(
			/*t.quantity >= 1
			OR*/
			t.aggregate = 'SUM.QUANTITY'
		)
ORDER BY	t.aggregate,
			m.code,
			s.code,
			sm.code;

SELECT	d.timestamp,
		d.market,
		d.symbol,
		d.side,
		d.quantity_BIG,
		MAX(CASE WHEN d.aggregate = 'SUM.QUANTITY.ALL' THEN d.quantity ELSE NULL END) AS quantity_ALL_TOTAL,
        MAX(CASE WHEN d.aggregate = 'SUM.QUANTITY.BIG' THEN d.quantity ELSE NULL END) AS quantity_BIG_TOTAL,
		MAX(CASE WHEN d.aggregate = 'FIRST.PRICE.ALL' THEN d.price ELSE NULL END) AS price_ALL_FIRST,
        MAX(CASE WHEN d.aggregate = 'LAST.PRICE.ALL' THEN d.price ELSE NULL END) AS price_ALL_LAST,
        MAX(CASE WHEN d.aggregate = 'MIN.PRICE.ALL' THEN d.price ELSE NULL END) AS price_ALL_MIN,
        MAX(CASE WHEN d.aggregate = 'MAX.PRICE.ALL' THEN d.price ELSE NULL END) AS price_ALL_MAX,
		MAX(CASE WHEN d.aggregate = 'FIRST.PRICE.BIG' THEN d.price ELSE NULL END) AS price_BIG_FIRST,
        MAX(CASE WHEN d.aggregate = 'LAST.PRICE.BIG' THEN d.price ELSE NULL END) AS price_BIG_LAST,
        MAX(CASE WHEN d.aggregate = 'MIN.PRICE.BIG' THEN d.price ELSE NULL END) AS price_BIG_MIN,
        MAX(CASE WHEN d.aggregate = 'MAX.PRICE.BIG' THEN d.price ELSE NULL END) AS price_BIG_MAX
FROM	(
            SELECT	to_char(b.created, 'dd.mm.yyyy hh24:mi:ss') AS timestamp,
                    m.code AS market,
                    sm.code AS symbol,
                    s.code AS side,
    				r.min_quantity AS quantity_BIG,
                    t.price,
                    t.quantity,
                    t.aggregate
            FROM	&&SCHEMA.trades t		INNER JOIN &&SCHEMA.sides s
                                            ON	s.id = t.side_id
                                            INNER JOIN &&SCHEMA.requests r
                                            ON	r.id = t.request_id
                                            INNER JOIN &&SCHEMA.markets m
                                            ON	m.id = r.market_id
                                            INNER JOIN &&SCHEMA.batches b
                                            ON	b.id = t.batch_id
                                            INNER JOIN &&SCHEMA.vw_symbols sm
                                            ON	sm.id = r.symbol_id
            AND		t.batch_id = (
                        SELECT	MAX(b.id)
                        FROM	&&SCHEMA.batches b
                    )
            AND		t.aggregate IS NOT NULL
   		) d
GROUP BY	d.timestamp,
			d.market,
			d.symbol,
            d.side,
            d.quantity_BIG
ORDER BY	d.market,
			d.symbol,
            d.side;
			