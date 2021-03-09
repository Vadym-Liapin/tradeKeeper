CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.orders
AS
SELECT	id,
		batch_id,
		request_id,
		side_id,
		price,
		quantity,
		quantity_CUM
FROM	&&SCHEMA.t_orders;
