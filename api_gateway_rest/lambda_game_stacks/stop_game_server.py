import os
import logging
import boto3 
import json

logger = logging.getLogger()
logger.setLevel("INFO")


def lambda_handler(event, context):
    

   # Get Item ID from API request

    # logger.info(event)
    body = {}
    statusCode = 200

    logger.info("stop_game_stack")

    directLambdaCall = False
    # get info from direct lambda call
    if "GAME_STACK_ID" in event:
      event['pathParameters']={}
      event['pathParameters']['id'] = event["GAME_STACK_ID"]
      directLambdaCall = True
      logger.info("set directLambdaCall to true ")
    else:
      logger.info("GAME_STACK_ID not sent ")

    try:
        route_key = event['routeKey']
        
        path_params = event['pathParameters']

        responseBody = []
        
        if route_key == 'POST /stopgameserver/{id}' or directLambdaCall:
            
          # Retreive Cluster and Service name from dynamodb item id
          dynamodb = boto3.resource("dynamodb")

          table = dynamodb.Table(os.environ["GAME_STACKS_TABLE_NAME"])
      
          response = table.get_item(Key={"ID": path_params['id']})
          
          # All services share same cluster
          cluster_name = os.environ["CLUSTER_NAME"]
          service_name = response["Item"][os.environ["SERVICE_NAME_COLUMN"]]

          logger.info("stack name : "+ cluster_name)
          logger.info("service name : "+ service_name)

          # Set Desired count to 0
          try:
            ecsClient = boto3.client('ecs')
            response = ecsClient.update_service(
              cluster=cluster_name,
              service=service_name,
              desiredCount=0,
            )
            # print(response)
          except Exception as e:
            print(e)
            raise e
                

          # Update record in dynamodb 
          table.update_item(
              ConditionExpression="attribute_exists(ID)",
              Key={"ID": path_params['id']},
              UpdateExpression="SET "+os.environ["STATUS_COLUMN_NAME"]+" = :val1",
              ExpressionAttributeValues={
              ':val1': os.environ["STOPPED_VALUE"]
              }
          )
          responseBody.append("Game server stopped ")
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