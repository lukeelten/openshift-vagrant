# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'socket'

hostname = Socket.gethostname
localmachineip = IPSocket.getaddress(Socket.gethostname)
puts %Q{ This machine has the IP '#{localmachineip} and host name '#{hostname}'}

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

deployment_type = 'origin'
box_name = 'centos/7'
crio_env =  ENV['OKD_ENABLE_CRIO'] || false

enable_crio = false
enforce_cio = false
if crio_env == "force"
  enable_crio = true
  enforce_cio = true
elsif crio_env
  enable_crio = true
end


REQUIRED_PLUGINS = %w(vagrant-hostmanager vagrant-sshfs landrush)
SUGGESTED_PLUGINS = %w(vagrant-reload)

def message(name)
  "#{name} plugin is not installed, run `vagrant plugin install #{name}` to install it."
end

SUGGESTED_PLUGINS.each { |plugin| print("note: " + message(plugin) + "\n") unless Vagrant.has_plugin?(plugin) }

errors = []

# Validate and collect error message if plugin is not installed
REQUIRED_PLUGINS.each { |plugin| errors << message(plugin) unless Vagrant.has_plugin?(plugin) }
unless errors.empty?
  msg = errors.size > 1 ? "Errors: \n* #{errors.join("\n* ")}" : "Error: #{errors.first}"
  fail Vagrant::Errors::VagrantError.new, msg
end


NETWORK_BASE = '192.168.50'
INTEGRATION_START_SEGMENT = 20

def quote_labels(labels)
    # Quoting logic for ansible host_vars has changed in Vagrant 2.0
    # See: https://github.com/hashicorp/vagrant/commit/ac75e409a3470897d56a0841a575e981d60e2e3d
    if Vagrant::VERSION.to_i >= 2
      return '{' + labels.map{|k, v| "\"#{k}\": \"#{v}\""}.join(', ') + '}'
    else
      return '"{' + labels.map{|k, v| "'#{k}': '#{v}'"}.join(', ') + '}"'
    end
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  if Vagrant.has_plugin?('landrush')
    config.landrush.enabled = true
    config.landrush.tld = 'example.com'
    config.landrush.guest_redirect_dns = false
  end

  # Configure eth0 via script, will disable NetworkManager and enable legacy network daemon:
  config.vm.provision "shell", path: "provision/setup.sh", args: [NETWORK_BASE]

  config.vm.provider "virtualbox" do |v, override|
    v.memory = 2048
    v.cpus = 1
    override.vm.box = box_name
    provider_name = 'virtualbox'
  end

  config.vm.provider "libvirt" do |libvirt, override|
    libvirt.cpus = 1
    libvirt.memory = 2048
    libvirt.driver = 'kvm'
    override.vm.box = box_name
    provider_name = 'libvirt'
  end

  # Suppress the default sync in both CentOS base and CentOS Atomic Host
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', '/home/vagrant/sync', disabled: true

  config.vm.define "master1" do |master1|
    master1.vm.network :private_network, ip: "#{NETWORK_BASE}.#{INTEGRATION_START_SEGMENT}"
    master1.vm.hostname = "master1.example.com"
    master1.hostmanager.aliases = %w(master1)

    # Update virtual machine to newest version
    master1.vm.provision "shell", inline: <<-SHELL
      echo "deltarpm_percentage=0" >> /etc/yum.conf
      yum -y update
    SHELL
    if Vagrant.has_plugin?('vagrant-reload')
      # Reboot machine
      master1.vm.provision :reload
    end
  end

  config.vm.define "node1" do |node1|
    node1.vm.network :private_network, ip: "#{NETWORK_BASE}.#{INTEGRATION_START_SEGMENT + 1}"
    node1.vm.hostname = "node1.example.com"
    node1.hostmanager.aliases = %w(node1)

    node1.vm.provision "shell", inline: <<-SHELL
      echo "deltarpm_percentage=0" >> /etc/yum.conf
      yum -y update
    SHELL
    if Vagrant.has_plugin?('vagrant-reload')
      node1.vm.provision :reload
    end
  end

  config.vm.define "node2" do |node2|
    node2.vm.network :private_network, ip: "#{NETWORK_BASE}.#{INTEGRATION_START_SEGMENT + 2}"
    node2.vm.hostname = "node2.example.com"
    node2.hostmanager.aliases = %w(node2)

    node2.vm.provision "shell", inline: <<-SHELL
      echo "deltarpm_percentage=0" >> /etc/yum.conf
      yum -y update
    SHELL
    if Vagrant.has_plugin?('vagrant-reload')
      node2.vm.provision :reload
    end
  end

  config.vm.define "admin1" do |admin1|
    admin1.vm.network :private_network, ip: "#{NETWORK_BASE}.#{INTEGRATION_START_SEGMENT + 3}"
    admin1.vm.hostname = "admin1.example.com"
    admin1.hostmanager.aliases = %w(admin1)

    admin1.vm.synced_folder ".", "/home/vagrant/sync", type: "sshfs"
    admin1.vm.synced_folder ".vagrant", "/home/vagrant/.hidden", type: "sshfs"

    admin1.vm.provision "shell", inline: <<-SHELL
      echo "deltarpm_percentage=0" >> /etc/yum.conf
      yum -y update
    SHELL
    if Vagrant.has_plugin?('vagrant-reload')
      admin1.vm.provision :reload
    end

    ansible_groups = {
      OSEv3: ["master1", "node1", "node2"],
      'OSEv3:children': ["masters", "nodes", "etcd", "nfs"],
      'OSEv3:vars': {
        ansible_become: true,
        ansible_ssh_user: 'vagrant',
        deployment_type: deployment_type,
        openshift_deployment_type: deployment_type,
        openshift_release: 'v3.10',
        openshift_clock_enabled: true,
        os_firewall_use_firewalld: true,
        ansible_service_broker_install: false,
        template_service_broker_install: false,
        openshift_master_identity_providers: "[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'file': '/etc/origin/master/htpasswd'}]",
        openshift_master_htpasswd_users: "{'admin': '$apr1$nWG7vwhy$jCMCBmBrW3MEYmCFCckYk1'}",
        openshift_master_default_subdomain: 'apps.example.com',
        openshift_disable_check: "docker_storage,memory_availability,package_version",
        openshift_hosted_registry_replicas: 1,
        openshift_hosted_router_selector: 'node-role.kubernetes.io/master=true',
        openshift_hosted_registry_selector: 'node-role.kubernetes.io/master=true',
        openshift_enable_unsupported_configurations: true, # Needed for NFS registry. For some unknown reason.
        openshift_hosted_registry_storage_kind: 'nfs',
        openshift_hosted_registry_storage_access_modes: ['ReadWriteMany'],
        openshift_hosted_registry_storage_host: 'admin1.example.com',
        openshift_hosted_registry_storage_nfs_directory: '/srv/nfs',
        openshift_hosted_registry_storage_volume_name: 'registry',
        openshift_hosted_registry_storage_volume_size: '2Gi',
        openshift_use_crio: enable_crio,
        openshift_use_crio_only: enforce_cio
      },
      etcd: ["master1"],
      nfs: ["admin1"],
      masters: ["master1"],
      nodes: ["master1", "node1", "node2"],
    }

    ansible_host_vars = {
      master1:  {
        openshift_ip: '192.168.50.20',
        openshift_schedulable: true,
        ansible_host: '192.168.50.20',
        ansible_ssh_private_key_file: "/home/vagrant/.ssh/master1.key",
        openshift_node_group_name: "node-config-master"
      },
      node1: {
        openshift_ip: '192.168.50.21',
        openshift_schedulable: true,
        ansible_host: '192.168.50.21',
        ansible_ssh_private_key_file: "/home/vagrant/.ssh/node1.key",
        openshift_node_group_name: "node-config-compute"
      },
      node2: {
        openshift_ip: '192.168.50.22',
        openshift_schedulable: true,
        ansible_host: '192.168.50.22',
        ansible_ssh_private_key_file: "/home/vagrant/.ssh/node2.key",
        openshift_node_group_name: "node-config-compute"
      },
      admin1: {
        ansible_connection: 'local',
        deployment_type: deployment_type
      }
    }

    admin1.vm.provision :ansible_local do |ansible|
      ansible.verbose        = true
      ansible.install        = true
      ansible.limit          = 'OSEv3:localhost'
      ansible.provisioning_path = '/home/vagrant/sync'
      ansible.playbook       = '/home/vagrant/sync/install.yaml'
      ansible.groups = ansible_groups
      ansible.host_vars = ansible_host_vars
    end

    admin1.vm.provision :ansible_local do |ansible|
      ansible.verbose        = true
      ansible.install        = false
      ansible.limit          = "OSEv3:localhost"
      ansible.provisioning_path = '/home/vagrant/sync'
      ansible.playbook = "/home/vagrant/openshift-ansible/playbooks/prerequisites.yml"
      ansible.groups = ansible_groups
      ansible.host_vars = ansible_host_vars
    end

    admin1.vm.provision :ansible_local do |ansible|
      ansible.verbose        = true
      ansible.install        = false
      ansible.limit          = "OSEv3:localhost"
      ansible.provisioning_path = '/home/vagrant/sync'
      ansible.playbook = "/home/vagrant/openshift-ansible/playbooks/deploy_cluster.yml"
      ansible.groups = ansible_groups
      ansible.host_vars = ansible_host_vars
    end

    admin1.vm.provision :ansible_local do |ansible|
      ansible.verbose        = true
      ansible.install        = false
      ansible.limit          = "OSEv3:localhost"
      ansible.provisioning_path = '/home/vagrant/sync'
      ansible.playbook = "/home/vagrant/sync/tasks/post-install.yaml"
      ansible.groups = ansible_groups
      ansible.host_vars = ansible_host_vars
    end
  end
end
