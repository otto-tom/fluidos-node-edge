#!/usr/bin/bash

SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# shellcheck disable=SC1091
source "$SCRIPT_DIR"/utils.sh

# PIDs of the processes in background
pids=()

# Function to handle errors
handle_error() {
    echo "An error occurred. Exiting..."
    for pid in "${pids[@]}"; do
        # Kill all the processes in background
        kill "$pid" 2>/dev/null
    done
    read -r -p "All the processes in background have been killed. Press enter to exit."
    return 1
}

# Function to handle exit
handle_exit() {
    echo "Exiting..."
    for pid in "${pids[@]}"; do
        # Kill all the processes in background
        kill "$pid" 2>/dev/null
    done
    # Ask the user if really wants to exit
    read -r -p "Do you really want to exit? [y/N] " answer
    if [ "$answer" == "y" ]; then
        return 0
    fi
}

# Build and load the docker image
build_and_load() {
    local COMPONENT="$1"
    local NAMESPACE="$2"
    local VERSION="$3"
    # Build the docker image
    docker build -q -f "$SCRIPT_DIR"/../../build/common/Dockerfile --build-arg COMPONENT="$COMPONENT" -t "$NAMESPACE"/"$COMPONENT":"$VERSION" "$SCRIPT_DIR"/../../

    echo "Docker image $NAMESPACE/$COMPONENT:$VERSION built"
    # For each cluster, load the docker image
    for cluster in "${!clusters[@]}"; do
        kind load docker-image "$NAMESPACE"/"$COMPONENT":"$VERSION" --name="$cluster"
    done
}

