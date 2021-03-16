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
					'ds_unix_ms_p10s': 	row[5]
				}
				
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
				'%ds_unix_ms_p10s%': 	str(batch.get('ds_unix_ms_p10s'))
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

def insertOrders(connection, batchId, requestId, response):
	cursor = connection.cursor()
	
	in_batch_id = cursor.var(cx_Oracle.NUMBER)
	in_request_id = cursor.var(cx_Oracle.NUMBER)
	in_json = cursor.var(cx_Oracle.CLOB)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)

	in_batch_id = batchId
	in_request_id = requestId
	in_json.setvalue(0, response)
	
	cursor.callproc('MARKETS_PKG.insert_orders', [in_batch_id, in_request_id, in_json, out_code, out_message])
	cursor.close()
	
	return {'code': int(out_code.getvalue()), 'message': out_message.getvalue()}

def insertTradesGTT(connection, batchId, requestId, response):
	cursor = connection.cursor()
	
	in_batch_id = cursor.var(cx_Oracle.NUMBER)
	in_request_id = cursor.var(cx_Oracle.NUMBER)
	in_json = cursor.var(cx_Oracle.CLOB)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)

	in_batch_id = batchId
	in_request_id = requestId
	in_json.setvalue(0, response)
	
	cursor.callproc('MARKETS_PKG.insert_trades_gtt', [in_batch_id, in_request_id, in_json, out_code, out_message])
	cursor.close()
	
	return {'code': int(out_code.getvalue()), 'message': out_message.getvalue()}

def insertTrades(connection, batchId):
	cursor = connection.cursor()
	
	in_batch_id = cursor.var(cx_Oracle.NUMBER)
	out_code = cursor.var(cx_Oracle.NUMBER)
	out_message = cursor.var(cx_Oracle.STRING)

	in_batch_id = batchId
	
	cursor.callproc('MARKETS_PKG.insert_trades', [in_batch_id, out_code, out_message])
	cursor.close()
	
	return {'code': int(out_code.getvalue()), 'message': out_message.getvalue()}
	
if __name__ == '__main__':
	errorLogger = initLogger('error', 'error.log')
	debugLogger = initLogger('debug', 'debug.log')
	
	connection = connect()
	
	batch = createBatch(connection)
	batchId = batch.get('id')
	batchDfUnixMs = batch.get('df_unix_ms')
	#debugLogger.info('batch=' + str(batch))
	
	activeEndpoints = getActiveEndpoints(connection, batch)
	#debugLogger.info('activeEndpoints=' + str(activeEndpoints))
	
	for row in activeEndpoints:
		requestId = row.get('request_id')
		request = str(row.get('endpoint')) + str(row.get('params'))
		requestParentId = row.get('request_parent_id')
		entity = row.get('entity')
		market = row.get('market')
		
		if (entity == "orders"):
			response = requests.get(request)
			insertOrders(connection, batchId, requestId, response.text)
			
		elif (entity == "trades" and market != "binance"):
			response = requests.get(request)
			insertTradesGTT(connection, batchId, requestId, response.text)

		elif (entity == "trades" and market == "binance"):
			if requestParentId is None:
				response = requests.get(request)
				responseJSON = response.json()
				fromId = int(responseJSON[0]['a'])
				created = int(responseJSON[0]['T'])
				#debugLogger.info('fromId=' + str(fromId) + ', created=' + str(created))
			else:
				for i in range(1000):
					response = requests.get(request.replace('%fromId%', str(fromId)))
					responseJSON = response.json()
					insertTradesGTT(connection, batchId, requestId, response.text)
					
					fromIdLast = int(responseJSON[-1]['a'])
					createdLast = int(responseJSON[-1]['T'])
					#debugLogger.info('i=' + str(i) + ', fromId=' + str(fromIdLast) + ', created=' + str(createdLast) + ', batchDfUnixMs=' + str(batchDfUnixMs))
					
					if fromIdLast > fromId and createdLast < batchDfUnixMs:
						fromId = fromIdLast
						i = i + 1
					else:
						break
			
	insertTrades(connection, batchId)

	connection.close()
	
	#errorLogger.error('Error!')
	#debugLogger.info('Debug!')
	