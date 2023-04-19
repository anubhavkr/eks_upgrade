#!/usr/bin/env bash

echo -e "\nChecking the status of each node in the cluster"

NODE_LIST=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

# Loop through each node and check its status
for NODE in $NODE_LIST
do
    NODE_STATUS=$(kubectl get node $NODE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')

    # Check if the node is not in the ready state
    if [ "$NODE_STATUS" != "True" ]
    then
        # Retry for up to 5 times
        for i in {1..5}
        do
            echo "Node $NODE is not in the ready state. Retrying in 2 minute..."
            sleep 120
            NODE_STATUS=$(kubectl get node $NODE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
            if [ "$NODE_STATUS" == "True" ]
            then
                echo "Node $NODE is now in the ready state"
                break
            fi
        done

        # If the node is still not in the ready state after 10 minutes, print its name
        if [ "$NODE_STATUS" != "True" ]
        then
            echo "Node $NODE is not in the ready state"
        fi
    else
        echo "Node $NODE is in the ready state"
    fi
done

echo -e "\nStatus of each node in the $CLUSTER_NAME for $NODE_GROUP"
kubectl get nodes

echo -e "\nChecking the status of each pod in the cluster"
# Get the list of all namespaces
NAMESPACE_LIST=$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
# Loop through each namespace and get the list of pods
for NAMESPACE in $NAMESPACE_LIST
do
    # Get the list of pods in the namespace
    POD_LIST=$(kubectl get pods -n $NAMESPACE -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

    # Loop through each pod and check its status
    for POD in $POD_LIST
    do
        POD_STATUS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.phase}')

        # Check if the pod is not in the running or completed state
        if [[ "$POD_STATUS" != "Running" && "$POD_STATUS" != "Succeeded" && "$POD_STATUS" != "Failed" ]]
        then
            # Retry for up to 5 times
            for i in {1..5}
            do
                echo "Pod $POD in namespace $NAMESPACE is not in the running state (status: $POD_STATUS). Retrying in 2 minute..."
                sleep 120
                POD_STATUS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.phase}')
                if [ "$POD_STATUS" == "Running" ]
                then
                    echo "Pod $POD in namespace $NAMESPACE is now in the running state"
                    break
                fi
            done
            # If the node is still not in the ready state after 10 minutes, print its name
            if [ "$POD_STATUS" != "Running" ]
            then
                echo "Pod $POD in namespace $NAMESPACE is not in the ready state"
            fi
        else
            echo "Pod $POD in namespace $NAMESPACE is in the running state"
        fi
    done
done
