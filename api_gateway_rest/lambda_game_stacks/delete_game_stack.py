import os
import logging
import boto3 
import json

logger = logging.getLogger()
logger.setLevel("INFO")


def lambda_handler(event, context):

    # Retreive CF_stack_name from dynamodb item id
    dynamodb_client = boto3.client('dynamodb')
    table = dynamodb_client.Table(os.environ["GAME_STACKS_TABLE_NAME"])

    item = table.get_item(Key={"id": os.environ["GAME_STACK_ID"]})

    logger.info("stack name : "+item[os.environ["GAME_STACKS_CLOUD_FORMATION_STACK_NAME_COLUMN"]])

    cloud_formation_client = boto3.client('cloudformation')    

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
        Key={"ID": os.environ["GAME_STACK_ID"]},
        UpdateExpression="SET "+os.environ["GAME_STACK_IS_ACTIVE_COLUMN"]+" = :val1",
        ExpressionAttributeValues={
        ':val1': False
        }
    )


    # logger.info(event)
    body = {}
    statusCode = 200

    # try:
    #     if event['routeKey'] == "DELETE /gamestack":
    #         body = table.scan()
    #         body = body["Items"]
    #         # logger.info(body)
    #         responseBody = []
    #         for items in body:
    #             responseItems = [
    #                 {'ID': items['ID'], 'Capacity': float(items['Capacity']), 'ServerLink': items['ServerLink']}]
    #             responseBody.append(responseItems)
    #         body = responseBody
    # except KeyError:
    #     statusCode = 400
    #     body = 'Unsupported route: ' + event['routeKey']
    body = json.dumps(body)
    res = {
        "statusCode": statusCode,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": body
    }
    return res