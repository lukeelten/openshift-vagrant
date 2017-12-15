# OpenShift Prometheus

Manage prometheus rules deployed on OpenShift.

## Dependencies

- Assumes a running [prometheus server](https://github.com/openshift/origin/tree/master/examples/prometheus), optional [node_exporter](https://github.com/openshift/origin/blob/master/examples/prometheus/node-exporter.yaml).
- Assumes an authenticated 'oc' client
- Assumes a prometheus configuration with wildcard 'rules/*.rules'.

## Running

1. Update the 'vars.yml' file with your rules repo
1. Run the playbook

        ansible-playbook rules.yml
