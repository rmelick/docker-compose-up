#!/bin/sh
set -x
set -e

build() {
    eval $(docker-machine env -u)
    docker build -t rmelick/docker-compose-up-app-container:latest -f ./app-container/Dockerfile ./app-container/
    docker build -t rmelick/docker-compose-up-data-container:latest -f ./data-container/Dockerfile ./data-container/
    docker push rmelick/docker-compose-up-app-container:latest
    docker push rmelick/docker-compose-up-data-container:latest
}
up() {
    echo "Starting..."
    eval $(docker-machine env --swarm docker-compose-up-master)
    docker-compose up -d
}
down() {
    echo "Stopping..."
    eval $(docker-machine env --swarm docker-compose-up-master)
    docker-compose down
}
pull() {
    echo "Pulling..."
    eval $(docker-machine env --swarm docker-compose-up-master)
    docker-compose pull
}

case "$1" in
    "up"):
        up
        ;;
    "down"):
        down
        ;;
    "pull"):
        pull
        ;;
    "build"):
        build
        ;;
esac