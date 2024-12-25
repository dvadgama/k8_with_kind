# k8 With Kind

A repository to record some learning/testing done with Kubernetes using KinD

Current Script, setups multi-node cluster with `3 controlplane` and, `3 worker nodes` with `Calico CNI`

Note:
- this installation does not make use of the tigera operator
  
## Useage
Execute following command to setup your cluster

```bash
./create_cluster.sh
```
### Minimum System Requirements
- 4 GB Memory
-  2 CPU

# Feature
- Multi node cluster
- Calico CNI 