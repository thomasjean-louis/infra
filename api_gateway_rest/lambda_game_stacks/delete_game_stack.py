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

    try:
        route_key = event['routeKey']
        path_params = event['pathParameters']
        
        if route_key == 'DELETE /items/{id}':
            
          # Retreive CF_stack_name from dynamodb item id
          dynamodb_client = boto3.client('dynamodb')
          table = dynamodb_client.Table(os.environ["GAME_STACKS_TABLE_NAME"])
      
          item = table.get_item(Key={"id": path_params['id']})
      
          logger.info("stack name : "+item[os.environ["GAME_STACKS_CLOUD_FORMATION_STACK_NAME_COLUMN"]])
      
          cloud_formation_client = boto3.client('cloudformation')    
      
          # Delete CF Stack
          cloud_formation_client.delete_stack(StackName=os.environ["GAME_STACKS_TABLE_NAME"],
            RetainResources=[
              'string',
            ],
            RoleARN='string',
            ClientRequestToken='string',
            DeletionMode='FORCE_DELETE_STACK' 
          )  

          # Update record in dynamodb to hide it
          table.update_item(
              Key={"ID": path_params['id']},
              UpdateExpression="SET "+os.environ["GAME_STACK_IS_ACTIVE_COLUMN"]+" = :val1",
              ExpressionAttributeValues={
              ':val1': False
              }
          )

          body = f"Deleted item {path_params['id']}"

        else:
            raise ValueError(f"Unsupported route: '{route_key}'")
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