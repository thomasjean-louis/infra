import os
import logging
import boto3 
import json
import time
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
          
          # Set Pending status
          table.update_item(
            ConditionExpression="attribute_exists(ID)",
            Key={"ID": path_params['id']},
            UpdateExpression="SET "+os.environ["STATUS_COLUMN_NAME"]+" = :val1",
            ExpressionAttributeValues={
            ':val1': os.environ["PENDING_VALUE"]
            }
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