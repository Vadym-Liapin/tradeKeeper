CREATE OR REPLACE PACKAGE BODY &&SCHEMA.utils_pkg
IS

	FUNCTION unix_seconds_to_date (
        in_unix_seconds	IN	number
    ) RETURN date DETERMINISTIC
	IS
		l_date	date;
	BEGIN
		SELECT 	to_date('19700101', 'YYYYMMDD') + ( 1 / 24 / 60 / 60 ) * in_unix_seconds
		INTO	l_date
		FROM 	dual;
		
		RETURN l_date;
	END unix_seconds_to_date;

	FUNCTION unix_milliseconds_to_date (
        in_unix_milliseconds	IN	number
    ) RETURN date DETERMINISTIC
	IS
		l_date	date;
	BEGIN
		SELECT 	to_date('19700101', 'YYYYMMDD') + ( 1 / 24 / 60 / 60 / 1000) * in_unix_milliseconds
		INTO	l_date
		FROM 	dual;
		
		RETURN l_date;
	END unix_milliseconds_to_date;

	FUNCTION date_to_unix_seconds (
        in_date	IN	date
    ) RETURN number DETERMINISTIC
	IS
		l_unix_seconds	number;
	BEGIN
		SELECT 	ROUND((in_date - to_date('19700101', 'YYYYMMDD')) * 24 * 60 * 60)
		INTO	l_unix_seconds
		FROM 	dual;
		
		RETURN l_unix_seconds;
	END date_to_unix_seconds;

	FUNCTION date_to_unix_milliseconds (
        in_date	IN	date
    ) RETURN number DETERMINISTIC
	IS
		l_unix_milliseconds	number;
	BEGIN
		SELECT 	ROUND((in_date - to_date('19700101', 'YYYYMMDD')) * 24 * 60 * 60 * 1000)
		INTO	l_unix_milliseconds
		FROM 	dual;
		
		RETURN l_unix_milliseconds;
	END date_to_unix_milliseconds;

	PROCEDURE init_out_params (
        out_code	OUT	number,
		out_message	OUT	varchar2
    )
	IS
	BEGIN
		out_code	:= 0;
		out_message	:= 'OK';
	END init_out_params;
	
END;
/
