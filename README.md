# Overview
DOKS (DigitalOcean K8s) based Cassandra Cluster as part of the DO (DigitalOcean) K8s challenge (https://www.digitalocean.com/community/pages/kubernetes-challenge).  

# Implmentation
To provide scalable HA (High Availability) Cassndra noSQL K8s based the following componemnts are required:
1. DOCKS Cluster
   a. defaut cluster with 3 nodes;
   b. minimum of 4GB RAM and 2 CPU per node otherwise Cassandra fails to startup dur to limit settings;
3. K8s statefulset set (https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) required so state is mainted;
4. K8s service with ClusterIP set to None required for DNS lookup within cluster for Cassandra;
5. K8s StorageClass with volumeBindingMode set to WaitForFirstConsumer needed for dynamic persistent storage used to map Cassandra data whcih garentees anyscaling up/down data will be preserved;

# Setup
1) Following default environment vars are set which can be overriden if needed:
  export DO_REGION=ams3
  export DO_SIZE=s-2vcpu-4gb (dont set any smaller
2) Set name of DOKS and access token as such:
  export DOKS_NAME=myk8s
  export DO_ACCESS_TOKEN=mytoken
3) make sure all .sh are executable:
  chmod +x *.sh
  
  Run create script:
  ./doks_create.sh
4) 
 
  


use DOKS defaults
3 nodes
s-1vcpu-2gb

kubectl patch storageclass do-block-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl patch storageclass fast -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

