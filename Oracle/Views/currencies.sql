CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.currencies
AS
SELECT	id,
		code,
		name
FROM	&&SCHEMA.t_currencies;
