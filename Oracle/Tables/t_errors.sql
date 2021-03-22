CREATE TABLE &&SCHEMA.t_errors (
    id              		number,
	ext_details				varchar2(4000),
	ora_details				varchar2(1000),
	format_call_stack		varchar2(2000),
	format_error_stack		varchar2(2000),
	format_error_backtrace	varchar2(4000),
	who_called_me			varchar2(4000),
	userenv					varchar2(4000),
    created         		date    		CONSTRAINT t_errors_created_nn	NOT NULL,
    CONSTRAINT t_errors_pk			PRIMARY KEY (id),
	CONSTRAINT t_ext_details_chk	CHECK (ext_details IS JSON),
	CONSTRAINT t_ora_details_chk	CHECK (ora_details IS JSON),
	CONSTRAINT t_who_called_me_chk	CHECK (who_called_me IS JSON),
	CONSTRAINT t_userenv_chk		CHECK (userenv IS JSON)	
);

COMMENT ON TABLE &&SCHEMA.t_errors IS 'Error Details';

COMMENT ON COLUMN &&SCHEMA.t_errors.id       				IS 'PK';
COMMENT ON COLUMN &&SCHEMA.t_errors.ext_details  			IS 'External Details (JSON)';
COMMENT ON COLUMN &&SCHEMA.t_errors.ora_details  			IS 'Oracle Error Details (JSON)';
COMMENT ON COLUMN &&SCHEMA.t_errors.format_call_stack  		IS 'DBMS_UTILITY.format_call_stack';
COMMENT ON COLUMN &&SCHEMA.t_errors.format_error_stack  	IS 'DBMS_UTILITY.format_error_stack';
COMMENT ON COLUMN &&SCHEMA.t_errors.format_error_backtrace	IS 'DBMS_UTILITY.format_error_backtrace';
COMMENT ON COLUMN &&SCHEMA.t_errors.who_called_me			IS 'OWA_UTIL.WHO_CALLED_ME (JSON)';
COMMENT ON COLUMN &&SCHEMA.t_errors.userenv  				IS 'USERENV (JSON)';
COMMENT ON COLUMN &&SCHEMA.t_errors.created					IS 'Created Date';
