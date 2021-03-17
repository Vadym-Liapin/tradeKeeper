CREATE OR REPLACE VIEW &&SCHEMA.vw_symbols
AS
SELECT	s.id,
		cb.code || '/' || cq.code AS code,
		cb.code AS currency_code_base,
		cq.code AS currency_code_quote
FROM	&&SCHEMA.symbols s	INNER JOIN &&SCHEMA.currencies cb
								ON	cb.id = s.currency_id_base
								INNER JOIN &&SCHEMA.currencies cq
								ON	cq.id = s.currency_id_quote;
