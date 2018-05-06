#!/bin/bash
VARIANT=${1:-39}

if [ -f "example/ovirt-${VARIANT}-infra.yaml" ]
then
    INFRA="example/ovirt-${VARIANT}-infra.yaml"
else
    INFRA="playbooks/ovirt-vm-infra.yaml"
fi

ansible-playbook -e@~/vault.yaml example/uninstall.yaml 
ansible-playbook -e@~/vault.yaml $INFRA
if [ "$?" != "0" ]; then
  echo "Infrastructure deploy broke"
  exit
fi
echo "Waiting a minute for VMs to get IPs posted"
sleep 60
ansible-playbook -i /etc/ansible/hosts -i inventory playbooks/output-dns.yaml 
if [ "$?" != "0" ]; then
  echo "DNS generation broke. Backing off and retrying in two minutes"
  sleep 120
  ansible-playbook -i /etc/ansible/hosts -i inventory playbooks/output-dns.yaml 
  if [ "$?" != "0" ]; then
    echo "Still breaking DNS generation. exiting."
    exit
  fi
fi
nsupdate -k /etc/rndc.key inventory.nsupdate 
if [ "$?" != "0" ]; then
  echo "DNS update broke"
  exit
fi
ansible-playbook -e@~/vault.yaml /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
if [ "$?" != "0" ]; then
  echo "Prerequisites installation broke"
  exit
fi
ansible-playbook -e@~/vault.yaml /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

