CREATE OR REPLACE PACKAGE &&SCHEMA.reports_pkg
IS

	PROCEDURE set_batch_ids (in_batch_ids IN varchar2);
	
	PROCEDURE set_orders_quantity (in_orders_quantity IN number);
	PROCEDURE set_orders_prc (in_orders_prc IN number);
	
END;
/
