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
    DEV=/dev/nvme1n1
    VG=dockervg
    CONTAINER_ROOT_LV_NAME=dockerlv
    CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
    CONTAINER_ROOT_LV_SIZE=100%FREE
  path: "/etc/sysconfig/docker-storage-setup"
  permissions: "0644"
  owner: "root"

runcmd:
- [ pvcreate, /dev/nvme1n1 ]
- [ vgcreate, dockervg, /dev/nvme1n1 ]

fs_setup:
- label: ocp_emptydir
  filesystem: xfs
  device: /dev/nvme2n1
  partition: auto

mounts:
- [ "LABEL=ocp_emptydir", "/var/lib/origin/openshift.local.volumes", xfs, "defaults,gquota" ]
