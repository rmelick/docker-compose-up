#!/bin/bash
AWS_ACCESS_KEY_ID=$(aws --profile rmelick configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws --profile rmelick configure get aws_secret_access_key)
AWS_SSH_KEY_PEM_PATH=~/Documents/privateAWSKeys/rmelick/rmelick.pem
NODE_PREFIX=docker-compose-up

create_instance() {
  docker-machine ip $1
  if [ $? -ne 0 ]; then
	  echo "creating new machine $1 with consul $CONSUL_IP..."
	  docker-machine create --driver amazonec2 \
			  --amazonec2-region eu-central-1 \
			  --amazonec2-access-key $AWS_ACCESS_KEY_ID \
			  --amazonec2-secret-key $AWS_SECRET_ACCESS_KEY \
			  --amazonec2-instance-type t2.micro \
			  --amazonec2-ssh-keypath $AWS_SSH_KEY_PEM_PATH \
			  --swarm $2 \
			  --swarm-discovery="consul://$CONSUL_IP:8500" --engine-opt="cluster-store=consul://$CONSUL_IP:8500" --engine-opt="cluster-advertise=eth0:2376" \
			  $1
  else
    echo "machine $1 already exists."
  fi
}

create_consul_instance() {
  docker-machine ip $1
  if [ $? -ne 0 ]; then
    create_instance $1
    eval $(docker-machine env "$1")
    docker run -d -p 8500:8500 --restart=always --name=consul progrium/consul -server -bootstrap
  else
    echo "machine $1 already exists."
  fi
}

create() {
	echo "Creating consul node..."
	create_consul_instance $NODE_PREFIX-consul
	CONSUL_IP=$(docker-machine ip "$NODE_PREFIX-consul")
	echo "Creating swarm master..."
	create_instance "$NODE_PREFIX-master" "--swarm-master "
	echo "Creating swarm node..."
	create_instance "$NODE_PREFIX-node"

	echo "Setting docker env to swarm cluster"
	eval $(docker-machine env --swarm "$NODE_PREFIX-master")
}

destroy() {
	# List of all machines regarding this environment:
	NODES=$(docker-machine ls | grep $NODE_PREFIX)
	echo "NODES=$NODES"
	docker-machine rm -f $(docker-machine ls --format "{{.Name}}" | grep $NODE_PREFIX)
}

case "$1" in
    "create"):
        create
        ;;
    "destroy"):
        destroy
        ;;
esac