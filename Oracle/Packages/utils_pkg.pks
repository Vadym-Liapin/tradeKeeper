CREATE OR REPLACE PACKAGE &&SCHEMA.utils_pkg
IS

	FUNCTION unix_seconds_to_date (
        in_unix_seconds	IN	number
    ) RETURN date DETERMINISTIC;

	FUNCTION unix_milliseconds_to_date (
        in_unix_milliseconds	IN	number
    ) RETURN date DETERMINISTIC;

	FUNCTION date_to_unix_seconds (
        in_date	IN	date
    ) RETURN number DETERMINISTIC;

	FUNCTION date_to_unix_milliseconds (
        in_date	IN	date
    ) RETURN number DETERMINISTIC;

	PROCEDURE init_out_params (
        out_code	OUT	number,
		out_message	OUT	varchar2
    );

	FUNCTION string_to_table (
		in_string		IN	varchar2,
		in_separator	IN	varchar2 DEFAULT ','
	) RETURN tt_values;
END;
/
