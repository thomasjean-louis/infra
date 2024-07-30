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
    logger.info(event)
    logger.info(event['resourceId'])
    body = {}
    statusCode = 200
    headers = {
        "Content-Type": "application/json"
    }

    try:
        if event['resourceId'] == "GET /gamestacks":
            body = table.scan()
            body = body["Items"]
            logger.info("ITEMS----")
            logger.info(body)
            responseBody = []
            for items in body:
                responseItems = [
                    {'ID': float(items['ID']), 'Capacity': items['Capacity'], 'ServerLink': items['ServerLink']}]
                responseBody.append(responseItems)
            body = responseBody
    except KeyError:
        statusCode = 400
        body = 'Unsupported route: ' + event['resourceId']
    body = json.dumps(body)
    res = {
        "statusCode": statusCode,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": body
    }
    return res