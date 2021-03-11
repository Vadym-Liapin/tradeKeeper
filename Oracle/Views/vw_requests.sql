CREATE OR REPLACE VIEW &&SCHEMA.vw_requests
AS
SELECT	r.id,
		r.parent_id,
		e.code AS entity,
		m.code AS market,
		s.code AS symbol,
		r.endpoint,
		r.params,
		r.active
FROM	&&SCHEMA.requests r	INNER JOIN &&SCHEMA.entities e
								ON	e.id = r.entity_id
								INNER JOIN &&SCHEMA.markets m
								ON	m.id = r.market_id
								INNER JOIN &&SCHEMA.vw_symbols s
								ON	s.id = r.symbol_id;
