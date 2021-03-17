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
AND		o.quantity >= 30
AND		o.price BETWEEN 30000 AND 70000
ORDER BY	CASE o.side_id WHEN 2 THEN 1 WHEN 1 THEN 2 END,
    		- o.price;

SELECT	d.batch,
		d.market,
		d.symbol,
		d.side,
		d.BIG_quantity,
		MAX(CASE WHEN d.aggregate = 'ALL.QUANTITY.SUM' THEN d.quantity ELSE NULL END) AS ALL_quantity_SUM,
        MAX(CASE WHEN d.aggregate = 'BIG.QUANTITY.SUM' THEN d.quantity ELSE NULL END) AS BIG_quantity_SUM,
        MAX(CASE WHEN d.aggregate = 'BIG.QUANTITY.SUM' THEN d.cnt ELSE NULL END) AS BIG_quantity_CNT,    
		MAX(CASE WHEN d.aggregate = 'ALL.PRICE.FIRST' THEN d.price ELSE NULL END) AS ALL_price_FIRST,
        MAX(CASE WHEN d.aggregate = 'ALL.PRICE.LAST' THEN d.price ELSE NULL END) AS ALL_price_LAST,
        MAX(CASE WHEN d.aggregate = 'ALL.PRICE.MIN' THEN d.price ELSE NULL END) AS ALL_price_MIN,
        MAX(CASE WHEN d.aggregate = 'ALL.PRICE.MAX' THEN d.price ELSE NULL END) AS ALL_price_MAX,
		MAX(CASE WHEN d.aggregate = 'BIG.PRICE.FIRST' THEN d.price ELSE NULL END) AS BIG_price_FIRST,
        MAX(CASE WHEN d.aggregate = 'BIG.PRICE.LAST' THEN d.price ELSE NULL END) AS BIG_price_LAST,
        MAX(CASE WHEN d.aggregate = 'BIG.PRICE.MIN' THEN d.price ELSE NULL END) AS BIG_price_MIN,
        MAX(CASE WHEN d.aggregate = 'BIG.PRICE.MAX' THEN d.price ELSE NULL END) AS BIG_price_MAX
FROM	(
            SELECT	to_char(b.created, 'dd.mm.yyyy hh24:mi:ss') AS batch,
                    m.code AS market,
                    sm.code AS symbol,
                    s.code AS side,
    				CASE
                        WHEN bs.quantity_base IS NOT NULL
                        THEN bs.quantity_base || ' ' || sm.currency_code_base
                        WHEN bs.quantity_quote IS NOT NULL
                        THEN bs.quantity_quote || ' ' || sm.currency_code_quote
                    END AS BIG_quantity,
                    t.price,
                    t.quantity,
                    t.cnt,
                    t.aggregate
            FROM	&&SCHEMA.trades t	INNER JOIN &&SCHEMA.sides s
                                        ON	s.id = t.side_id
                                        INNER JOIN &&SCHEMA.requests r
                                        ON	r.id = t.request_id
    									INNER JOIN &&SCHEMA.big_sets bs
    									ON	bs.symbol_id = r.symbol_id
										AND	bs.entity_id = r.entity_id
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
GROUP BY	d.batch,
			d.market,
			d.symbol,
            d.side,
            d.BIG_quantity
ORDER BY	d.market,
			d.symbol,
            d.side;