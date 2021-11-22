## Components of a Kubernetes Cluster

### **Nodes**

There are two types of nodes in a kubernetes cluster. Master node and Slave node. Master nodes control the cluster and the slaves run the pods.

### _Components of **Master Node**_

- **API Server**
  - This is the only entry point through which one can interact with the cluster
- **Scheduler**
  - Scheduler is responsible to find appropriate nodes and schedule tasks for them. API server talks to the scheduler when a new resource is requested.
- **Controller Manager**
  - Controller Manager detects and manages health of the pods. If a pod dies, CM will detect that from _etcd_ and tell the Scheduler to re schedule those dead pods. The scheduler then will talk to the kubelet on the worker nodes and they will manage curresponding pods.
- **etcd**
  - This is where all the data of a cluster is stored. etcd stored the data as key-value pairs.

### Ingress Component

Ingress is what allows external traffic to get to the kubernetes cluster. There has to be an ingress controller node and ingress rules which defines the routes and its properties.

TLS is configured using ingress. TLS certificates can be stored as a secret and accessed and configured in the Ingress configuration.
