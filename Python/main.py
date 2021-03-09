import cx_Oracle
import os
import configparser
import requests
import json
import logging

def connect():
	config = configparser.ConfigParser()
	config.read('config.ini')
	
	connection = cx_Oracle.connect(config['DATABASE']['username'], config['DATABASE']['password'], dsn=config['DATABASE']['dsn'])
	return connection
	
if __name__ == '__main__':
	errorLogger = logging.getLogger('error')
	errorLogger.setLevel(logging.ERROR)
	errorHandler = logging.FileHandler('error.log')
	errorFormatter = logging.Formatter('%(asctime)s %(filename)s: %(message)s', '%d.%m.%Y %H:%M:%S')
	errorHandler.setFormatter(errorFormatter)
	errorLogger.addHandler(errorHandler)

	debugLogger = logging.getLogger('debug')
	debugLogger.setLevel(logging.DEBUG)
	debugHandler = logging.FileHandler('debug.log')
	debugFormatter = logging.Formatter('%(asctime)s %(filename)s: %(message)s', '%d.%m.%Y %H:%M:%S')
	debugHandler.setFormatter(debugFormatter)
	debugLogger.addHandler(debugHandler)

	os.environ["TNS_ADMIN"] = os.environ["HOME"]
	connection = connect()
	
	cursor = connection.cursor()
	in_batch_id = cursor.var(cx_Oracle.NUMBER)
	cursor.callfunc('MARKETS_PKG.create_batch', in_batch_id, [])
	cursor.close()

	cursor = connection.cursor()
	out_cursor = cursor.var(cx_Oracle.CURSOR)
	cursor.callproc('MARKETS_PKG.get_active_endpoints', [in_batch_id, out_cursor])
	endpoints = out_cursor.getvalue().fetchall()
	cursor.close()
	
	for row in endpoints:
		in_request_id = row[0]
		response = requests.get(row[1])
		in_entity = row[2]
		in_market = row[3]
		
		cursor = connection.cursor()
		in_json = cursor.var(cx_Oracle.CLOB)
		in_json.setvalue(0, response.text)
		
		if (in_entity == "orders"):
			cursor.callproc('MARKETS_PKG.insert_orders', [in_batch_id, in_request_id, in_json])
		elif (in_entity == "trades" and in_market != "binance"):
			cursor.callproc('MARKETS_PKG.insert_trades', [in_batch_id, in_request_id, in_json])

		if (in_entity == "trades" and in_market == "binance"):
			cursor.callproc('MARKETS_PKG.insert_trades_binance', [in_batch_id, in_request_id, in_json])
			
		cursor.close()

	connection.close()
	
	#errorLogger.error('Error!')
	#debugLogger.info('Debug!')
	