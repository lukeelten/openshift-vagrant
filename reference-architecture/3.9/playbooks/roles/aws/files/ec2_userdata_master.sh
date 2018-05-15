#cloud-config
cloud_config_modules:
- disk_setup
- mounts
- package-update-upgrade-install
- runcmd

packages:
- lvm2

write_files:
- content: |
    STORAGE_DRIVER=overlay2
    DEV=/dev/nvme2n1
    VG=dockervg
    CONTAINER_ROOT_LV_NAME=dockerlv
    CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
    CONTAINER_ROOT_LV_SIZE=100%FREE
  path: "/etc/sysconfig/docker-storage-setup"
  permissions: "0644"
  owner: "root"

runcmd:
- [ pvcreate, /dev/nvme2n1 ]
- [ vgcreate, dockervg, /dev/nvme2n1 ]
- [ mkdir, -p, /var/lib/etcd ]

fs_setup:
- label: etcd
  filesystem: xfs
  device: /dev/nvme1n1
  partition: auto
- label: ocp_emptydir
  filesystem: xfs
  device: /dev/nvme3n1
  partition: auto

mounts:
- [ "LABEL=etcd", "/var/lib/etcd", xfs, "defaults,gquota" ]
- [ "LABEL=ocp_emptydir", "/var/lib/origin/openshift.local.volumes", xfs, "defaults,gquota" ]
