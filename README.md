# doks-cassandra
DigitalOcean Managed K8s Cassandra Cluster

use DOKS defaults
3 nodes
s-1vcpu-2gb

kubectl patch storageclass do-block-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl patch storageclass fast -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

