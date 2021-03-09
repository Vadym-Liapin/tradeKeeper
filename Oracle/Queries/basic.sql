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