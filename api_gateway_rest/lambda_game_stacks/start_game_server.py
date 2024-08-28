import os
import logging
import boto3 
import json
import time
import datetime
from datetime import *
logger = logging.getLogger()
logger.setLevel("INFO")


def lambda_handler(event, context):
    

   # Get Item ID from API request

    # logger.info(event)
    body = {}
    statusCode = 200

    logger.info("create_game_stack")

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
            print(response_update_service)
          except Exception as e:
            print(e)
            raise e

          # Start step function, to stop automatically the server after X s
          step_function_client = boto3.client('stepfunctions')
          input_dict = {'ArnStopServerFunction': os.environ["ARN_STOPPED_SERVER_FUNCTION"]}

          response = step_function_client.start_execution(
            stateMachineArn = os.environ["STATE_MACHINE_ARN"],
            input = json.dumps(input_dict)
          )
          
          # Set Pending status
          table.update_item(
            ConditionExpression="attribute_exists(ID)",
            Key={"ID": path_params['id']},
            UpdateExpression="SET "+os.environ["STATUS_COLUMN_NAME"]+" = :val1, "+os.environ["STOP_SERVER_TIME_COLUMN_NAME"]+" = :val2",
            ExpressionAttributeValues={
            ':val1': os.environ["PENDING_VALUE"],
            ':val2': (datetime.utcnow() + timedelta(seconds = int(os.environ["NB_SECONDS_BEFORE_SERVER_STOPPED"]))).isoformat(),
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