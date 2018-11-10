#! /bin/bash

####################################################################################
#### Check that docker is installed
hash docker
if [ $? -eq 1 ]; then echo "docker is not installed, please install it first"; exit 1; fi


####################################################################################
#### Check existing docker containers for the Shiny App and remove them
CONT_ID=$(docker ps -a | awk '/etournay\/shinyproxy/{print $1}')
for i in $CONT_ID; do echo "Stopping and removing $i container"; docker stop $i; docker rm $i; done 

CONT_ID=$(docker ps -a | awk '/etournay\/dna_barcode_compatibility_shiny/{print $1}')
for i in $CONT_ID; do echo "Stopping and removing $i container";docker stop $i; docker rm $i; done 

####################################################################################
#### Dockerize DNABarcodeCompatibility_Shiny
bash dockerize_DNABarcodeCompatibility_Shiny.sh

####################################################################################
#### Dockerize shinyproxy
cd ShinyProxy

# Create a docker network that ShinyProxy will use to communicate with the Shiny containers
docker network create sp-example-net > /dev/null 2>&1

# Build docker image for the Shiny proxy
docker build --no-cache -t etournay/shinyproxy .
cd ..

####################################################################################
#### Remove dangling images
for i in $(docker images -qa -f 'dangling=true'); do docker rmi $i > /dev/null 2>&1; done

####################################################################################
#### Start the shinyproxy server in a container
docker run -d -v /var/run/docker.sock:/var/run/docker.sock --net sp-example-net -p 8080:8080 etournay/shinyproxy

####################################################################################
#### Show container status
echo "CONTAINER STATUS: please, make sure that the container etournay/shinyproxy is up and running" 
docker ps -a

echo "If the container is up and running then you can access it using using IP address:"
echo "http://host-ip:8080"


