CREATE OR REPLACE PACKAGE BODY &&SCHEMA.errors_pkg
IS

    FUNCTION log_error (
        in_params	IN	varchar2
    ) RETURN varchar2
	IS
		PRAGMA AUTONOMOUS_TRANSACTION;
		
		lr_errors	errors%rowtype;
	BEGIN
		lr_errors.id						:= SQN_errors.NEXTVAL;
		lr_errors.sqlcode					:= SQLCODE;
		lr_errors.sqlerrm					:= SQLERRM;
		lr_errors.format_call_stack			:= DBMS_UTILITY.format_call_stack();
		lr_errors.format_error_stack		:= DBMS_UTILITY.format_error_stack();
		lr_errors.format_error_backtrace	:= DBMS_UTILITY.format_error_backtrace();
		
        OWA_UTIL.WHO_CALLED_ME(
			owner 		=> lr_errors.who_called_me_owner,
            name 		=> lr_errors.who_called_me_name,
            lineno 		=> lr_errors.who_called_me_lineno,
            caller_t 	=> lr_errors.who_called_me_caller_t
		);
	
		lr_errors.module				:= SYS_CONTEXT('USERENV', 'MODULE');
		lr_errors.action				:= SYS_CONTEXT('USERENV', 'ACTION');
		lr_errors.client_info			:= SYS_CONTEXT('USERENV', 'CLIENT_INFO');
		lr_errors.current_schema		:= SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');
		lr_errors.current_user			:= SYS_CONTEXT('USERENV', 'CURRENT_USER');
		lr_errors.session_user			:= SYS_CONTEXT('USERENV', 'SESSION_USER');
		lr_errors.os_user				:= SYS_CONTEXT('USERENV', 'OS_USER');
		lr_errors.host					:= SYS_CONTEXT('USERENV', 'HOST');
		lr_errors.ip_address			:= SYS_CONTEXT('USERENV', 'IP_ADDRESS');
		lr_errors.language				:= SYS_CONTEXT('USERENV', 'LANGUAGE');
		lr_errors.current_edition_name	:= SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME');
		
		lr_errors.params	:= in_params;
		lr_errors.created	:= SYSDATE;
		
		INSERT INTO errors VALUES lr_errors;
		
		COMMIT;
		
		RETURN 'Sorry, technical error occurred. Please contact us providing the following error ID: ' || lr_errors.id;
	EXCEPTION
		WHEN OTHERS
		THEN
            lr_errors.id		:= SQN_errors.NEXTVAL;
            lr_errors.sqlcode	:= SQLCODE;
            lr_errors.sqlerrm	:= SQLERRM;
            lr_errors.created	:= SYSDATE;

            INSERT INTO errors VALUES lr_errors;

            COMMIT;
            
            RETURN 'Sorry, technical error occurred. Please contact us providing the following error ID: ' || lr_errors.id;
	END log_error;

END;
/
