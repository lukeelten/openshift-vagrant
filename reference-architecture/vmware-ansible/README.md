# The Reference Architecture OpenShift on VMware

**NOTE: This repository contains deprecated scripts and ansible playbooks. Refer to the official documentation [Deploying and Managing OpenShift 3.9 on VMware vSphere](https://access.redhat.com/documentation/en-us/reference_architectures/2018/html-single/deploying_and_managing_openshift_3.9_on_vmware_vsphere/)**

This repository contains the scripts used to deploy an OpenShift environment based off of the Reference Architecture Guide for OpenShift 3.6 on VMware

## Overview
The repository contains Ansible playbooks which deploy 3 masters, 3 infrastructure nodes and 3 application nodes. All nodes could utilize anti-affinity rules to separate them on the number of hypervisors you have allocated for this deployment. The playbooks deploy a Docker registry and scale the router to the number of Infrastruture nodes.

![Architecture](images/OCP-on-VMware-Architecture.jpg)

## Prerequisites and Usage

- Make sure your public key is copied to your template.

- Internal DNS should be set up to reflect the number of nodes in the environment. The default "VM network" should have a contiguous static IP addresses set up for initial provisioning.

- The code in this repository handles all of the VMware specific components except for the installation of OpenShift.


The following commands should be issued from the deployment host:
```
# yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# yum install -y ansible git python2-pyvmomi
$ cd ~/git/
$ git clone -b vmw-3.9 https://github.com/openshift/openshift-ansible-contrib
$ cd openshift-ansible-contrib/reference-architecture/vmware-ansible/ 
$ cp inventory/vsphere/vms/inventory39 /etc/ansible/hosts
```

Copy the SSH pub key to the template:
```bash
ssh-copy-id root@template_ip_address
```

Next fill out the variables in the inventory file

```bash
$ vim /etc/ansible/hosts 
```

### VMware Template Name
The variable `openshift_cloudprovider_vsphere_template` is the VMware template name it should have RHEL 7.5 installed with the open-vm-tools package.

### New VMware Environment (Greenfield)
When configuring a Greednfield cluster the following components can be deployed:

- HAproxy VM
- NFS VM for registry
- 3 Master OpenShift VMs
- 3 Infrastructure OpenShift VMs
- 3 Application nodes OpenShift VMs

```bash
$ cd ~/git/openshift-ansible-contrib/reference-architecture/vmware-ansible/
$ cat /etc/ansible/hosts | egrep 'rhsub|ip'
rhsub_user=rhn_username
rhsub_pass=rhn_password
rhsub_pool=8a85f9815e9b371b015e9b501d081d4b
infra-0  openshift_node_labels="{'region': 'infra'}" ipv4addr=10.x.y.8
infra-1  openshift_node_labels="{'region': 'infra'}" ipv4addr=10.x.y.9
infra-2  openshift_node_labels="{'region': 'infra'}" ipv4addr=10.x.y.13
app-0  openshift_node_labels="{'region': 'app'}" ipv4addr=10.x.y.10
app-1  openshift_node_labels="{'region': 'app'}" ipv4addr=10.x.y.11
...omitted...
$ ansible-playbook playbooks/prod.yaml
```

If an HAproxy instance is required it can also be deployed.

```bash
$ ansible-playbook playbooks/haproxy.yaml
```

Lastly, the prepared VMs must correspond to the following hardware requirements:

|Node Type | CPUs | Memory | Disk 1 | Disk 2 | Disk 3 | Disk 4 |
| ------- | ------- | ------- | ------- | ------- | ------- | ------- |
| Master  | 2 vCPU | 16GB RAM | 1 x 60GB - OS RHEL 7.4 | 1 x 40GB - Docker volume | 1 x 40Gb -  EmptyDir volume | 1 x 40GB - ETCD volume |
| Node | 2 vCPU | 8GB RAM | 1 x 60GB - OS RHEL 7.4 | 1 x 40GB - Docker volume | 1 x 40Gb - EmptyDir volume | |

```
### Adding a node to an existing OCP cluster
Please use the following process for adding a node to a cluster:
https://access.redhat.com/solutions/3003411

### Container Storage

#### Using CNS or CRS - Container Native Storage or Container Ready Storage

```bash
$ sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
$ sudo yum install -y python2-pyvmomi
$ git clone -b vmw-3.9 https://github.com/openshift/openshift-ansible-contrib
$ cd openshift-ansible-contrib/reference-architecture/vmware-ansible/

$ cat /etc/ansible/hosts
rhsub_user=rhn_username
rhsub_pass=rhn_password
rhsub_pool=8a85f9815e9b371b015e9b501d081d4b
[storage]
cns-0  openshift_node_labels="{'region': 'infra'}" ipv4addr=10.x.y.33
cns-1  openshift_node_labels="{'region': 'infra'}" ipv4addr=10.x.y.34
cns-2  openshift_node_labels="{'region': 'infra'}" ipv4addr=10.x.y.35
...omitted...

$ ansible-playbook playbooks/cns-storage.yaml

$ cat /etc/ansible/hosts
...omitted...
# CNS registry storage
openshift_hosted_registry_storage_kind=glusterfs
openshift_hosted_registry_storage_volume_size=30Gi

# CNS storage cluster for applications
openshift_storage_glusterfs_namespace=app-storage
openshift_storage_glusterfs_storageclass=true
openshift_storage_glusterfs_block_deploy=false

# CNS storage for OpenShift infrastructure
openshift_storage_glusterfs_registry_namespace=infra-storage
openshift_storage_glusterfs_registry_storageclass=false
openshift_storage_glusterfs_registry_block_deploy=true
openshift_storage_glusterfs_registry_block_storageclass=true
openshift_storage_glusterfs_registry_block_storageclass_default=false
openshift_storage_glusterfs_registry_block_host_vol_create=true
openshift_storage_glusterfs_registry_block_host_vol_size=100
# 100% Dependent on sizing for logging and metrics

[glusterfs]
cns-0  glusterfs_devices='[ "/dev/sdd" ]'
cns-1  glusterfs_devices='[ "/dev/sdd" ]'
cns-2  glusterfs_devices='[ "/dev/sdd" ]'
[glusterfs_registry]
infra-0  glusterfs_devices='[ "/dev/sdd" ]'
infra-1  glusterfs_devices='[ "/dev/sdd" ]'
infra-2  glusterfs_devices='[ "/dev/sdd" ]'
...omitted...

# After the installation has been completed, metrics can be added via the following process.
$ cat /etc/ansible/hosts
...omitted...
# metrics
openshift_metrics_install_metrics=true
openshift_metrics_hawkular_nodeselector={"role":"infra"}
openshift_metrics_cassandra_nodeselector={"role":"infra"}
openshift_metrics_heapster_nodeselector={"role":"infra"}
openshift_metrics_cassanda_pvc_storage_class_name="glusterfs-registry-block"
openshift_metrics_cassandra_pvc_size=25Gi
openshift_metrics_storage_kind=dynamic
...omitted...

$ ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/openshift-metrics/config.yml

# Now logging
$ cat /etc/ansible/hosts
...omitted...
# logging
openshift_logging_install_logging=true
openshift_logging_es_cluster_size=3
openshift_logging_es_nodeselector={"role":"infra"}
openshift_logging_kibana_nodeselector={"role":"infra"}
openshift_logging_curator_nodeselector={"role":"infra"}
openshift_logging_es_pvc_storage_class_name="glusterfs-registry-block"
openshift_logging_es_pvc_size=10Gi
openshift_logging_storage_kind=dynamic

$ ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/openshift-logging/config.yml 
```

