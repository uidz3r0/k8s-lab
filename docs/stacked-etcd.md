# Stacked etcd

There are two common kubeadm HA topologies.

## Stacked etcd

Each control plane node runs its own local etcd member alongside the Kubernetes control plane components.

```
+-------------------+
| kube-apiserver    |
| controller-manager|
| scheduler         |
| etcd              |
+-------------------+
```

Advantages:

- Simple to deploy with kubeadm
- Fewer machines required
- Ideal for home labs and many production environments

Disadvantages:

- Control plane and etcd share the same hosts
- Scaling or recovering etcd is tied to the control plane nodes

---

## External etcd

A separate cluster of dedicated etcd servers is used.

```
Control Planes  --->  External etcd Cluster
```

Advantages:

- Better isolation
- Independent scaling and maintenance

Disadvantages:

- More infrastructure
- More complex setup and operations

For this course, we use **stacked etcd**, which is the default HA topology created by `kubeadm`.

---

## More Info

- The choice between stacked etcd and external etcd in Kubernetes depends on cluster scale, resilience requirements, and operational complexity.
- `Stacked etcd` co-locates the etcd datastore with control plane components on the same nodes, offering a simpler, lower-cost setup that requires a minimum of `3 nodes` and is best for clusters under `100-1000 nodes`.  
- `External etcd` runs the datastore on dedicated nodes separate from the control plane, providing `better fault isolation`, `scalability`, and `performance` but requiring a minimum of `6 nodes` and higher operational overhead. (nodes with NVMe SSDs)