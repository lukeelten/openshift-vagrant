# Notice
This repository has been forked from [openshift/openshift-ansible-contrib](https://github.com/openshift/openshift-ansible-contrib/tree/master/vagrant).

# OpenShift Vagrant 
This is a Vagrant based project that demonstrates an advanced Openshift Origin 3.10 installation process using an Ansible playbook.



## Prerequisites

* Vagrant
* VirtualBox or Libvirt (--provider=libvirt)


Install the following vagrant plugins:
* landrush
* vagrant-hostmanager
* vagrant-sshfs
* vagrant-reload (optional)



The OS for the origin install defaults to centos but can be overridden by the following environment variable

    export ORIGIN_OS=<desired OS>

## Installation

```bash
./install_plugins.sh
vagrant up
```

Two ansible playbooks will start on admin1 after it has booted. The first playbook bootstraps the pre-requisites for the Openshift install. The second playbook is the actual Openshift install. The inventory for the Openshift install is declared inline in the Vagrantfile.

The install comprises one master and two nodes. The NFS share gets created on admin1.


## Login to your cluster

```bash
oc login https://master1.example.com:8443 -u admin -p admin123
```

Login to the web console on https://master1.example.com:8443 with user "admin" and password "admin123".


## Troubleshooting
The landrush plugin creates a small DNS server to that the guest VMs can resolve each others hostnames and also the host can resolve the guest VMs hostnames. The landrush DNS server is listens on 127.0.0.1 on port 10053. It uses a dnsmasq process to redirect dns traffic to landrush. If this isn't working verify that:

    cat /etc/dnsmasq.d/vagrant-landrush

gives

    server=/example.com/127.0.0.1#10053

and that /etc/resolv.conf has an entry

    # Added by landrush, a vagrant plugin
    nameserver 127.0.0.1
