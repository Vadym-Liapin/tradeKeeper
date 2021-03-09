CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.symbols
AS
SELECT	id,
		currency_id_base,
		currency_id_quote
FROM	&&SCHEMA.t_symbols;
