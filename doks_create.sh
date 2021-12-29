#!/bin/bash

echo "make sure DO_ACCESS_TOKEN, DOKS_NAME and DO_REGION are set"
echo "creating DOKS Cluster with deafult paramters"

doctl auth init --access-token $DO_ACCESS_TOKEN
doctl kubernetes cluster create $DOKS_NAME --region $DO_REGION --access-token $DO_ACCESS_TOKEN
