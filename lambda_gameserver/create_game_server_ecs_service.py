import os
import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    client = boto3.client('ecs', region_name='us-east-1')
    response = client.create_service(
    cluster=os.environ["GAME_SERVER_SERVICE_CLUSTER_ID"],
    desiredCount=1,
    launchType='FARGATE',
    networkConfiguration={
        'awsvpcConfiguration': {
            'subnets': [
                os.environ["GAME_SERVER_SERVICE_SUBNET_ID_A"],os.environ["GAME_SERVER_SERVICE_SUBNET_ID_B"]
            ],
            'securityGroups': [
                os.environ["GAME_SERVER_SERVICE_SECURITY_GROUP"],
            ],
            'assignPublicIp': 'DISABLED'
        }
    },
    loadBalancers=[
        {
            'containerName': os.environ["PROXY_SERVER_NAME_CONTAINER"],
            'containerPort': 27961,
            'targetGroupArn': os.environ["GAME_SERVER_SERVICE_TARGET_GROUP_WS_ARN"],
        },
        {
            'containerName': os.environ["PROXY_SERVER_NAME_CONTAINER"],
            'containerPort': 443,
            'targetGroupArn': os.environ["GAME_SERVER_SERVICE_TARGET_GROUP_HTTPS_ARN"],
        },
    ],
    serviceName='gameserver-service',
    taskDefinition=os.environ["GAME_SERVER_SERVICE_TASK_DEFINITION"],
)

    print(response)
    return json.dumps(response, default=str)
    
