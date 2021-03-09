CREATE TABLE &&SCHEMA.t_entities (
    id		number,
	code	varchar2(50)	CONSTRAINT t_entities_code_nn	NOT NULL,
    CONSTRAINT t_entities_pk	PRIMARY KEY (id),
	CONSTRAINT t_entities_uniq	UNIQUE (code)
);

COMMENT ON TABLE &&SCHEMA.t_entities IS 'Entities';

COMMENT ON COLUMN &&SCHEMA.t_entities.id    IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_entities.code	IS 'Entity Code';

TRUNCATE TABLE &&SCHEMA.t_entities;
INSERT INTO &&SCHEMA.t_entities (id, code)
SELECT	1 AS id,	'orders' AS code	FROM dual	UNION ALL
SELECT	2 AS id,	'trades' AS code	FROM dual;

COMMIT;