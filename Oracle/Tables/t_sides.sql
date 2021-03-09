CREATE TABLE &&SCHEMA.t_sides (
    id			number,
	code		varchar2(10)	CONSTRAINT t_sides_code_nn		NOT NULL,
	entity_id	number			CONSTRAINT t_sides_entity_id_nn	NOT NULL,
    CONSTRAINT t_sides_pk			PRIMARY KEY (id),
	CONSTRAINT t_sides_uniq			UNIQUE (code),
	CONSTRAINT t_sides_entity_id_fk	FOREIGN KEY (entity_id) REFERENCES &&SCHEMA.t_entities (id)
);

COMMENT ON TABLE &&SCHEMA.t_sides IS 'Sides';

COMMENT ON COLUMN &&SCHEMA.t_sides.id   		IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_sides.code			IS 'Side Code';
COMMENT ON COLUMN &&SCHEMA.t_sides.entity_id	IS 'Entity ID';

TRUNCATE TABLE &&SCHEMA.t_sides;
INSERT INTO &&SCHEMA.t_sides (id, code, entity_id)
SELECT	1 AS id,	'BID' 	AS code,	1 AS entity_id	FROM dual 	UNION ALL
SELECT	2 AS id,	'ASK' 	AS code,	1 AS entity_id	FROM dual	UNION ALL
SELECT	3 AS id,	'BUY' 	AS code,	2 AS entity_id	FROM dual 	UNION ALL
SELECT	4 AS id,	'SELL' 	AS code,	2 AS entity_id	FROM dual
;

COMMIT;