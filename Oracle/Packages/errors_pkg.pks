CREATE OR REPLACE PACKAGE &&SCHEMA.errors_pkg
IS

	FUNCTION log_error (
        in_params	IN	varchar2
    ) RETURN varchar2;
	
END;
/
