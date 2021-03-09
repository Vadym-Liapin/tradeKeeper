CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.trades
AS
SELECT	id,
		batch_id,
		request_id,
		side_id,
		trade_id,
		created,
		price,
		quantity
FROM	&&SCHEMA.t_trades;
