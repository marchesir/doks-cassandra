#!/bin/bash

echo "make sure DO_ACCESS_TOKEN, DOKS_NAME and DO_REGION are set"
echo "deleting DOKS Cluster with deafult paramters"

doctl kubernetes cluster delete $DOKS_NAME --access-token $DO_ACCESS_TOKEN --force 
