#!/bin/bash
set -e

dir_name=$(basename $(pwd))
docker build --tag=quick/$dir_name .
image_name=quick/$dir_name
container_id=$(docker create "$image_name")
mkdir -p packages
docker cp "$container_id:/home/datadog-aas-extension/package/Datadog.AzureAppServices.Node.0.1.0.nupkg" "$(pwd)/packages"
docker rm "$container_id"

