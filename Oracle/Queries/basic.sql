DECLARE
	out_cursor	sys_refcursor;
	l_batch_ids	varchar2(4000);
BEGIN
    SELECT	MAX(b.id)
	INTO	l_batch_ids
    FROM	&&SCHEMA.batches b;
	
	&&SCHEMA.REPORTS_PKG.set_batch_ids(l_batch_ids);
    
    &&SCHEMA.REPORTS_PKG.set_orders_quantity(50);
    &&SCHEMA.REPORTS_PKG.set_orders_prc(6);
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
/*
SELECT	ta.*
FROM	&&SCHEMA.vw_orders_total ta;
*/