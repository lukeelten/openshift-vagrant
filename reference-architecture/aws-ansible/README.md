
# DEPRECATED
This code has been deprecated please check the directory https://github.com/openshift/openshift-ansible-contrib/tree/master/reference-architecture/3.9/playbooks and the new reference architecture document 
https://access.redhat.com/documentation/en-us/reference_architectures/2018/html/deploying_and_managing_openshift_3.9_on_amazon_web_services/

# The Reference Architecture OpenShift on Amazon Web Services
This repository contains the scripts used to deploy an OpenShift Container Platform or OpenShift Origin environment based off of the Reference Architecture Guide for OCP 3.6 on Amazon Web Services.

## Overview
The repository contains Ansible playbooks which deploy 3 masters in different availability zones, 3 infrastructure and 2 application nodes. The infrastructure and application nodes are split between availability zones. The playbooks deploy a Docker registry and scale the router to the number of infrastructure nodes.

![Architecture](images/arch.jpg)

## Prerequisites
A registered domain must be added to Route53 as a Hosted Zone before installation. This registered domain can be purchased through AWS.

### Deploying OpenShift Container Platform
The code in this repository handles all of the AWS specific components except for the installation of OpenShift. We rely on the OpenShift playbooks from the openshift-ansible-playbooks rpm. You will need the rpm installed on the workstation before using ose-on-aws.py. Do not perform the following within a container as errors have been found when attempting to run subscription-manager. It is advised to use a VM or bare metal installation of RHEL.

```
$ subscription-manager repos --enable rhel-7-server-optional-rpms
$ subscription-manager repos --enable rhel-7-server-ose-3.6-rpms
$ subscription-manager repos --enable rhel-7-fast-datapath-rpms
$ yum -y install atomic-openshift-utils ansible openshift-ansible-playbooks
$ rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
$ yum -y install python2-boto \
                 pyOpenSSL \
                 git \
                 python-netaddr \
                 python-six \
                 python2-boto3 \
                 python-click \
                 python-httplib2 \
                 python-passlib \
                 httpd-tools \
                 java-1.8.0-openjdk-headless
```

### Deploying OpenShift Origin
The playbooks in the repository also have the ability to configure CentOS or RHEL instances to prepare for the installation of Origin. Due to the OpenShift playbooks not being available in RPM format outside of a OpenShift Container Platform subscription the openshift-ansible repository must be cloned. At this time, the following cannot be performed within a container due to known issues that have been found while running openshift-ansible in a container. It is advised to use a virtual or bare metal machine.

```
$ rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
$ yum -y install python-pip git python2-boto \
                 python-netaddr python-httplib2 python-devel \
                 gcc libffi-devel openssl-devel python2-boto3 \
                 python-click python-six python-passlib pyOpenSSL \
                 httpd-tools java-1.8.0-openjdk-headless
$ pip install git+https://github.com/ansible/ansible.git@stable-2.3
$ mkdir -p /usr/share/ansible/openshift-ansible
$ git clone https://github.com/openshift/openshift-ansible.git /usr/share/ansible/openshift-ansible
```

## Usage
It is advised to not run the ose-on-aws.py from a container. The ose-on-aws.py script will launch infrastructure and flow straight into installing the OpenShift application and components.

### Before Launching the Ansible script
Due to the installations use of a bastion server the ssh config must be modified.
```
$ vim /home/user/.ssh/config
Host *.sysdeseng.com
     ProxyCommand               ssh ec2-user@bastion -W %h:%p
     IdentityFile               /path/to/ssh/key

Host bastion
     Hostname                   bastion.sysdeseng.com
     user                       ec2-user
     StrictHostKeyChecking      no
     ProxyCommand               none
     CheckHostIP                no
     ForwardAgent               yes
     IdentityFile               /path/to/ssh/key
```
### Export the EC2 Credentials
You will need to export your EC2 credentials before attempting to use the
scripts:
```
export AWS_ACCESS_KEY_ID=foo
export AWS_SECRET_ACCESS_KEY=bar
```