# Install remote components function
# Parameters:
# $1: consumer JSON tmp file
# $2: provider JSON tmp file
# $3: local repositories boolean
# $4: local resource manager boolean
# $5: kubernetes clusters type
# $6: network manager installation boolean
# Return: none
function install_components() {

    unset clusters
    declare -A clusters

    # Get consumer JSON tmp file from parameter
    consumers_json=$1

    # Get provider JSON tmp file from parameter
    providers_json=$2

    # Get the remote boolean from parameters
    local_repositories=$3

    # Get the local resource manager installation boolean from parameters
    enable_auto_discovery=$4

    # Get the kubernetes clusters type from parameters
    installation_type=$5

    # Get the network manager installation boolean from parameters
    enable_local_discovery=$6

    # Get the edge enable boolean from parameters
    edge_ena=$7

    helm repo add fluidos https://fluidos-project.github.io/node/

    # Read the results from the files
    while IFS= read -r line; do
        echo 
        name=$(echo "$line" | cut -d: -f1)
        info=$(echo "$line" | cut -d: -f2-)
        clusters["$name"]=$info
    done < "$consumers_json"

    while IFS= read -r line; do
        name=$(echo "$line" | cut -d: -f1)
        info=$(echo "$line" | cut -d: -f2-)
        clusters["$name"]=$info
    done < "$providers_json"
    
    # Print the clusters
    for cluster in "${!clusters[@]}"; do 
        echo "Cluster: $cluster"
        echo "Value: ${clusters[$cluster]}"
    done

    echo "Liqoctl version in installation.sh: $(liqoctl version 2>&1 | grep -oP 'Client version: \K\S+')"

    if [ "$local_repositories" == "true" ]; then
        unset COMPONENT_MAP
        declare -A COMPONENT_MAP
        COMPONENT_MAP["rear-controller"]="rearController.imageName"
        COMPONENT_MAP["rear-manager"]="rearManager.imageName"
        COMPONENT_MAP["edge-resource-manager"]="edgeResourceManager.imageName"
        COMPONENT_MAP["local-resource-manager"]="localResourceManager.imageName"
        COMPONENT_MAP["network-manager"]="networkManager.imageName"
        # Build the image name using the username
        IMAGE_SET_STRING=""
        DOCKER_USERNAME="fluidoscustom"
        VERSION="0.0.1"
        for component in rear-controller rear-manager edge-resource-manager local-resource-manager network-manager; do
            helm_key="${COMPONENT_MAP[$component]}"
            IMAGE_SET_STRING="$IMAGE_SET_STRING --set $helm_key=$DOCKER_USERNAME/$component"
            # Build and load the docker image
            (
                build_and_load $component $DOCKER_USERNAME $VERSION
            ) &
            # Save the PID of the process
            pids+=($!)
        done

        # Wait for each process and if any of them fails, generates a trap to be captured, which kills all the processes and exits
        for pid in "${pids[@]}"; do
            wait "$pid" || handle_error
            echo "Process $pid finished"
        done

        # Reset the pids array
        pids=()
    fi

    echo "Liqoctl version in installation.sh: $(liqoctl version 2>&1 | grep -oP 'Client version: \K\S+')"

    # Iterate over the clusters
    for cluster in "${!clusters[@]}"; do

        (
        echo "Cluster is: $cluster"
        echo "Cluster value is: ${clusters[$cluster]}"

        if alias liqoctl &>/dev/null; then
            liqoctl_path=$(alias liqoctl | sed -E "s/alias liqoctl='(.*)'/\1/")
        else
            liqoctl_path=$(which liqoctl)
        fi
        
        echo "Liqoctl version in installation.sh CLUSTER LOOP: $(liqoctl version 2>&1 | grep -oP 'Client version: \K\S+')"
        if [ -z "$liqoctl_path" ]; then
            liqoctl_path='/usr/local/bin/liqoctl'
        fi
        echo "Liqoctl path is: $liqoctl_path"

        # Get the kubeconfig file which depends on variable installation_type
        KUBECONFIG=$(jq -r '.kubeconfig' <<< "${clusters[$cluster]}")
        echo "The KUBECONFIG is $KUBECONFIG"

        # Setup CNI to enable multicast node discovery
        if [ "$enable_local_discovery" == "true" ]; then
            kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml --kubeconfig "$KUBECONFIG"
        fi
      
        # Decide value file to use based on the role of the cluster
        if [ "$(jq -r '.role' <<< "${clusters[$cluster]}")" == "consumer" ]; then
            # Check if local resouce manager is enabled
            if [ "$enable_auto_discovery" == "true" ]; then
                value_file="$SCRIPT_DIR/../../quickstart/utils/consumer-values.yaml"
            else
                value_file="$SCRIPT_DIR/../../quickstart/utils/consumer-values-no-ad.yaml"
            fi
            # Get control plane IP
            ip_value="${clusters[$cluster]}"
            ip=$(jq -r '.ip' <<< "$ip_value")
        else
            # Skip this installation if the cluster is a provider and its installation type is not kind
            if [ "$installation_type" != "kind" ]; then
                echo "Skipping network configuration in a cluster not managed by the user."
                return 0
            else
                # Check if local resouce manager is enabled
                if [ "$enable_auto_discovery" == "true" ]; then
                    value_file="$SCRIPT_DIR/../../quickstart/utils/provider-values.yaml"
                else
                    value_file="$SCRIPT_DIR/../../quickstart/utils/provider-values-no-ad.yaml"
                fi
                # Get control plane IP
                ip_value="${clusters[$cluster]}"
                ip=$(jq -r '.ip' <<< "$ip_value")
                fi
        fi

        # Install liqo
        chmod +x "$SCRIPT_DIR"/install_liqo.sh
        "$SCRIPT_DIR"/install_liqo.sh "$installation_type" "$cluster" "$KUBECONFIG" "$liqoctl_path" || { echo "Failed to install Liqo in cluster $cluster"; exit 1; }
        chmod -x "$SCRIPT_DIR"/install_liqo.sh

        # Skipping the installation of the node Helm chart if the cluster is a provider and its installation type is not kind
        if [ "$(jq -r '.role' <<< "${clusters[$cluster]}")" == "provider" ] && [ "$installation_type" != "kind" ]; then
            echo "Skipping FLUIDOS Node installation in a cluster not managed by the user"
            return 0
        else
            # Install the node Helm chart
            # The installation set statically all the other nodes as providers and the current node as the consumer
            echo "Installing node Helm chart in cluster $cluster"
            # If the installation does not use remote repository, the image is used the one built locally
            if [ "$local_repositories" == "true" ]; then
                # If the installation does not use remote repository, the CRDs are applied
                kubectl apply -f "$SCRIPT_DIR"/../../deployments/node/crds --kubeconfig "$KUBECONFIG"
                echo "Installing local repositories in cluster $cluster with local resource manager"
                # Execute command
                # shellcheck disable=SC2086
                helm upgrade --install node $SCRIPT_DIR/../../deployments/node \
                -n fluidos --create-namespace -f $value_file $IMAGE_SET_STRING \
                --set tag=$VERSION \
                --set "provider=$installation_type" \
                --set "common.configMaps.nodeIdentity.ip=$ip" \
                --set "networkManager.config.enableLocalDiscovery=$enable_local_discovery" \
                --set "networkManager.config.address.thirdOctet=${cluster: -1}" \
                --wait \
                --kubeconfig $KUBECONFIG
            else
                echo "Installing remote repositories in cluster $cluster with local resource manager"
                helm upgrade --install node fluidos/node -n fluidos --create-namespace -f "$value_file" \
                --set "provider=$installation_type" \
                --set "common.configMaps.nodeIdentity.ip=$ip" \
                --set "networkManager.config.enableLocalDiscovery=$enable_local_discovery" \
                --set "networkManager.config.address.thirdOctet=${cluster: -1}" \
                --wait \
                --kubeconfig "$KUBECONFIG"
            fi
        fi

        ) &
        # Save the PID of the process
        pids+=($!)

    done

    # Wait for each process and if any of them fails, generates a trap to be captured, which kills all the processes and exits
    for pid in "${pids[@]}"; do
        wait "$pid" || handle_error
        echo "Process $pid finished"
    done

    for cluster in "${!clusters[@]}"; do
        # Get the kubeconfig file which depends on variable installation_type

        if [ "$(jq -r '.role' <<< "${clusters[$cluster]}")" == "provider" ] && [ "$edge_ena" == "true" ]; then
            export KUBECONFIG=$(jq -r '.kubeconfig' <<< "${clusters[$cluster]}")
            echo "Found Edge enabled cluster: $cluster"
	        echo "Patching liqo for edge node"
            kubectl patch daemonset liqo-fabric --kubeconfig "$PWD/$cluster"-config --context "kind-$cluster" -n liqo -p '{"spec": {"template": {"spec": {"affinity": {"nodeAffinity": {"requiredDuringSchedulingIgnoredDuringExecution": {"nodeSelectorTerms": [{"matchExpressions": [{"key": "node-role.kubernetes.io/edge", "operator": "DoesNotExist"}]}]}}}}}}}' 1> $OUTPUT
            kubectl patch cronjob.batch liqo-telemetry --kubeconfig "$PWD/$cluster"-config --context "kind-$cluster" -n liqo -p '{"spec": {"jobTemplate": {"spec": {"template": {"spec": {"affinity": {"nodeAffinity": {"requiredDuringSchedulingIgnoredDuringExecution": {"nodeSelectorTerms": [{"matchExpressions": [{"key": "node-role.kubernetes.io/edge", "operator": "DoesNotExist"}]}]}}}}}}}}}' 1> $OUTPUT
            worker=""$cluster"-worker2"
            worker_node=$(docker ps --filter "name=$worker" -q)
            echo "Label edge worker node with fluidos tags"
            kubectl label nodes "$worker" node-role.fluidos.eu/edge-worker=true 1> $OUTPUT
            kubectl label nodes "$worker" node-role.fluidos.eu/sensors=true 1> $OUTPUT
            echo "Install the MQTT broker for the worker node"
            docker exec --privileged -it $worker_node apt-get update 1> $OUTPUT
            docker exec --privileged -it $worker_node apt-get install -y mosquitto 1> $OUTPUT
            docker cp "../../quickstart/kind/configs/mqtt_access.conf" $worker_node:/etc/mosquitto/conf.d 1> $OUTPUT
            docker exec --privileged -it $worker_node systemctl enable mosquitto 1> $OUTPUT
            docker exec --privileged -it $worker_node systemctl start mosquitto 1> $OUTPUT
            echo "Install default BT Device Model"
            kubectl apply -f "$PWD"/../../quickstart/edge/cloudcore/manifests/samples/devices/SensorTile-BLE-Device-Model.yaml --kubeconfig "$PWD/$cluster"-config --context "kind-$cluster" 1> $OUTPUT
            echo "Install default BT Device Instance"
            kubectl apply -f "$PWD"/../../quickstart/edge/cloudcore/manifests/samples/devices/SensorTile-BLE-Instance_tb.yaml --kubeconfig "$PWD/$cluster"-config --context "kind-$cluster" 1> $OUTPUT
        fi
    done

}
