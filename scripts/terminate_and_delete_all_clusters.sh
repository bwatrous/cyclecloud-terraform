#!/bin/bash

echo "Terminating and Deleting ALL CycleCloud clusters!"

retries=0
while true; do
    retries=$[$retries+1]
    
    #STARTED_CLUSTERS=$( cyclecloud show_nodes -f 'ClusterName  isnt undefined && State isnt undefined && State != "Terminated"' --output="%(ClusterName)s" | sort -u | sed -e 's/^[[:space:]]*//' )
    STARTED_CLUSTERS=$( /opt/cycle_server/cycle_server execute --format csv 'select ClusterName from Cloud.Cluster where State isnt undefined && State != "Terminated"' | grep -v ClusterName )
	
    if [ ! -z "$STARTED_CLUSTERS" ]; then
		echo "Waiting for clusters to terminate: [$retries]"
		
		for CLUSTER in ${STARTED_CLUSTERS}; do
			if [ $retries -gt 10 ]; then
				echo "Giving up on terminating ${CLUSTER}..."
				cyclecloud show_cluster ${CLUSTER}
				break
			else
				cyclecloud terminate_cluster ${CLUSTER}
			fi
		done
		sleep 60     
    else
		echo "All clusters terminated."
		break
    fi
done



retries=0
while true; do
    retries=$[$retries+1]
    
    # CREATED_CLUSTERS=$( cyclecloud show_nodes -f 'ClusterName  isnt undefined' --output="%(ClusterName)s" | sort -u | sed -e 's/^[[:space:]]*//' )
    CREATED_CLUSTERS=$( /opt/cycle_server/cycle_server execute --format csv 'select ClusterName from Cloud.Cluster' | grep -v ClusterName )
	
	if [ ! -z "$CREATED_CLUSTERS" ]; then
		echo "Waiting for clusters to delete: [$retries]"
		
		for CLUSTER in ${CREATED_CLUSTERS}; do
			if [ $retries -gt 10 ]; then
				echo "Force deleting ${CLUSTER}..."
				cyclecloud delete_cluster ${CLUSTER} --force
			else
				cyclecloud delete_cluster ${CLUSTER}
			fi
		done
		sleep 60     
    else
		echo "All clusters deleted."
		break
    fi
done



