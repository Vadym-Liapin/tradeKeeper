CREATE OR REPLACE EDITIONING VIEW &&SCHEMA.errors 
AS
SELECT	id,
		sqlcode,
		sqlerrm,
		format_call_stack,
		format_error_stack,
		format_error_backtrace,
		who_called_me_owner,
		who_called_me_name,
		who_called_me_lineno,
		who_called_me_caller_t,
		module,
		action,
		client_info,
		current_schema,
		current_user,
		session_user,
		os_user,
		host,
		ip_address,
		language,
		current_edition_name,
		params,
		created
FROM	&&SCHEMA.t_errors;