### GitHub Authentication
GitHub authentication is the default authentication mechanism used for this reference architecture. GitHub authentication requires an OAuth application to be created. The values should reflect the hosted zone defined in Route53 for example the Homepage URL would be https://openshift-master.sysdeseng.com and Authorization callback URL is https://openshift-master.sysdeseng.com/oauth2callback/github.

### Region
The default region is us-east-1 but can be changed when running the ose-on-aws script by specifying --region=us-west-2 for example. The region must contain at least 3 Availability Zones.

### AMI ID
The AMI ID may need to change if the AWS IAM account does not have access to the Red Hat Cloud Access gold image, another OS such as CentOS is deployed, or if deploying outside of the us-east-1 region.

### Containerized Installation
Specifying the configuration trigger --containerized=true will install and run OpenShift services in containers. Both Atomic Host and RHEL can run OpenShift in containers. When using Atomic Host the version of docker must be 1.10 or greater and the configuration trigger --containerized=true must be used or OpenShift will not operate as expected.

### New AWS Environment (Greenfield)
When installing into an new AWS environment perform the following.   This will create the SSH key, bastion host, and VPC for the new environment.

**OpenShift Container Platform**
```
./ose-on-aws.py --keypair=OSE-key --create-key=yes --key-path=/path/to/ssh/key.pub --rhsm-user=rh-user --rhsm-password=password \
--public-hosted-zone=sysdeseng.com --rhsm-pool="Red Hat OpenShift Container Platform, Standard, 2-Core" \
--github-client-secret=47a0c41f0295b451834675ed78aecfb7876905f9 --github-organization=openshift \
--github-organization=RHSyseng --github-client-id=3a30415d84720ad14abc --deploy-openshift-metrics=true
```
**OpenShift Origin**
```
./ose-on-aws.py --keypair=OSE-key --create-key=yes --key-path=/path/to/ssh/key.pub --public-hosted-zone=sysdeseng.com \
--deployment-type=origin --ami=ami-6d1c2007 --github-client-secret=47a0c41f0295b451834675ed78aecfb7876905f9 \
--github-organization=openshift --github-organization=RHSyseng --github-client-id=3a30415d84720ad14abc
```

If the SSH key that you plan on using in AWS already exists then perform the following.

**OpenShift Container Platform**
```
./ose-on-aws.py --keypair=OSE-key --rhsm-user=rh-user --rhsm-password=password --public-hosted-zone=sysdeseng.com --rhsm-pool="Red Hat OpenShift Container Platform, Standard, 2-Core"
```

**OpenShift Origin**
```
./ose-on-aws.py --keypair=OSE-key --public-hosted-zone=sysdeseng.com --deployment-type=origin --ami=ami-6d1c2007 \
--github-client-secret=47a0c41f0295b451834675ed78aecfb7876905f9 --github-organization=openshift \
--github-organization=RHSyseng --github-client-id=3a30415d84720ad14abc
```

### Existing AWS Environment (Brownfield)
If installing OpenShift Container Platform or OpenShift Origin into an existing AWS VPC perform the following. The script will prompt for vpc and subnet IDs. The Brownfield deployment can also skip the creation of a Bastion server if one already exists. For mappings of security groups make sure the bastion security group is named bastion-sg.

**OpenShift Container Platform**
```
./ose-on-aws.py --create-vpc=no --byo-bastion=yes --keypair=OSE-key --rhsm-user=rh-user --rhsm-password=password \
--public-hosted-zone=sysdeseng.com --rhsm-pool="Red Hat OpenShift Container Platform, Standard, 2-Core" --bastion-sg=sg-a32fa3 \
--github-client-secret=47a0c41f0295b451834675ed78aecfb7876905f9 --github-organization=openshift \
--github-organization=RHSyseng --github-client-id=3a30415d84720ad14abc
```

**OpenShift Origin**
```
./ose-on-aws.py --create-vpc=no --byo-bastion=yes --keypair=OSE-key --public-hosted-zone=sysdeseng.com \
--deployment-type=origin --ami=ami-6d1c2007 --bastion-sg=sg-a32fa3 \
--github-client-secret=47a0c41f0295b451834675ed78aecfb7876905f9 --github-organization=openshift \
--github-organization=RHSyseng --github-client-id=3a30415d84720ad14abc
```

