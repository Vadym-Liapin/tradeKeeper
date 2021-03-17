CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.batches
AS
SELECT	id,
		created,
		ds,
		df,
		ds_unix_s,
		df_unix_s,
		ds_unix_ms,
		df_unix_ms,
		ds_ISO8601,
		df_ISO8601
FROM	&&SCHEMA.t_batches;
