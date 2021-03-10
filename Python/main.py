import cx_Oracle
import os
import configparser
import requests
import json
import logging

def initLogger(in_type, in_file):
	logger = logging.getLogger(in_type)
	
	if in_type == 'error':
		logger.setLevel(logging.ERROR)
	elif in_type == 'debug':
		logger.setLevel(logging.DEBUG)
	
	handler = logging.FileHandler(in_file)
	formatter = logging.Formatter('%(asctime)s %(filename)s: %(message)s', '%d.%m.%Y %H:%M:%S')
	handler.setFormatter(formatter)
	logger.addHandler(handler)
	
	return logger

def connect():
	config = configparser.ConfigParser()
	config.read('config.ini')
	
	os.environ["TNS_ADMIN"] = os.environ["HOME"]
	
	connection = cx_Oracle.connect(config['DATABASE']['username'], config['DATABASE']['password'], dsn=config['DATABASE']['dsn'])
	return connection

if __name__ == '__main__':
	errorLogger = initLogger('error', 'error.log')
	debugLogger = initLogger('debug', 'debug.log')
	
	connection = connect()
	
	cursor = connection.cursor()
	in_batch_id = cursor.var(cx_Oracle.NUMBER)
	in_json = cursor.var(cx_Oracle.CLOB)
	out_batch_id = cursor.var(cx_Oracle.NUMBER)
	out_cursor = cursor.var(cx_Oracle.CURSOR)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)
	out_trade_id_MIN = cursor.var(cx_Oracle.STRING)
	
	cursor.callproc('MARKETS_PKG.create_batch', [out_batch_id, out_code, out_message])

	in_batch_id.setvalue(0, out_batch_id.getvalue())
	cursor.callproc('MARKETS_PKG.get_active_endpoints', [in_batch_id, out_cursor, out_code, out_message])
	endpoints = out_cursor.getvalue().fetchall()
	
	for row in endpoints:
		in_request_id = row[0]
		response = requests.get(row[1])
		in_entity = row[2]
		in_market = row[3]
		
		in_json.setvalue(0, response.text)
		
		if (in_entity == "orders"):
			cursor.callproc('MARKETS_PKG.insert_orders', [in_batch_id, in_request_id, in_json, out_code, out_message])
			
		if (in_entity == "trades" and in_market != "binance"):
			cursor.callproc('MARKETS_PKG.insert_trades_gtt', [in_batch_id, in_request_id, in_json, out_trade_id_MIN, out_code, out_message])

		if (in_entity == "trades" and in_market == "binance"):
			trade_id_MIN = '0'
			trade_id_PREV = '0'

			for i in range(10):
				if i > 0:
					debugLogger.info('request=' + row[1] + '&fromId=' + str(trade_id_PREV))
					response = requests.get(row[1] + '&fromId=' + str(trade_id_PREV))
					in_json.setvalue(0, response.text)
				
				debugLogger.info('response=' + response.text)
				
				cursor.callproc('MARKETS_PKG.insert_trades_gtt', [in_batch_id, in_request_id, in_json, out_trade_id_MIN, out_code, out_message])
				if out_trade_id_MIN is None:
					trade_id_MIN = '0'
				else:
					trade_id_MIN = out_trade_id_MIN.getvalue()
					
				debugLogger.info('i=' + str(i) + ', out_trade_id_MIN=' + str(trade_id_MIN))
				
				if i == 0:
					trade_id_PREV = trade_id_MIN
					i = i + 1
				elif int(trade_id_MIN) < int(trade_id_PREV):
					trade_id_PREV = trade_id_MIN
					i = i + 1
				else:
					break
			
	cursor.callproc('MARKETS_PKG.insert_trades', [in_batch_id, out_code, out_message])

	cursor.close()
	connection.close()
	
	#errorLogger.error('Error!')
	#debugLogger.info('Debug!')
	