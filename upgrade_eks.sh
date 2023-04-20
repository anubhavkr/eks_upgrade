#!/usr/bin/env bash

# Get List of Clusters
EKS_CLUSTER=$(aws eks list-clusters | jq -r .clusters[])
if [ $? -ne 0 ]; then 
    echo "Please check your AWS authentication!"
    exit 1
fi
eks_options=($EKS_CLUSTER)

echo "Please select cluster..."
PS3="Enter a number (1-${#eks_options[@]}): "

select eks_option in "${eks_options[@]}"; do
    export CLUSTER_NAME=$eks_option
    break
done

# Get List of Node Groups
NODE_GROUP=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME  | jq -r .nodegroups[])
node_options=($NODE_GROUP)
echo -e "\nPlease select node group..."
PS3="Enter a number (1-${#node_options[@]}): "

select node_option in "${node_options[@]}"; do
    export NODE_GROUP=$node_option
    break
done    

echo -e "\nCluster Name = $CLUSTER_NAME"
echo -e "NodeGroup=$NODE_GROUP"

echo -e "\n## Pre-Activity Validation Before Upgrade=>"

# Get Current EKS Cluster Version
CURRENT_EKS_VERSION=$(aws eks describe-cluster --name $CLUSTER_NAME | jq -r .cluster.version)
echo -e "\nCurrent EKS Version = $CURRENT_EKS_VERSION"

echo -e "NodeGroup=$NODE_GROUP"

# Get current releaseVersion
RELEASE_VERSION=$(aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP --query 'nodegroup.releaseVersion' --output text)
echo -e "Release Version = $RELEASE_VERSION"

# Get AG Name
AG=$(aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP --query 'nodegroup.resources.autoScalingGroups[0].name' --output text)
echo -e "AG Name = $AG"

## Get Instance ID under Node Group
#INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $AG --query 'AutoScalingGroups[].Instances[].InstanceId' --output text)
#echo -e "Instance-IDs = $INSTANCE_ID"

read -rep $'\nPlease provide the desired K8S version:\n' k8s_version

echo -e "\n## Upgradation Node Group =>"
echo -e "\nUpgrade $NODE_GROUP to version $k8s_version. block is commented !"

# Upgrade Node Group
#aws eks update-nodegroup-version --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP --kubernetes-version $k8s_version

echo -e "\nChecking status of node group $NODE_GROUP in cluster $CLUSTER_NAME..."

while true; do
    STATUS=$(aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP --query 'nodegroup.status' --output text)
    
    if [ "$STATUS" == "ACTIVE" ]; then
        echo "Node group $NODE_GROUP is now active."
        break
    elif [ "$STATUS" == "UPDATING" ]; then
        echo "Node group $NODE_GROUP is updating. Sleeping for 3 minutes before checking again..."
        sleep 180
    else
        echo "Node group $NODE_GROUP is in status: $STATUS. Aborting..."
        exit 1
    fi
done

echo -e "\nNode group $NODE_GROUP is successfully upgraded!!!"

echo -e "\n## Post-Activity Validation After Upgrade=>"

# Get Current EKS Cluster Version
CURRENT_EKS_VERSION=$(aws eks describe-cluster --name $CLUSTER_NAME | jq -r .cluster.version)
echo -e "\nEKS Version = $CURRENT_EKS_VERSION"

# Get current releaseVersion
RELEASE_VERSION=$(aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP --query 'nodegroup.releaseVersion' --output text)
echo -e "Release Version = $RELEASE_VERSION"

## Get Instance ID under Node Group
#INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $AG --query 'AutoScalingGroups[].Instances[].InstanceId' --output text)
#echo -e "Instance-IDs = $INSTANCE_ID"

echo -e "\n"
