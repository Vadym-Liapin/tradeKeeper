import cx_Oracle
import os
import configparser
import requests
import json
import logging

def initLogger(type, file):
	logger = logging.getLogger(type)
	
	if type == 'error':
		logger.setLevel(logging.ERROR)
	elif type == 'debug':
		logger.setLevel(logging.DEBUG)
	
	handler = logging.FileHandler(file)
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

def createBatch(connection):
	cursor = connection.cursor()
	
	out_batch_id = cursor.var(cx_Oracle.NUMBER)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)
	
	cursor.callproc('MARKETS_PKG.create_batch', [out_batch_id, out_code, out_message])
	cursor.close()
	
	return int(out_batch_id.getvalue())

def getActiveEndpoints(connection, batchId):
	cursor = connection.cursor()
	
	in_batch_id = cursor.var(cx_Oracle.NUMBER)
	in_batch_id.setvalue(0, batchId)
	
	out_cursor = cursor.var(cx_Oracle.CURSOR)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)

	cursor.callproc('MARKETS_PKG.get_active_endpoints', [in_batch_id, out_cursor, out_code, out_message])
	cursor.close()
	
	return out_cursor.getvalue().fetchall()
	
if __name__ == '__main__':
	errorLogger = initLogger('error', 'error.log')
	debugLogger = initLogger('debug', 'debug.log')
	
	connection = connect()
	
	batchId = createBatch(connection)
	endpoints = getActiveEndpoints(connection, batchId)
	
	cursor = connection.cursor()
	in_batch_id = cursor.var(cx_Oracle.NUMBER)
	in_json = cursor.var(cx_Oracle.CLOB)
	out_batch_id = cursor.var(cx_Oracle.NUMBER)
	out_cursor = cursor.var(cx_Oracle.CURSOR)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)
	out_trade_id_LAST = cursor.var(cx_Oracle.STRING)
	
	exit(0)
	
	for row in endpoints:
		in_request_id = row[0]
		in_request_parent_id = row[1]
		in_entity = row[4]
		in_market = row[5]
		
		if (in_entity == "orders"):
			request = str(row[2]) + str(row[3])
			response = requests.get(request)
			in_json.setvalue(0, response.text)
			
			cursor.callproc('MARKETS_PKG.insert_orders', [in_batch_id, in_request_id, in_json, out_code, out_message])
			
		if (in_entity == "trades" and in_market != "binance"):
			request = str(row[2]) + str(row[3])
			response = requests.get(request)
			in_json.setvalue(0, response.text)

			cursor.callproc('MARKETS_PKG.insert_trades_gtt', [in_batch_id, in_request_id, in_json, out_trade_id_LAST, out_code, out_message])

		if (in_entity == "trades" and in_market == "binance"):
			if in_request_parent_id is None:
				request = str(row[2]) + str(row[3])
				debugLogger.info('request=' + request)
				response = requests.get(request)
				in_json.setvalue(0, response.text)
				debugLogger.info('response=' + response.text)
			
				cursor.callproc('MARKETS_PKG.insert_trades_gtt', [in_batch_id, in_request_id, in_json, out_trade_id_LAST, out_code, out_message])
				debugLogger.info('out_trade_id_LAST=' + out_trade_id_LAST.getvalue() + ', out_code=' + str(out_code.getvalue()) + ', out_message=' + out_message.getvalue())
				
				trade_id_LAST = out_trade_id_LAST.getvalue()
				trade_id_PREV = trade_id_LAST
			else:
				for i in range(10):
					request = row[2] + row[3].replace('%trade_id_LAST%', str(trade_id_PREV))
					debugLogger.info('request=' + request)
					response = requests.get(request)
					in_json.setvalue(0, response.text)
					debugLogger.info('response=' + response.text)
					
					cursor.callproc('MARKETS_PKG.insert_trades_gtt', [in_batch_id, in_request_id, in_json, out_trade_id_LAST, out_code, out_message])
					debugLogger.info('out_trade_id_LAST=' + out_trade_id_LAST.getvalue() + ', out_code=' + str(out_code.getvalue()) + ', out_message=' + out_message.getvalue())
					
					trade_id_LAST = out_trade_id_LAST.getvalue()
						
					if int(trade_id_LAST) > int(trade_id_PREV):
						trade_id_PREV = trade_id_LAST
						i = i + 1
					else:
						break
			
	cursor.callproc('MARKETS_PKG.insert_trades', [in_batch_id, out_code, out_message])

	cursor.close()
	connection.close()
	
	#errorLogger.error('Error!')
	#debugLogger.info('Debug!')
	