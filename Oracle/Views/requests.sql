CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.requests
AS
SELECT	id,
		entity_id,
		market_id,
		symbol_id,
		endpoint,
		active,
		min_quantity
FROM	&&SCHEMA.t_requests;
