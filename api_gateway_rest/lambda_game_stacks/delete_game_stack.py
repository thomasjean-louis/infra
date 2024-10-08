import os
import logging
import boto3 
import json

logger = logging.getLogger()
logger.setLevel("INFO")


def lambda_handler(event, context):
    

   # Get Item ID from API request

    # logger.info(event)
    body = {}
    statusCode = 200

    logger.info("delete_game_stack")

    try:
        route_key = event['routeKey']
        
        path_params = event['pathParameters']

        responseBody = []
        
        if route_key == 'DELETE /gamestack/{id}':
            
          # Retreive CF_stack_name from dynamodb item id
          dynamodb = boto3.resource("dynamodb")

          table = dynamodb.Table(os.environ["GAME_STACKS_TABLE_NAME"])
      
          response = table.get_item(Key={"ID": path_params['id']})
          
          stack_id = response["Item"][os.environ["GAME_STACKS_CLOUD_FORMATION_STACK_NAME_COLUMN"]]

          logger.info("stack name : "+ stack_id)
      
          cloud_formation_client = boto3.client('cloudformation')    
                
          # Retreive 53 record from CF stack
          responseCF = cloud_formation_client.describe_stack_resources(
            StackName=stack_id,
            LogicalResourceId='Route53Record'
          )

          physicalResourceId = responseCF['StackResources'][0]['PhysicalResourceId']
          

          # Delete CName record that was created to validate DNS entry
          client53 = boto3.client('route53')
          response53 = client53.list_resource_record_sets(
            HostedZoneId = os.environ["HOSTED_ZONE_ID"]
          )

          dns_records = []    
          dns_records.extend(response53['ResourceRecordSets'])

          for record in dns_records:
            if (record['Type'] == 'CNAME') and (physicalResourceId in record['Name']) and ("acm-validations.aws" in record['ResourceRecords'][0]['Value']) :
                
              # delete this record
              client53.change_resource_record_sets(
                ChangeBatch={
                  'Changes': [
                   {
                      'Action': 'DELETE',
                      'ResourceRecordSet': {
                          'Name': record['Name'],
                          'ResourceRecords': [
                              {
                                  'Value': record['ResourceRecords'][0]['Value'],
                              },
                          ],
                          'TTL': 300,
                          'Type': 'CNAME',
                      },
                   },
                ],
                 },
                HostedZoneId = os.environ["HOSTED_ZONE_ID"],
              )

              break


          # Delete CF Stack
          cloud_formation_client.delete_stack(StackName=stack_id)  

          # Update record in dynamodb to hide it
          table.update_item(
              ConditionExpression="attribute_exists(ID)",
              Key={"ID": path_params['id']},
              UpdateExpression="SET "+os.environ["GAME_STACK_IS_ACTIVE_COLUMN"]+" = :val1",
              ExpressionAttributeValues={
              ':val1': False
              }
          )
          responseBody.append("Deleted item")
          body = responseBody

        else:
            raise ValueError(f"Unsupported routee: '{route_key}'")
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