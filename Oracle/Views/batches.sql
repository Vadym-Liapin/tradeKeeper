CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.batches
AS
SELECT	id,
		created,
		ds_unix_s,
		df_unix_s,
		ds_unix_ms,
		df_unix_ms
FROM	&&SCHEMA.t_batches;
