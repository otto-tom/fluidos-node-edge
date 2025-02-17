#!/bin/bash

# Check that there are at least 3 arguments (username, version, at least one component)
if [[ "$#" -lt 3 ]]; then
    echo "Syntaxt error: insufficient arguments."
    echo "Use: $0 DOCKER_USERNAME VERSIONE EDGE component [component2 ...]"
    echo "EDGE values: \"on\", \"off\" and refers to provider cluster edge IoT support"
    exit 1
fi

DOCKER_USERNAME="$1"
VERSION="$2"
EDGE="$3"
# Remove the first three arguments (username and version) to handle only components and images
shift 3

# Associative array to associate components to their corresponding Helm values
declare -A COMPONENT_MAP
COMPONENT_MAP["rear-controller"]="rearController.imageName"
COMPONENT_MAP["rear-manager"]="rearManager.imageName"
COMPONENT_MAP["local-resource-manager"]="localResourceManager.imageName"
COMPONENT_MAP["network-manager"]="networkManager.imageName"
if [ $EDGE == "on" ]; then
    COMPONENT_MAP["edge-resource-manager"]="edgeResourceManager.imageName"
fi

# Initialize a variable to store the --set options
IMAGE_SET_STRING=""

# Iterates over the arguments passed to the script
for component in "$@"; do
    # Check that the component is valid
    if [[ -z "${COMPONENT_MAP[$component]}" ]]; then
        echo "Error: component '$component' not recognized."
        continue
    fi
    
    helm_key="${COMPONENT_MAP[$component]}"
    # Build the --set string using the map
    IMAGE_SET_STRING="$IMAGE_SET_STRING --set $helm_key=$DOCKER_USERNAME/$component"
done

export KUBECONFIG=../scripts/fluidos-consumer-1-config

# Delete all the resources
kubectl delete -f ../../deployments/node/crds
# Install all the resources
kubectl apply -f ../../deployments/node/crds

# Run the helm command
helm get values node -n fluidos > consumer_values.yaml
helm uninstall node -n fluidos
eval "helm install node ../../deployments/node -n fluidos -f consumer_values.yaml $IMAGE_SET_STRING" --set tag="$VERSION"
rm consumer_values.yaml

if [ $EDGE == "on" ]; then
    export KUBECONFIG=../scripts/fluidos-provider-1-edge-config
else
    export KUBECONFIG=../scripts/fluidos-provider-1-config
fi

# Delete all the resources
kubectl delete -f ../../deployments/node/crds
# Install all the resources
kubectl apply -f ../../deployments/node/crds

# Run the helm command
helm get values node -n fluidos > provider_values.yaml
helm uninstall node -n fluidos
eval "helm install node ../../deployments/node -n fluidos -f provider_values.yaml $IMAGE_SET_STRING" --set tag="$VERSION"
rm provider_values.yaml


