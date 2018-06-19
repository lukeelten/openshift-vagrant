# openshift-etcd-disaster-recovery
An ETCD failover process for dealing with spanning across two datacenters.

This process is based on instructions from access.redhat.com based on 3.9:
https://access.redhat.com/documentation/en-us/openshift_container_platform/3.9/html/cluster_administration/assembly_restore-etcd-quorum

1. Simulate an ETCD failure
2. Recover ETCD with a single RW node
3. Recover ETCD by rejoining with the recovered node
4. Recover ETCD by adding two new nodes

# TODO:
Recover ETCD by adding two new nodes

# Credits
The original version of this work was put together by William Burton.

Originally cloned from here:
https://github.com/abaxo/openshift-etcd-disaster-recovery

