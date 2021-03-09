CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.sides
AS
SELECT	id,
		code,
		entity_id
FROM	&&SCHEMA.t_sides;
