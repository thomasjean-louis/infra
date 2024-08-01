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
    TemplateURL=os.environ["CREATE_GAME_SERVER_CF_TEMPLATE_URL"]
)  
  res = {
        "statusCode": statusCode,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": body
    }
  return res
  
