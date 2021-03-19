CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.errors 
AS
SELECT	id,
		ext_details,
		ora_details,
		format_call_stack,
		format_error_stack,
		format_error_backtrace,
		who_called_me,
		userenv,
		created
FROM	&&SCHEMA.t_errors;
