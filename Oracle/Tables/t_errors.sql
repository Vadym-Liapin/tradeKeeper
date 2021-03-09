CREATE TABLE &&SCHEMA.t_errors (
    id              		number,
	sqlcode					number,
	sqlerrm					varchar2(512),
	format_call_stack		varchar2(2000),
	format_error_stack		varchar2(2000),
	format_error_backtrace	varchar2(4000),
	who_called_me_owner		varchar2(128),
	who_called_me_name		varchar2(256),
	who_called_me_lineno	number,
	who_called_me_caller_t	varchar2(30),
	module					varchar2(64),
	action					varchar2(64),
	client_info				varchar2(64),
	current_schema			varchar2(128),
	current_user			varchar2(128),
	session_user			varchar2(128),
	os_user					varchar2(128),
	host					varchar2(128),
	ip_address				varchar2(255),
	language				varchar2(255),
	current_edition_name	varchar2(128),
	params					varchar2(4000),
    created         		date    		CONSTRAINT t_errors_created_nn	NOT NULL,
    CONSTRAINT t_errors_pk	PRIMARY KEY (id)
);

COMMENT ON TABLE &&SCHEMA.t_errors IS 'Error Details';

COMMENT ON COLUMN &&SCHEMA.t_errors.id       				IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_errors.sqlcode  				IS 'SQLCODE';
COMMENT ON COLUMN &&SCHEMA.t_errors.sqlerrm  				IS 'SQLERRM';
COMMENT ON COLUMN &&SCHEMA.t_errors.format_call_stack  		IS 'DBMS_UTILITY.format_call_stack';
COMMENT ON COLUMN &&SCHEMA.t_errors.format_error_stack  	IS 'DBMS_UTILITY.format_error_stack';
COMMENT ON COLUMN &&SCHEMA.t_errors.format_error_backtrace	IS 'DBMS_UTILITY.format_error_backtrace';
COMMENT ON COLUMN &&SCHEMA.t_errors.who_called_me_owner		IS 'OWA_UTIL.WHO_CALLED_ME.owner';
COMMENT ON COLUMN &&SCHEMA.t_errors.who_called_me_name		IS 'OWA_UTIL.WHO_CALLED_ME.name';
COMMENT ON COLUMN &&SCHEMA.t_errors.who_called_me_lineno	IS 'OWA_UTIL.WHO_CALLED_ME.lineno';
COMMENT ON COLUMN &&SCHEMA.t_errors.who_called_me_caller_t	IS 'OWA_UTIL.WHO_CALLED_ME.caller_t';
COMMENT ON COLUMN &&SCHEMA.t_errors.module  				IS 'USERENV.module';
COMMENT ON COLUMN &&SCHEMA.t_errors.action  				IS 'USERENV.action';
COMMENT ON COLUMN &&SCHEMA.t_errors.client_info  			IS 'USERENV.client_info';
COMMENT ON COLUMN &&SCHEMA.t_errors.current_schema  		IS 'USERENV.current_schema';
COMMENT ON COLUMN &&SCHEMA.t_errors.current_user  			IS 'USERENV.current_user';
COMMENT ON COLUMN &&SCHEMA.t_errors.session_user  			IS 'USERENV.session_user';
COMMENT ON COLUMN &&SCHEMA.t_errors.os_user  				IS 'USERENV.os_user';
COMMENT ON COLUMN &&SCHEMA.t_errors.host  					IS 'USERENV.host';
COMMENT ON COLUMN &&SCHEMA.t_errors.ip_address  			IS 'USERENV.ip_address';
COMMENT ON COLUMN &&SCHEMA.t_errors.language  				IS 'USERENV.language';
COMMENT ON COLUMN &&SCHEMA.t_errors.current_edition_name  	IS 'USERENV.current_edition_name';
COMMENT ON COLUMN &&SCHEMA.t_errors.params  				IS 'Other Parameters';
COMMENT ON COLUMN &&SCHEMA.t_errors.created					IS 'Created Date';
