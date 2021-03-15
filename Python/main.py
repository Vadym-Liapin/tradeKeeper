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
	
	out_cursor = cursor.var(cx_Oracle.CURSOR)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)
	
	cursor.callproc('MARKETS_PKG.create_batch', [out_cursor, out_code, out_message])
	cursor.close()
	
	row = out_cursor.getvalue().fetchone()
	
	result	= 	{
					'id': 				row[0], 
					'ds_unix_s': 		row[1], 
					'df_unix_s': 		row[2], 
					'ds_unix_ms': 		row[3], 
					'df_unix_ms': 		row[4], 
					'ds_unix_ms_m10s': 	row[5]
		
	return result

def getActiveEndpoints(connection, batch):
	def replace (string, subst):
		for i, j in subst.items():
			string = string.replace(i, j)
			
		return string
	
	cursor = connection.cursor()
	
	out_cursor = cursor.var(cx_Oracle.CURSOR)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)

	cursor.callproc('MARKETS_PKG.get_active_endpoints', [out_cursor, out_code, out_message])
	cursor.close()
	
	subst =	{
				'%ds_unix_s%': 			str(batch.get('ds_unix_s')),
				'%df_unix_s%': 			str(batch.get('df_unix_s')),
				'%ds_unix_ms%': 		str(batch.get('ds_unix_ms')),
				'%df_unix_ms%': 		str(batch.get('df_unix_ms')),
				'%ds_unix_ms_m10s%': 	str(batch.get('ds_unix_ms_m10s'))
			}
			
	result = []
	
	for row in out_cursor.getvalue().fetchall():
		endpoint = 	{
						'request_id': 			row[0], 
						'request_parent_id': 	row[1], 
						'endpoint': 			row[2], 
						'params': 				None if row[3] is None else replace(row[3], subst), 
						'entity': 				row[4], 
						'market': 				row[5]
					}
		result.append(endpoint)

	return result
	
if __name__ == '__main__':
	errorLogger = initLogger('error', 'error.log')
	debugLogger = initLogger('debug', 'debug.log')
	
	connection = connect()
	
	batch = createBatch(connection)
	debugLogger.info('batch=' + str(batch))
	activeEndpoints = getActiveEndpoints(connection, batch)
	debugLogger.info('activeEndpoints=' + str(activeEndpoints))
	
	exit(0)
	
	cursor = connection.cursor()
	in_batch_id = cursor.var(cx_Oracle.NUMBER)
	in_json = cursor.var(cx_Oracle.CLOB)
	out_batch_id = cursor.var(cx_Oracle.NUMBER)
	out_cursor = cursor.var(cx_Oracle.CURSOR)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)
	out_trade_id_LAST = cursor.var(cx_Oracle.STRING)
	
	for row in activeEndpoints:
		in_batch_id = batch.get('id')
		in_request_id = row.get('request_id')
		in_request_parent_id = row.get('request_parent_id')
		in_entity = row.get('entity')
		in_market = row.get('market')
		
		if (in_entity == "orders"):
			request = str(row.get('endpoint')) + str(row.get('params'))
			response = requests.get(request)
			in_json.setvalue(0, response.text)
			
			cursor.callproc('MARKETS_PKG.insert_orders', [in_batch_id, in_request_id, in_json, out_code, out_message])
			
		elif (in_entity == "trades" and in_market != "binance"):
			request = str(row.get('endpoint')) + str(row.get('params'))
			response = requests.get(request)
			in_json.setvalue(0, response.text)

			cursor.callproc('MARKETS_PKG.insert_trades_gtt', [in_batch_id, in_request_id, in_json, out_trade_id_LAST, out_code, out_message])

		elif (in_entity == "trades" and in_market == "binance"):
			if in_request_parent_id is None:
				request = str(row.get('endpoint')) + str(row.get('params'))
				debugLogger.info('request=' + request)
				response = requests.get(request)
				in_json.setvalue(0, response.text)
				debugLogger.info('response=' + response.text)
			
				cursor.callproc('MARKETS_PKG.insert_trades_gtt', [in_batch_id, in_request_id, in_json, out_trade_id_LAST, out_code, out_message])
				debugLogger.info('out_trade_id_LAST=' + str(out_trade_id_LAST.getvalue()) + ', out_code=' + str(out_code.getvalue()) + ', out_message=' + out_message.getvalue())
				
				trade_id_LAST = out_trade_id_LAST.getvalue()
				trade_id_PREV = trade_id_LAST
			else:
				for i in range(30):
					request = str(row.get('endpoint')) + str(row.get('params').replace('%trade_id_LAST%', str(trade_id_PREV)))
					debugLogger.info('request=' + request)
					response = requests.get(request)
					in_json.setvalue(0, response.text)
					debugLogger.info('response=' + response.text)
					
					cursor.callproc('MARKETS_PKG.insert_trades_gtt', [in_batch_id, in_request_id, in_json, out_trade_id_LAST, out_code, out_message])
					debugLogger.info('out_trade_id_LAST=' + str(out_trade_id_LAST.getvalue()) + ', out_code=' + str(out_code.getvalue()) + ', out_message=' + str(out_message.getvalue()))
					
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
	