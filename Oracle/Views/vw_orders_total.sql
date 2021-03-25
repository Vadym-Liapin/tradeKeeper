CREATE OR REPLACE VIEW &&SCHEMA.vw_orders_total
AS
SELECT	d.batch,
		d.market,
		d.side,
		d.price,
		d.quantity,
		d.quantity_CUM,
		d.prc
FROM	(
            SELECT	d.batch,
                    d.market,
                    d.side,
                    d.price,
                    d.quantity,
                    d.quantity_CUM,
                    d.price_BID_MAX,
                    d.price_ASK_MIN,
                    ROUND(ABS(
                        100 - 
                        CASE d.side
                           WHEN 'BID'
                           THEN d.price * 100 / price_BID_MAX
                           WHEN 'ASK'
                           THEN d.price * 100 / price_ASK_MIN
                        END
                    ), 2) AS prc
            FROM	(
                        SELECT	to_char(b.created, 'dd.mm.yyyy hh24:mi:ss') AS batch,
                                m.code AS market,
                                s.code AS side,
                                o.price,
                                o.quantity,
                                o.quantity_CUM,
                                MAX(CASE s.code WHEN 'BID' THEN o.price END) OVER() AS price_BID_MAX,
                                MIN(CASE s.code WHEN 'ASK' THEN o.price END) OVER() AS price_ASK_MIN
                        FROM	&&SCHEMA.orders o	INNER JOIN &&SCHEMA.sides s
                                                    ON	s.id = o.side_id
                                                    INNER JOIN &&SCHEMA.requests r
                                                    ON	r.id = o.request_id
                                                    INNER JOIN &&SCHEMA.markets m
                                                    ON	m.id = r.market_id
                                                    INNER JOIN &&SCHEMA.batches b
                                                    ON	b.id = o.batch_id
                        AND		o.batch_id IN (
									SELECT	column_value
									FROM	TABLE(&&SCHEMA.UTILS_PKG.string_to_table(SYS_CONTEXT('CTX_REPORTS', 'BATCH_IDS')))
								)
                        AND		o.quantity >= SYS_CONTEXT('CTX_REPORTS', 'ORDERS_QUANTITY')
                    ) d
      	) d
WHERE	d.prc <= SYS_CONTEXT('CTX_REPORTS', 'ORDERS_PRC')
ORDER BY	CASE d.side WHEN 'ASK' THEN 1 WHEN 'BID' THEN 2 END,
    		- d.price;
