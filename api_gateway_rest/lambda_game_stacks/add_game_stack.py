import json 
import os
import boto3 
import uuid

#function definition 
def lambda_handler(event,context): 

    cf_parameters = json.loads(event.body)

    dynamodb = boto3.resource('dynamodb') 
    #table name 
    table = dynamodb.Table(os.environ["GAME_STACKS_TABLE_NAME"])
                            

    #inserting values into table 
    response = table.put_item( 
       Item={ 
            os.environ["GAME_STACKS_ID_COLUMN_NAME"]: str(uuid.uuid4()),
            os.environ["GAME_STACKS_CAPACITY_COLUMN_NAME"]: os.environ["GAME_STACKS_CAPACITY_VALUE"], 
            os.environ["GAME_STACKS_SERVER_LINK_COLUMN_NAME"]: event['game_server_link'],             
        } 
    ) 
    return response