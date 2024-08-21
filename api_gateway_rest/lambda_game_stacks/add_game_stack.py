import json 
import os
import boto3 
import uuid

#function definition 
def lambda_handler(event,context): 

    dynamodb = boto3.resource('dynamodb') 
    #table name 
    table = dynamodb.Table(event['game_stacks_table_name'])
                            

    #inserting values into table 
    response = table.put_item( 
       Item={ 
            event['game_stacks_id_column_name']: str(uuid.uuid4()),
            event['game_stacks_capacity_column_name']: event['game_stacks_capacity_value'], 
            event['game_stacks_server_link_column_name']: event['game_server_random_string']+"."+event['game_server_hosted_zone_name'],             
            event['game_stacks_cloud_formation_stack_name_column']: event['game_stacks_cloud_formation_stack_name_value'],
            event['service_name_column']: event['service_name_value'],
            event['game_stacks_is_active_columnn_name']: True        
        } 
    ) 
    return response