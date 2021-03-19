CREATE OR REPLACE PACKAGE BODY &&SCHEMA.errors_pkg
IS

	FUNCTION add_varchar2 (
		in_key		IN	varchar2,
		in_value	IN	varchar2
	) RETURN varchar2
	IS
	BEGIN
		RETURN '"' || in_key || '":"' || NVL(in_value, 'null') || '",';
	END add_varchar2;
	
	FUNCTION add_number (
		in_key		IN	varchar2,
		in_value	IN	number
	) RETURN varchar2
	IS
	BEGIN
		RETURN '"' || in_key || '":"' || NVL(to_char(in_value), 'null') || '",';
	END add_number;

    FUNCTION log_error (
        in_ext_details	IN	varchar2
    ) RETURN varchar2
	IS
		PRAGMA AUTONOMOUS_TRANSACTION;
		
		lr_errors	errors%rowtype;

		l_who_called_me_owner		varchar2(255);
        l_who_called_me_name		varchar2(255);
        l_who_called_me_lineno		varchar2(255);
        l_who_called_me_caller_t	varchar2(255);
	BEGIN
		lr_errors.id						:= 	SQN_errors.NEXTVAL;
		lr_errors.ext_details				:= 	'{' || REGEXP_REPLACE(in_ext_details, ',$', '') || '}';
		lr_errors.ora_details				:= 	'{' || 
												REGEXP_REPLACE(
													add_number('sqlcode', SQLCODE) ||
													add_varchar2('sqlerrm', SQLERRM),
													',$', ''
												) || 
												'}';

		lr_errors.format_call_stack			:= DBMS_UTILITY.format_call_stack();
		lr_errors.format_error_stack		:= DBMS_UTILITY.format_error_stack();
		lr_errors.format_error_backtrace	:= DBMS_UTILITY.format_error_backtrace();
		lr_errors.created					:= SYSDATE;
		
        OWA_UTIL.WHO_CALLED_ME(
			owner 		=> l_who_called_me_owner,
            name 		=> l_who_called_me_name,
            lineno 		=> l_who_called_me_lineno,
            caller_t 	=> l_who_called_me_caller_t
		);

		lr_errors.who_called_me	:=	'{' || 
									REGEXP_REPLACE(
										add_varchar2('owner', l_who_called_me_owner) ||
										add_varchar2('name', l_who_called_me_name) ||
										add_varchar2('lineno', l_who_called_me_lineno) ||
										add_varchar2('caller_t', l_who_called_me_caller_t),
										',$', ''
									) ||
									'}';
		
		lr_errors.userenv	:= 	'{' ||
								REGEXP_REPLACE(
									add_varchar2('module', SYS_CONTEXT('USERENV', 'MODULE')) ||
									add_varchar2('action', SYS_CONTEXT('USERENV', 'ACTION')) ||
									add_varchar2('client_info', SYS_CONTEXT('USERENV', 'CLIENT_INFO')) ||
									add_varchar2('current_schema', SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')) ||
									add_varchar2('current_user', SYS_CONTEXT('USERENV', 'CURRENT_USER')) ||
									add_varchar2('session_user', SYS_CONTEXT('USERENV', 'SESSION_USER')) ||
									add_varchar2('os_user', SYS_CONTEXT('USERENV', 'OS_USER')) ||
									add_varchar2('host', SYS_CONTEXT('USERENV', 'HOST')) ||
									add_varchar2('ip_address', SYS_CONTEXT('USERENV', 'IP_ADDRESS')) ||
									add_varchar2('language', SYS_CONTEXT('USERENV', 'LANGUAGE')) ||
									add_varchar2('current_edition_name', SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME')),
									',$', ''
								) ||
								'}';
		
		INSERT INTO errors VALUES lr_errors;
		
		COMMIT;
		
		RETURN 'Sorry, technical error occurred. Please contact us providing the following error ID: ' || lr_errors.id;
	EXCEPTION
		WHEN OTHERS
		THEN
            lr_errors.id		:= SQN_errors.NEXTVAL;
            lr_errors.created	:= SYSDATE;
			
			lr_errors.ora_details 	:=	'{' || 
											REGEXP_REPLACE(
												add_number('sqlcode', SQLCODE) ||
												add_varchar2('sqlerrm', SQLERRM),
												',$', ''
											) || 
										'}';			

            INSERT INTO errors VALUES lr_errors;

            COMMIT;
            
            RETURN 'Sorry, technical error occurred. Please contact us providing the following error ID: ' || lr_errors.id;
	END log_error;

END;
/
