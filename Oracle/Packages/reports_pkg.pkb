CREATE OR REPLACE PACKAGE BODY &&SCHEMA.reports_pkg
IS

	PROCEDURE set_batch_ids (in_batch_ids IN varchar2)
	IS
	BEGIN
		DBMS_SESSION.set_context('CTX_REPORTS', 'BATCH_IDS', in_batch_ids);
	END set_batch_ids;

	PROCEDURE set_orders_quantity (in_orders_quantity IN number)
	IS
	BEGIN
		DBMS_SESSION.set_context('CTX_REPORTS', 'ORDERS_QUANTITY', in_orders_quantity);
	END set_orders_quantity;
	
	PROCEDURE set_orders_prc (in_orders_prc IN number)
	IS
	BEGIN
		DBMS_SESSION.set_context('CTX_REPORTS', 'ORDERS_PRC', in_orders_prc);
	END set_orders_prc;
	
END;
/
