CREATE TABLE &&SCHEMA.t_batches (
    id			number,
	created		date	CONSTRAINT t_batches_created_nn		NOT NULL,
	ds			date	CONSTRAINT t_batches_ds_nn			NOT NULL,
	df			date	CONSTRAINT t_batches_df_nn			NOT NULL,
	ds_unix_s	number	CONSTRAINT t_batches_ds_unix_s_nn	NOT NULL,
	df_unix_s	number	CONSTRAINT t_batches_df_unix_s_nn	NOT NULL,
	ds_unix_ms	number	CONSTRAINT t_batches_ds_unix_ms_nn	NOT NULL,
	df_unix_ms	number	CONSTRAINT t_batches_df_unix_ms_nn	NOT NULL,
    CONSTRAINT t_batches_pk		PRIMARY KEY (id),
	CONSTRAINT t_batches_uniq	UNIQUE (created)
)
PARTITION BY RANGE (created)
INTERVAL (NUMTODSINTERVAL(1, 'DAY'))
(
    PARTITION p_t_batches_init VALUES LESS THAN (to_date('01.01.2021', 'dd.mm.yyyy'))
);

COMMENT ON TABLE &&SCHEMA.t_batches IS 'Batches';

COMMENT ON COLUMN &&SCHEMA.t_batches.id   		IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_batches.created	IS 'Created Date';
COMMENT ON COLUMN &&SCHEMA.t_batches.ds			IS 'Period Start Date';
COMMENT ON COLUMN &&SCHEMA.t_batches.df			IS 'Period End Date';
COMMENT ON COLUMN &&SCHEMA.t_batches.ds_unix_s	IS 'Period Start Date (in Unix Seconds)';
COMMENT ON COLUMN &&SCHEMA.t_batches.df_unix_s	IS 'Period End Date (in Unix Seconds)';
COMMENT ON COLUMN &&SCHEMA.t_batches.ds_unix_ms	IS 'Period Start Date (in Unix Milliseconds)';
COMMENT ON COLUMN &&SCHEMA.t_batches.df_unix_ms	IS 'Period End Date (in Unix Milliseconds)';