## Multiple OpenShift deployments
The same greenfield and brownfield deployment steps can be used to launch another instance of the reference architecture environment. When launching a new environment ensure that the variable stack-name is changed. If the variable is not changed the currently deployed environment may be changed.

**OpenShift Container Platform**
```
./ose-on-aws.py --rhsm-user=rh-user --public-hosted-zone=rcook-aws.sysdeseng.com --keypair=OSE-key \
--rhsm-pool="Red Hat OpenShift Container Platform, Standard, 2-Core" --keypair=OSE-key --rhsm-password=password \
--stack-name=prod --github-client-secret=47a0c41f0295b451834675ed78aecfb7876905f9 --github-organization=openshift \
--github-organization=RHSyseng --github-client-id=3a30415d84720ad14abc
```

**OpenShift Origin**
```
./ose-on-aws.py --keypair=OSE-key --public-hosted-zone=sysdeseng.com --deployment-type=origin --ami=ami-6d1c2007 \
--stack-name=prod --github-client-secret=47a0c41f0295b451834675ed78aecfb7876905f9 --github-organization=openshift \
--github-organization=RHSyseng --github-client-id=3a30415d84720ad14abc
```

## Adding nodes
Adding nodes can be done by performing the following. The configuration option --node-type allows for the creation of application or
infrastructure nodes. If the deployment is for an application node --infra-sg and --infra-elb-name are not required.

If `--use-cloudformation-facts` is not used the `--iam-role` or `Specify the name of the existing IAM Instance Profile:`
is available visiting the IAM Dashboard and selecting the role sub-menu. Select the
node role and record the information from the `Instance Profile ARN(s)` line. An
example Instance Profile would be `OpenShift-Infra-NodeInstanceProfile-TNAGMYGY9W8K`.

If the Reference Architecture deployment is >= 3.5

```
$ ./add-node.py --existing-stack=dev --rhsm-user=rhsm-user --rhsm-password=password
--public-hosted-zone=sysdeseng.com --keypair=OSE-key --rhsm-pool="Red Hat OpenShift Container Platform, Premium, 2-Core"
--use-cloudformation-facts --shortname=ose-infra-node04 --node-type=infra --subnet-id=subnet-0a962f4
```

If the Reference Architecture deployment was performed before 3.5.

```
$ ./add-node.py --rhsm-user=user --rhsm-password=password --public-hosted-zone=sysdeseng.com
--keypair=OSE-key --rhsm-pool="Red Hat OpenShift Container Platform, Premium, 2-Core" --node-type=infra
--iam-role=OpenShift-Infra-NodeInstanceProfile-TNAGMYGY9W8K --node-sg=sg-309f9a4a --infra-sg=sg-289f9a52
--shortname=ose-infra-node04 --subnet-id=subnet-0a962f4 --infra-elb-name=OpenShift-InfraElb-1N0DZ3CFCAHLV
```

## Gluster Storage
If there is a desire to use CNS or Gluster storage for OpenShift visit the link below
https://access.redhat.com/documentation/en-us/reference_architectures/2017/html-single/deploying_and_managing_openshift_container_platform_3.6_on_amazon_web_services/#persistent_storage

## Teardown

A playbook is included to remove the s3 bucket and cloudformation. The parameter ci=true should not be used unless there is 100% certainty that all unattached EBS volumes can be removed.

```
ansible-playbook -i inventory/aws/hosts -e 'region=us-east-1 stack_name=openshift-infra ci=false' playbooks/teardown.yaml
```
If nodes were added to the environment the following can be ran. Below shows all of the possible teardown additions.
```
ansible-playbook -i inventory/aws/hosts -e 'region=us-east-1 stack_name=openshift-infra ci=true' -e 'extra_app_nodes=openshift-infra-ose-app-node03' -e 'gluster_nodes=openshift-infra-cns' -e 'extra_infra_nodes=openshift-infra-ose-infra-node04' playbooks/teardown.yaml
```
