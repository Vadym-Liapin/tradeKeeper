CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.big_sets
AS
SELECT	id,
		symbol_id,
		entity_id,
		quantity_base,
		quantity_quote
FROM	&&SCHEMA.t_big_sets;
