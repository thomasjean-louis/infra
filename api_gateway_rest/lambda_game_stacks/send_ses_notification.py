import os
import logging
import boto3 
import time
import datetime
import json
import uuid
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
    logger.info("function mail")
    return response['MessageId']

def lambda_handler(event, context):  

    # logger.info(event)
    body = {}
    statusCode = 200

    logger.info("send_ses_notification")

    # Add in game monitoring dynamodb table start server event
    dynamodbGameMonitoring = boto3.resource("dynamodb")
    tableGameMonitoring = dynamodbGameMonitoring.Table(os.environ["GAME_MONITORING_TABLE_NAME"])
    
    #inserting values into table 
    cognito_username = event['cognito_username']
    datetime_now = str(datetime.now())
    response = tableGameMonitoring.put_item( 
      Item={ 
            os.environ['ID_COLUMN_NAME']: str(uuid.uuid4()),
            os.environ['TIMESTAMP_COLUMN_NAME']: datetime_now,
            os.environ['USERNAME_COLOMN_NAME']: cognito_username,
            os.environ['ACTION_COLUMN_NAME']: os.environ['START_ACTION_COLUMN_NAME'],                   
            } 
    )

    # Send mail from SES
    subject = cognito_username+" has started the ECS server"
    body = cognito_username+" has started the ECS server at "+datetime_now
    sender = os.environ['ADMIN_MAIL']
    recipient = os.environ['ADMIN_MAIL']

    logger.info("send ses mail")
    send_email(subject, body, sender, recipient)
    logger.info("ses mail sent")


    body = json.dumps(body)
    res = {
        "statusCode": statusCode,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": body
    }
    return res