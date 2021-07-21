DECLARE
	out_cursor	sys_refcursor;
	l_batch_ids	varchar2(4000);
BEGIN
    SELECT	MAX(b.id)
	INTO	l_batch_ids
    FROM	&&SCHEMA.batches b;
	
	&&SCHEMA.REPORTS_PKG.set_batch_ids(l_batch_ids);
    
    &&SCHEMA.REPORTS_PKG.set_orders_quantity(50);
    &&SCHEMA.REPORTS_PKG.set_orders_prc(3);
END;
/
/*
SELECT	SYS_CONTEXT('CTX_REPORTS', 'BATCH_IDS') AS batch_ids,
		SYS_CONTEXT('CTX_REPORTS', 'ORDERS_QUANTITY') AS orders_quantity,
		SYS_CONTEXT('CTX_REPORTS', 'ORDERS_PRC') AS orders_prc
FROM 	dual;
*/
/*
SELECT	ta.*
FROM	&&SCHEMA.vw_trades_total ta;
*/

SELECT	ta.batch,
        ta.market,
        ta.side,
        CASE ta.side
            WHEN 'ASK'
            THEN MAX(ta.price) KEEP (DENSE_RANK FIRST ORDER BY ta.price ASC)
            WHEN 'BID'
            THEN MAX(ta.price) KEEP (DENSE_RANK FIRST ORDER BY ta.price DESC)
        END AS price,
        CASE ta.side
            WHEN 'ASK'
            THEN MAX(ta.quantity) KEEP (DENSE_RANK FIRST ORDER BY ta.price ASC)
            WHEN 'BID'
            THEN MAX(ta.quantity) KEEP (DENSE_RANK FIRST ORDER BY ta.price DESC)
        END AS quantity
FROM	&&SCHEMA.vw_orders_total ta
GROUP BY    ta.batch,
            ta.market,
            ta.side
ORDER BY    ta.batch,
            ta.market,
            CASE ta.side WHEN 'ASK' THEN 1 WHEN 'BID' THEN 2 END;