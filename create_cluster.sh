#!/bin/bash

# Template
KIND_TEMPLATE="cluster_template.yaml"

# Tempfiles
TEMP_DIR="${PWD}/generated"
KIND_CONFIG="${TEMP_DIR}/kind_cluster.yaml"
CALICO_RESOURCE_FILE="${TEMP_DIR}/calico.yaml"
TIGERA_OPERATOR_FILE="${TEMP_DIR}/tigera_operator.yaml"

# Cluster Config
K8_VERSION="1.31.0"
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
CLUSTER_NAME="cluster01"

function create_temp_dir(){
    if [ ! -d $TEMP_DIR ]
    then
        mkdir -p $TEMP_DIR
    fi
}

function download_and_configure_calico_files() {
    CALICO_RESOURCE_URL="https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/calico.yaml"
    
 
    echo "Downloading $CALICO_RESOURCE_FILE"
    curl -s "${CALICO_RESOURCE_URL}" -o "${CALICO_RESOURCE_FILE}" || { echo "Failed to download $CALICO_RESOURCE_FILE"; exit 1; }

    # Replace Calico CIDR with Cluster's POD CIDR
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|192\.168\.0\.0\/16|${POD_CIDR}|" "$CALICO_RESOURCE_FILE"
    else
        sed -i "s|192\.168\.0\.0\/16|${POD_CIDR}|" "$CALICO_RESOURCE_FILE"
    fi
}

function generate_cluster_config() {
    CLUSTER_NAME=$CLUSTER_NAME POD_CIDR=$POD_CIDR SERVICE_CIDR=$SERVICE_CIDR envsubst < $KIND_TEMPLATE > $KIND_CONFIG
}

function clean_up() {
    echo "Cleaning up temporary files..."
    rm -rf $TEMP_DIR
}

function create_cluster() {
    echo "Creating KIND cluster..."
    kind create cluster --config $KIND_CONFIG --image kindest/node:v$K8_VERSION || { echo "Failed to create KIND cluster"; exit 1; }

    echo "Waiting for cluster to become ready..."
    until kubectl get nodes &>/dev/null; do
        sleep 5
    done

    echo "Applying Calico resources..."
    kubectl apply -f $CALICO_RESOURCE_FILE || { echo "Failed to apply Calico resources"; exit 1; }
}


function dependencies_check(){
    # Ensure dependencies are installed
    if ! command -v kind &> /dev/null; then
        echo "KIND is required but not installed. Exiting."
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        echo "kubectl is required but not installed. Exiting."
        exit 1
    fi

    if ! command -v envsubst &> /dev/null; then
        echo "envsubst is required but not installed. Exiting."
        exit 1
    fi
}

function main() {
    dependencies_check
    create_temp_dir
    download_and_configure_calico_files
    generate_cluster_config
    create_cluster
    clean_up
}

main