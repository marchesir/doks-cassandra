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
1. Following default environment vars are set which can be overriden if needed:
  export DO_REGION=ams3
  export DO_SIZE=s-2vcpu-4gb (dont set any smaller)
2. Set name of DOKS and access token as such:
  export DOKS_NAME=myk8s
  export DO_ACCESS_TOKEN=mytoken
3. make sure all .sh are executable:
  chmod +x *.sh
  
  Run create script:
  ./doks_create.sh (can take up to 10 mins)
4. Verify cluster with kubectl get nodes -o wide command and Something like below will be displayed:
NAME                              STATUS   VERSION   INTERNAL-IP   EXTERNAL-IP      OS-IMAGE                       KERNEL-VERSION          CONTAINER-RUNTIME
k8scassandra-default-pool-u6zte   Ready    v1.21.5   10.110.0.3    164.92.220.139   Debian GNU/Linux 10 (buster)   4.19.0-17-cloud-amd64   containerd://1.4.11
k8scassandra-default-pool-u6ztg   Ready    v1.21.5   10.110.0.5    164.92.220.154   Debian GNU/Linux 10 (buster)   4.19.0-17-cloud-amd64   containerd://1.4.11
k8scassandra-default-pool-u6ztw   Ready    v1.21.5   10.110.0.4    164.92.220.145   Debian GNU/Linux 10 (buster)   4.19.0-17-cloud-amd64   containerd://1.4.11
5. Fist lets install the K8s Cassandra service with kubectl apply -f cassandra-service.yml and verify with kubectl get service cassandra:
NAME        TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
cassandra   ClusterIP   None         <none>        9042/TCP   43s

Note CLUSTER_IP and EXTERNAL_IP are all empty as this serivice is needed fro DNS loopkup by Cassandra.
6. This step is very important as we need to create new SotrageClass and patch it so it becomes the default:
   1. create storageclass fast with kubectl apply -f st.yml and verify all storageclasses with kubectl get sc:
     NAME                         PROVISIONER                 RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
     do-block-storage (default)   dobs.csi.digitalocean.com   Delete          Immediate              true                   16m
     fast                         dobs.csi.digitalocean.com   Delete          WaitForFirstConsumer   true                   23s
   
    As can be seen WaitForFirstConsumer is set on the fast storageclass.
  2. To make fast the default run the following 2 commands:
    kubectl patch storageclass do-block-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
    kubectl patch storageclass fast -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  3. Verify the fast storageclass is now default with kubectl get sc:
    NAME               PROVISIONER                 RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
    do-block-storage   dobs.csi.digitalocean.com   Delete          Immediate              true                   20m
    fast (default)     dobs.csi.digitalocean.com   Delete          WaitForFirstConsumer   true                   5m2s
7. Now all components are installed leaving the Cassandra statefullset which includes the following: 
   1. google docker image with Cassandra and required tools;
   2. CPU/Memory limits of 0.25% CPI and 1Gb RAM;
   3. Dynamic Persistent Storage to map Cassandra Data;
   4. Configuration of Cassandra DataCenter/Ring with 2 inital pods;
8. Install with kubectl apply -f cassandra-statefulset.yml, this part can take sometime to spinup, pods may report the following error:
   1. readiness probe failed, but actually Cassandra is ok;
   2. Verify K8s events are all ok with kubectl get events --sort-by=.metadata.creationTimestamp
   3. Next lets check the statefulset with kubectl get statefulset cassandra:
      NAME        READY   AGE
      cassandra   2/2     7m
   4. Now lets verify the pods with kubectl get pods:
   NAME          READY   STATUS    RESTARTS   AGE
   cassandra-0   1/1     Running   0          8m11s
   cassandra-1   1/1     Running   0          7m14s
   5. If desired the Cassandra raw logs can be tailed as such per pod:
   kubectl logs -f cassandra-0
9. Verify Cassandra Cluster (DC/Ring) is by running following command on any Cassandra Node/Pod:
   kubectl exec -it cassandra-0 -- nodetool status    
   Datacenter: DC1-Cassandra1
   ==========================
   Status=Up/Down
   |/ State=Normal/Leaving/Joining/Moving
   --  Address       Load       Tokens       Owns (effective)  Host ID                               Rack
   UN  10.244.0.85   65.81 KiB  32           100.0%            0d8fedd1-ee5a-49b4-9ffa-0a0efcd291ac  Rack1-Cassandra1
   UN  10.244.1.235  104.55 KiB 32           100.0%            b7b22f5b-f549-4f05-9c44-db9df44cd52c  Rack1-Cassandra1
 
   this show the all i sup and running.
10. Test scaling with the following
  
   
   
   
   
   
   
