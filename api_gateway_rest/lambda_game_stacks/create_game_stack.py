import boto3
import os
import random
import string

def get_random_string(length):
    letters = string.ascii_lowercase
    result_str = ''.join(random.choice(letters) for i in range(length))
    return result_str

def lambda_handler(event, context):
  body = "{\"message\":\"CF stack is being created\"}"
  statusCode = 200
  
  cf_client = boto3.client('cloudformation')
  cf_client.create_stack(
    StackName=os.environ["CREATE_GAME_SERVER_CF_STACK_NAME"]+"-"+get_random_string(16),
    TemplateURL=os.environ["CREATE_GAME_SERVER_CF_TEMPLATE_URL"],
     Parameters=[
        {
            'ParameterKey': 'VpcId',
            'ParameterValue': os.environ["VPC_ID"]
        },
        {
            'ParameterKey': 'RandomString',
            'ParameterValue': get_random_string(10)
        },
        {
            'ParameterKey': 'HostedZoneName',
            'ParameterValue': os.environ["HOSTED_ZONE_NAME"]
        },
        {
            'ParameterKey': 'HostedZoneId',
            'ParameterValue': os.environ["HOSTED_ZONE_ID"]
        },
        {
            'ParameterKey': 'PublicSubnetIdA',
            'ParameterValue': os.environ["PUBLIC_SUBNET_IA_A"]
        },
        {
            'ParameterKey': 'PublicSubnetIdB',
            'ParameterValue': os.environ["PUBLIC_SUBNET_IA_B"]
        },
        {
            'ParameterKey': 'SecurityGroupAlbId',
            'ParameterValue': os.environ["SECURITY_GROUP_ALB_ID"]
        },
        {
            'ParameterKey': 'ProxyServerPort',
            'ParameterValue': os.environ["PROXY_SERVER_PORT"]
        },
        {
            'ParameterKey': 'ClusterId',
            'ParameterValue': os.environ["CLUSTER_ID"]
        },
        {
            'ParameterKey': 'SecurityGroupGameServerTaskId',
            'ParameterValue': os.environ["SECURITY_GROUP_GAME_SERVER_TASK_ID"]
        },
        {
            'ParameterKey': 'PrivateSubnetA',
            'ParameterValue': os.environ["PRIVATE_SUBNET_A"]
        },
        {
            'ParameterKey': 'PrivateSubnetB',
            'ParameterValue': os.environ["PRIVATE_SUBNET_B"]
        },
        {
            'ParameterKey': 'TaskDefinitionArn',
            'ParameterValue': os.environ["TASK_DEFINITION_ARN"]
        },
        {
            'ParameterKey': 'ProxyServerNameContainer',
            'ParameterValue': os.environ["PROXY_SERVER_NAME_CONTAINER"]
        },
        {
            'ParameterKey': 'LambdaInvokerRoleArn',
            'ParameterValue': os.environ["LAMBDA_INVOKER_ROLE_ARN"]
        },
        {
            'ParameterKey': 'InvokedLambdaFunctionName',
            'ParameterValue': os.environ["INVOKED_LAMBDA_FUNCTION_NAME"]
        },
        {
            'ParameterKey': 'GameStacksIdColumnName',
            'ParameterValue': os.environ["GAME_STACKS_ID_COLUMN_NAME"]
        },
        {
            'ParameterKey': 'GameStacksCapacityColumnName',
            'ParameterValue': os.environ["GAME_STACKS_CAPACITY_COLUMN_NAME"]
        },
        {
            'ParameterKey': 'GameStacksCapacityValue',
            'ParameterValue': os.environ["GAME_STACKS_CAPACITY_VALUE"]
        },
        {
            'ParameterKey': 'GameStacksServerLinkColumnName',
            'ParameterValue': os.environ["GAME_STACKS_SERVER_LINK_COLUMN_NAME"]
        },
        {
            'ParameterKey': 'GameStacksTableName',
            'ParameterValue': os.environ["GAME_STACKS_TABLE_NAME"]
        },
    ]
)  
  res = {
        "statusCode": statusCode,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": body
    }
  return res
  
