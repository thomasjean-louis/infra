import os
import logging
import boto3 
import json
import time
import threading

logger = logging.getLogger()
logger.setLevel("INFO")

def waiter_caller(cluster_name, service_name):
      try:
          waiter.wait(
              cluster=cluster_name,
              services=[
                  service_name,
              ],
              WaiterConfig={
                  'Delay': 15,
                  'MaxAttempts': 60
              }
          )
      except Exception as e:
          print('Deploy failed', e)

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
        
        if route_key == 'POST /detectserviceready/{id}':
            
          # Retreive Service name from dynamodb item id
          dynamodb = boto3.resource("dynamodb")

          table = dynamodb.Table(os.environ["GAME_STACKS_TABLE_NAME"])
      
          response = table.get_item(Key={"ID": path_params['id']})
          
          # All services share same cluster
          cluster_name = os.environ["CLUSTER_NAME"]
          service_name = response["Item"][os.environ["SERVICE_NAME_COLUMN"]]

          logger.info("stack name : "+ cluster_name)
          logger.info("service name : "+ service_name)

          ecs_client = boto3.client('ecs')
          waiter = ecs_client.get_waiter('services_stable')

          # Wait the ecs service deployment
          t = threading.Thread(target=waiter_caller, args=(os.environ["CLUSTER_NAME"], service_name))
          t.start()
          while t.is_alive():
              print("Waiting for service deployment...")
              time.sleep(15)
                

          responseBody.append("Game server ready ")
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