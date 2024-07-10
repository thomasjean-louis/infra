[
  {
    "name": "${name}",
    "image": "${image}",
    "cpu": ${cpu},
    "memory": ${ram},
    "networkMode": "awsvpc",
    "environment": [
      {
        "HTTP_PORT": "80",
        "CONTENT_SERVER": "${contentserver}",
        "GAME_SERVER": "${gameserver}"
      }
    ]
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