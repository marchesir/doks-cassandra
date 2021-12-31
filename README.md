# Overview
DOKS (DigitalOcean K8s) based Cassandra Cluster as part of the DO (DigitalOcean) K8s challenge (https://www.digitalocean.com/community/pages/kubernetes-challenge).  

# Implementation
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
3. Make sure all .sh are executable:
   chmod +x *.sh <br/>
  
   Run create script:
   ./doks_create.sh (can take up to 10 mins)<br/> 
4. Verify cluster with kubectl get nodes -o wide command and the nodes and there properties will be displayed, e.g.:
   k8scassandra-default-pool-u6zte  v1.21.5   10.110.0.3    164.92.220.139   containerd://1.4.11<br/>
5. Fist lets install the K8s Cassandra service with kubectl apply -f cassandra-service.yml and verify with kubectl get service cassandra:<br/>
   cassandra   ClusterIP   None         <none>        9042/TCP   43s<br/>
   Note: CLUSTER_IP and EXTERNAL_IP are all empty as this serivice is needed fro DNS loopkup by Cassandra.
6. This step is very important as we need to create new SotrageClass and patch it so it becomes the default:
   1. Create storageclass fast with kubectl apply -f st.yml and verify all storageclasses with kubectl get sc:<br/>
      do-block-storage (default)   dobs.csi.digitalocean.com   Delete          Immediate              true                   16m<br/>
      fast                         dobs.csi.digitalocean.com   Delete          WaitForFirstConsumer   true                   23s<br/>
   
      As can be seen WaitForFirstConsumer is set on the fast storageclass.
   2. To make fast the default run the following 2 commands:<br/>
      kubectl patch storageclass do-block-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'<br/>
      kubectl patch storageclass fast -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'<br/>
   3. Verify the fast storageclass is now default with kubectl get sc:<br/>
    do-block-storage   dobs.csi.digitalocean.com   Delete          Immediate              true                   20m<br/>
    fast (default)     dobs.csi.digitalocean.com   Delete          WaitForFirstConsumer   true                   5m2s<br/>
7. Now all components are installed leaving the Cassandra statefulset which includes the following: 
   1. Google docker image with Cassandra and required tools;
   2. CPU/Memory limits of 0.25% CPI and 1Gb RAM;
   3. Dynamic Persistent Storage to map Cassandra Data;
   4. Configuration of Cassandra DataCenter/Ring with 2 inital pods;
8. Install with kubectl apply -f cassandra-statefulset.yml, this part can take sometime to spinup:
   1. Pods may report "readiness probe failed" error, but actually Cassandra is ok;
   2. Verify K8s events are all ok with kubectl get events --sort-by=.metadata.creationTimestamp;
   3. Next lets check the statefulset with kubectl get statefulset cassandra:<br/>
      cassandra   2/2     7m<br/>
   4. Now lets verify the pods with kubectl get pods:<br/>
   cassandra-0   1/1     Running   0          8m11s<br/>
   cassandra-1   1/1     Running   0          7m14s<br/>
   5. If desired the Cassandra raw logs can be tailed as such per pod:<br/>
   kubectl logs -f cassandra-0
9. Verify Cassandra Cluster (DC/Ring) is by running following command on any Cassandra Node/Pod:<br/>
   kubectl exec -it cassandra-0 -- nodetool status    
   Datacenter: DC1-Cassandra1<br/>
   ==========================<br/>
   Status=Up/Down<br/>
   |/ State=Normal/Leaving/Joining/Moving<br/>
   --  Address       Load       Tokens       Owns (effective)  Host ID                               Rack<br/>
   UN  10.244.0.85   65.81 KiB  32           100.0%            0d8fedd1-ee5a-49b4-9ffa-0a0efcd291ac  Rack1-Cassandra1<br/>
   UN  10.244.1.235  104.55 KiB 32           100.0%            b7b22f5b-f549-4f05-9c44-db9df44cd52c  Rack1-Cassandra1<br/>
 
   This shows all is up and running.
10. Verify each pod has its persistent storage created with kubectl get pv:<br/>
    pvc-6f1047eb-485d-4390-8b65-b54382a248bc   1Gi        RWO            Delete           Bound    default/cassandra-data-cassandra-0   fast<br/>               
    pvc-d9f6b30a-261c-46ac-b4d1-9953e043e4d0   1Gi        RWO            Delete           Bound    default/cassandra-data-cassandra-1   fast<br/>                   
    As can be seen 2 1Gi persistent storage disks have been created per Pod.
10. Test scaling with the following command to go from 2 pods to 3:<br/>
    kubectl scale statefulsets cassandra --replicas=3
    
    Verify with kubectl get pods or kubectl get statefulset cassandra and then verify Cassandra Cluster state with kubectl exec -it cassandra-0 -- nodetool     
    status.
   
    finally rerun scale command and set back to 2 and Pods will be reduced back to 2, in this case Cassandra will drain the data from the dieing Pod and push it     to the remianing live Pods.  Running kubectl get pv shows the persistent storage of the dead Pod is still present.

# Conclusion
There are many improvements required to make thsi more "production ready":
1. Add dedicated namespace combined with RBAC for better management/security;
2. Add HPA (Horizontal Pod Scaler) to automatically size the cluster better bases on resources;
3. Tweak node size to best fit Cassandra needs;
4. Create custom Dockerfile to better fit needs;
5. Fix health check error "readiness probe failed" by understanding why Cassandra causes K8s to fail and add maybe CRD or simular;
6. Package all via helm or even kustomize;
   
   
   
   
   
