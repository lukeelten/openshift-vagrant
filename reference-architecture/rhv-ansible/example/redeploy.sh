#!/bin/bash
VARIANT=${1:-centos}
if [ -f "test/ocp-vars.yaml.$VARIANT" ]
then
    VARS="-e@test/ocp-vars.yaml.$VARIANT"
else
    VARS="-e@test/ocp-vars.yaml"
fi

if [ -f "test/ovirt-${VARIANT}-infra.yaml" ]
then
    INFRA="test/ovirt-${VARIANT}-infra.yaml"
else
    INFRA="playbooks/ovirt-vm-infra.yaml"
fi

ansible-playbook $VARS test/uninstall.yaml 
ansible-playbook $VARS $INFRA
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
ansible-playbook $VARS playbooks/openshift-install.yaml 

