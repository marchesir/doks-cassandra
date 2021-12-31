#!/bin/bash

# set sensible defaults whcih can be overridden as needed.
# Cassandra is very memory hungary, still needs tweaking, ideally 8gb RAM is best.
export DO_REGION=ams3
export DO_SIZE=s-2vcpu-4gbs

echo "make sure DO_ACCESS_TOKEN and DOKS_NAME are set"
echo "creating DOKS Cluster with deafult paramters"

doctl kubernetes cluster create $DOKS_NAME --region $DO_REGION --size $DO_SIZE --access-token $DO_ACCESS_TOKEN
