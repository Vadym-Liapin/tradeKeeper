CREATE USER &&SCHEMA
	IDENTIFIED BY &&PASSWORD
	ENABLE EDITIONS
	ACCOUNT UNLOCK
	QUOTA 10240M ON DATA;

GRANT CREATE SESSION TO &&SCHEMA;
