CREATE OR REPLACE PACKAGE &&SCHEMA.errors_pkg
IS

	FUNCTION add_varchar2 (
		in_key		IN	varchar2,
		in_value	IN	varchar2
	) RETURN varchar2;

	FUNCTION add_number (
		in_key		IN	varchar2,
		in_value	IN	number
	) RETURN varchar2;

	FUNCTION log_error (
        in_ext_details	IN	varchar2
    ) RETURN varchar2;
	
END;
/
