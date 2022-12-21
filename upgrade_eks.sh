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

echo -e "\nCluster Name = $CLUSTER_NAME"

# Get Current EKS Cluster Version
CURRENT_EKS_VERSION=$(aws eks describe-cluster --name $CLUSTER_NAME | jq -r .cluster.version)
echo -e "\nCurrent EKS Version = $CURRENT_EKS_VERSION\n"

# Get List of Node Groups
NODE_GROUP=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME  | jq -r .nodegroups[])
node_options=($NODE_GROUP)
echo "Please select node group..."
PS3="Enter a number (1-${#node_options[@]}): "

select node_option in "${node_options[@]}"; do
    export NODE_GROUP=$node_option
    break
done    

echo -e "\nNodeGroup=$NODE_GROUP\n"

# Get AG Name
AG=$(aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP --query 'nodegroup.resources.autoScalingGroups[0].name' --output text)
echo "AG Name = $AG"

# Get Instance ID under Node Group
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $AG --query 'AutoScalingGroups[].Instances[].InstanceId' --output text)
echo -e "\nInstance-IDs = $INSTANCE_ID\n"

read -rep $'Please provide the desired K8S version:\n' k8s_version

echo -e "Upgrade node group to version $k8s_version block is commented !"

# Upgrade Node Group
#aws eks update-nodegroup-version --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP --kubernetes-version $k8s_version

