import os
import logging
import boto3 
import json
import time
logger = logging.getLogger()
logger.setLevel("INFO")


def lambda_handler(event, context):  

    # logger.info(event)
    body = {}
    statusCode = 200

    logger.info("create_game_stack")

    try:
        dynamodb = boto3.resource("dynamodb")

        table = dynamodb.Table(os.environ["GAME_STACKS_TABLE_NAME"])
     
        response_get_item = table.get_item(Key={"ID": path_params['id']}) 

        cluster_name = os.environ["CLUSTER_NAME"]
        service_name = response_get_item["Item"][os.environ["SERVICE_NAME_COLUMN"]]

        logger.info("stack name : "+ cluster_name)
        logger.info("service name : "+ service_name)

        ecsClient = boto3.client('ecs')

        # Check when ecs service is ready
        runningCount=0
 
        try:
          while runningCount==0:
            response_describe_service = ecsClient.describe_services(
              cluster=cluster_name, 
              services=[service_name,]
            )
            runningCount = response_describe_service["services"][0]["runningCount"]
            print("runningCount ")
            print(response_describe_service["services"][0]["runningCount"])
            time.sleep(3)
          
        except Exception as e:
          print(e)
          raise e       

        # Update record in dynamodb 
        table.update_item(
            ConditionExpression="attribute_exists(ID)",
            Key={"ID": path_params['id']},
            UpdateExpression="SET "+os.environ["STATUS_COLUMN_NAME"]+" = :val1",
            ExpressionAttributeValues={
            ':val1': True
            }
        )

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