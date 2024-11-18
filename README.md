# Infra
Terraform repository to manage resources used by the "Serverless multi-player game" demo project. The resources are auto-deployed based on schedule rule in Prod account and deployed when needed, in Dev account. 

## Architecture
![alt text](https://p.thomasjeanlouis.com/wp-content/uploads/2024/09/serverlessMultiplayerGame.architecture_V2.png)


1. Docker images are uploaded into ECR repositories.

2. At each [front-end react commit](https://github.com/thomasjean-louis/homepage), the code is deployed into the serverless amplify website.

3. A user accesses the amplify website using a public custom domain name. He is redirected to a login page, binded with Cognito data.

4. After successful login, the user can press a button which will call HTTP API, and trigger lambda functions. Some APIs can be called only by users belonging to Cognito admin group.

5. Lambda functions create and manage Cloudformation game-server stacks. A step function is used, to stop automatically game-servers after a timer.

6. When a user joins a game, the client retreive static files from a S3 bucket, and a WSS connection is made with the ECS game server task.

7. Each game server are contained in an ECS task. The task is composed of two docker containers : a proxy and a game server.

8. A dynamodb table stores all game server data (endpoint url, cloudformation stack name, game server status,…)

9. AWS resources are deployed using Terraform in Dev and Prod aws accounts. A cloudwatch_event deploy the ressources during work hours, in prod account.

## Credits

* [inolen/quakejs](https://github.com/inolen/quakejs) - The original QuakeJS project.
* [ioquake/ioq3](https://github.com/ioquake/ioq3) - The community supported version of Quake 3 used by QuakeJS. It is licensed under the GPLv2.
* [treyyoder/quakejs-docker](https://github.com/treyyoder/quakejs-docker/tree/master) - The original quakeJs docker image I started working with.   
* [joz3d.net](http://www.joz3d.net/html/q3console.html) - Useful information about configuration values.
