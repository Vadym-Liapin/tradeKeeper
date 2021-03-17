CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.requests
AS
SELECT	id,
		parent_id,
		entity_id,
		market_id,
		symbol_id,
		endpoint,
		params,
		active
FROM	&&SCHEMA.t_requests;
