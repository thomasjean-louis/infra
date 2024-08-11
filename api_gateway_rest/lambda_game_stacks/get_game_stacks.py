import os
import logging
import json
import boto3

logger = logging.getLogger()
logger.setLevel("INFO")

client = boto3.client('dynamodb')
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["GAME_STACKS_TABLE_NAME"])

def lambda_handler(event, context):
    # logger.info(event)
    body = {}
    statusCode = 200

    try:
        if event['routeKey'] == "GET /gamestacks":
            body = table.scan()
            body = body["Items"]
            # logger.info(body)
            responseBody = []
            for items in body:
                responseItems = [
                    {os.environ["GAME_STACKS_ID_COLUMN_NAME"]: items[os.environ["GAME_STACKS_ID_COLUMN_NAME"]], os.environ["GAME_STACKS_CAPACITY_COLUMN_NAME"]: float(items[os.environ["GAME_STACKS_CAPACITY_COLUMN_NAME"]]), 'GAME_STACKS_SERVER_LINK_COLUMN_NAME': items['GAME_STACKS_SERVER_LINK_COLUMN_NAME'],'GAME_STACKS_IS_ACTIVE_COLUMN_NAME': items['GAME_STACKS_IS_ACTIVE_COLUMN_NAME'],}]
                responseBody.append(responseItems)
            body = responseBody
    except KeyError:
        statusCode = 400
        body = 'Unsupported route: ' + event['routeKey']
    body = json.dumps(body)
    res = {
        "statusCode": statusCode,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": body
    }
    return res