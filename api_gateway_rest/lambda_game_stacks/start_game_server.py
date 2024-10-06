import os
import logging
import boto3 
import json
import time
import datetime
import uuid
from datetime import *
logger = logging.getLogger()
logger.setLevel("INFO")

def send_email(subject, body, sender, recipient):
    client = boto3.client('ses')
    response = client.send_email(
        Source=sender,
        Destination={
            'ToAddresses': [recipient]
        },
        Message={
            'Subject': {
                'Data': subject
            },
            'Body': {
                'Text': {
                    'Data': body
                }
            }
        }
    )
    return response['MessageId']


def lambda_handler(event, context):
    

   # Get Item ID from API request

    # logger.info(event)
    body = {}
    statusCode = 200

    logger.info("create_game_stack")

    # Add in game monitoring dynamodb table start server event
    dynamodbGameMonitoring = boto3.resource("dynamodb")
    tableGameMonitoring = dynamodbGameMonitoring.Table(os.environ["GAME_MONITORING_TABLE_NAME"])
    
    #inserting values into table 
    response = tableGameMonitoring.put_item( 
      Item={ 
            os.environ['ID_COLUMN_NAME']: str(uuid.uuid4()),
            os.environ['TIMESTAMP_COLUMN_NAME']: str(datetime.now()),
            os.environ['USERNAME_COLOMN_NAME']: event['requestContext']['authorizer']['jwt']['claims']['username'],
            os.environ['ACTION_COLUMN_NAME']: os.environ['START_ACTION_COLUMN_NAME'],                   
            } 
    )

    try:
        route_key = event['routeKey']
        
        path_params = event['pathParameters']

        responseBody = []
        
        if route_key == 'POST /startgameserver/{id}':
            
          # Retreive Service name from dynamodb item id
          dynamodb = boto3.resource("dynamodb")

          table = dynamodb.Table(os.environ["GAME_STACKS_TABLE_NAME"])
      
          response_get_item = table.get_item(Key={"ID": path_params['id']})
          
          # All services share same cluster
          cluster_name = os.environ["CLUSTER_NAME"]
          service_name = response_get_item["Item"][os.environ["SERVICE_NAME_COLUMN"]]

          logger.info("stack name : "+ cluster_name)
          logger.info("service name : "+ service_name)

          ecsClient = boto3.client('ecs')

          # Set Desired count to 1
          try:
            
            response_update_service = ecsClient.update_service(
              cluster=cluster_name,
              service=service_name,
              desiredCount=1,
            )
            #print(response_update_service)
          except Exception as e:
            print(e)
            raise e

          # Start step function, to stop automatically the server after X s
          step_function_client = boto3.client('stepfunctions')
          input_dict = {
            'ArnStopServerFunction': os.environ["ARN_STOPPED_SERVER_FUNCTION"],
            'SecondsToWait': int(os.environ["NB_SECONDS_BEFORE_SERVER_STOPPED"]),
            'GAME_STACK_ID': path_params['id'],
          }

          response = step_function_client.start_execution(
            stateMachineArn = os.environ["STATE_MACHINE_ARN"],
            input = json.dumps(input_dict)
          )
          
          # Set Pending status
          table.update_item(
            ConditionExpression="attribute_exists(ID)",
            Key={"ID": path_params['id']},
            UpdateExpression="SET "+os.environ["STATUS_COLUMN_NAME"]+" = :val1, "+os.environ["STOP_SERVER_TIME_COLUMN_NAME"]+" = :val2,"+os.environ["MESSAGE_COLUMN_NAME"]+" = :val3",
            ExpressionAttributeValues={
            ':val1': os.environ["PENDING_VALUE"],
            ':val2': (datetime.utcnow() + timedelta(seconds = int(os.environ["NB_SECONDS_BEFORE_SERVER_STOPPED"]))).isoformat(),
            ':val3': "Game server is starting ...",
            }
          )

          # Invoke lambda that checks when the ecs task is running
          lambda_client = boto3.client('lambda')
          
          cfn_event = {
                "service_name": service_name,
                "record_id": path_params['id'],
          }

          lambda_client.invoke( 
                 FunctionName=os.environ["DETECT_SERVICE_FUNCTION_NAME"],
                 InvocationType='Event',
                 Payload=json.dumps(cfn_event)
          )
          
          responseBody.append("Game server starting .. ")
          body = responseBody

          

          # Send SNS notification

        else:
            raise ValueError(f"Unsupported routee: '{route_key}'")
    except Exception as err:
      statusCode = 400
      body = str(err)
    finally:
      body = json.dumps(body)


    body = json.dumps(body)
    res = {
        "statusCode": statusCode,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": body
    }
    return res