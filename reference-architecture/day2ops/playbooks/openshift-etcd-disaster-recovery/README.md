# openshift-etcd-disaster-recovery
An UNSUPPORTED ETCD failover process for dealing with spanning across two datacenters.

This process is based on instructions from access.redhat.com based on 3.9:
https://access.redhat.com/documentation/en-us/openshift_container_platform/3.9/html/cluster_administration/assembly_restore-etcd-quorum

1. Simulate an ETCD failure 
```
ansible-playbook playbooks/ocp-etc-dr-simulate.yml
```
This play stops the etcd services on the primary etcd group. This is meant to simulate a datacenter failure in DC_A (quorum).

2. Recover ETCD with a single RW node
```
ansible-playbook playbooks/ocp-etc-dr-recover.yml
```
This play runs on the secondary etcd group. It adds the following option into etcd.conf 'ETCD_FORCE_NEW_CLUSTER='. This allows for etcd read write on the cluster with a single node. 

3. Recover ETCD by rejoining with the recovered node
```
ansible-playbook playbooks/ocp-etc-dr-recover.yml
```
- This play runs on the primary etcd group. The following command is executed and the nodes are added back manually to the cluster:

```
etcdctl -C https://{{ hostvars[groups['etcd-sec'][0]].ansible_default_ipv4.address }}:2379 --cert-file /etc/etcd/peer.crt --key-file /etc/etcd/peer.key --ca-file /etc/etcd/ca.crt member add {{ ansible_hostname }} https://{{ ansible_default_ipv4.address }}:2380 2>/dev/null | grep '^ETCD_INITIAL_CLUSTER='
```

- The resulting output gives the: ETCD_INITIAL_CLUSTER.

- Then etcd.conf is modified with the following values:
  ETCD_NAME
  ETCD_INITIAL_CLUSTER
  ETCD_INITIAL_CLUSTER_STATE

The important value in this is the 'ETCD_INITIAL_CLUSTER_STATE=existing'

- The services are restarted and etcd is restored.

4. Recover ETCD by adding two new nodes
# TODO:

Recover ETCD by adding two new nodes

# Credits
The original version of this work was put together by William Burton.

Originally cloned from here:
https://github.com/abaxo/openshift-etcd-disaster-recovery

