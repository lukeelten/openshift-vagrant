#!/bin/bash
VARIANT=${1:-39}
if [ -f "example/ocp-vars.yaml.$VARIANT" ]
then
    VARS="-e@example/ocp-vars.yaml.$VARIANT -e@~/vault.yaml"
else
    VARS="-e@example/ocp-vars.yaml -e@~/vault.yaml"
fi

if [ -f "example/ovirt-${VARIANT}-infra.yaml" ]
then
    INFRA="example/ovirt-${VARIANT}-infra.yaml"
else
    INFRA="playbooks/ovirt-vm-infra.yaml"
fi

ansible-playbook $VARS example/uninstall.yaml 
ansible-playbook -i example/inventory.yaml $VARS $INFRA
if [ "$?" != "0" ]; then
  echo "Infrastructure deploy broke"
  exit
fi
ansible-playbook $VARS playbooks/output-dns.yaml 
if [ "$?" != "0" ]; then
  echo "DNS generation broke"
  exit
fi
nsupdate -k /etc/rndc.key inventory.nsupdate 
if [ "$?" != "0" ]; then
  echo "DNS update broke"
  exit
fi
ansible-playbook -i example/inventory.yaml -e@~/vault.yaml example/node-preparation.yaml
if [ "$?" != "0" ]; then
  echo "Node preparation broke"
  exit
fi
ansible-playbook -i example/inventory.yaml -e@~/vault.yaml /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
if [ "$?" != "0" ]; then
  echo "Prerequisites installation broke"
  exit
fi
ansible-playbook -i example/inventory.yaml -e@~/vault.yaml /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

