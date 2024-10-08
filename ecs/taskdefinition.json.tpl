[
  {
    "name": "${name}",
    "image": "${image}",
    "cpu": ${cpu},
    "memory": ${ram},
    "networkMode": "awsvpc",
    "environment": [
      {
        "name": "HTTP_PORT",
        "value": "80"
      },
      {
        "name": "CONTENT_SERVER",
        "value": "${contentserver_address}"
      },
      {
        "name": "GAME_SERVER",
        "value": "${gameserver_address}"
      }      
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${name}",
          "awslogs-region": "${region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${port},
        "hostPort": ${port}
      }
    ]
  }
]