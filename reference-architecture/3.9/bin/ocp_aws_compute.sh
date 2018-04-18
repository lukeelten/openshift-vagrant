if [ ! "$ocp_ec2_bastion" ]; then
  export ocp_ec2_bastion=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_bastion_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_bastion | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet1_routing | jq -r '.Subnet.SubnetId') \
    --associate-public-ip-address \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=bastion},{Key=Clusterid,Value=$ocp_clusterid}]" \
  )
  sleep 30
  export ocp_ec2_bastioneipassc=$(aws ec2 associate-address \
    --allocation-id $(echo $ocp_eip0 | jq -r '.AllocationId') \
    --instance-id $(echo $ocp_ec2_bastion | jq -r '.Instances[].InstanceId'))
fi
if [ ! "$ocp_ec2_master1" ]; then
  export ocp_ec2_master1=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_master_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_master | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=master1},{Key=Clusterid,Value=$ocp_clusterid}]" \
  )
fi
if [ ! "$ocp_ec2_master2" ]; then
  export ocp_ec2_master2=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_master_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_master | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=master2},{Key=Clusterid,Value=$ocp_clusterid}]" \
  )
fi
if [ ! "$ocp_ec2_master3" ]; then
  export ocp_ec2_master3=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_master_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_master | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=master3},{Key=Clusterid,Value=$ocp_clusterid}]" \
  )
fi
if [ "$ocp_ec2_master1" ] && [ "$ocp_ec2_master2" ] && [ "$ocp_ec2_master3" ]; then
  export ocp_elb_masterextreg=$(aws elb register-instances-with-load-balancer \
    --load-balancer-name $ocp_clusterid-master-external \
    --instances \
      $(echo $ocp_ec2_master1 | jq -r '.Instances[].InstanceId') \
      $(echo $ocp_ec2_master2 | jq -r '.Instances[].InstanceId') \
      $(echo $ocp_ec2_master3 | jq -r '.Instances[].InstanceId') \
  )
  export ocp_elb_masterintreg=$(aws elb register-instances-with-load-balancer \
    --load-balancer-name $ocp_clusterid-master-internal \
    --instances \
      $(echo $ocp_ec2_master1 | jq -r '.Instances[].InstanceId') \
      $(echo $ocp_ec2_master2 | jq -r '.Instances[].InstanceId') \
      $(echo $ocp_ec2_master3 | jq -r '.Instances[].InstanceId') \
  )
fi

if [ ! "$ocp_ec2_infra1" ]; then
  export ocp_ec2_infra1=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_infra_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_infra | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=infra1},{Key=Clusterid,Value=$ocp_clusterid}]" \
  )
fi
if [ ! "$ocp_ec2_infra2" ]; then
  export ocp_ec2_infra2=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_infra_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_infra | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=infra2},{Key=Clusterid,Value=$ocp_clusterid}]" \
  )
fi
if [ ! "$ocp_ec2_infra3" ]; then
  export ocp_ec2_infra3=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_infra_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_infra | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=infra3},{Key=Clusterid,Value=$ocp_clusterid}]" \
  )
fi
if [ "$ocp_ec2_infra1" ] && [ "$ocp_ec2_infra2" ] && [ "$ocp_ec2_infra3" ]; then
  export ocp_elb_infrareg=$(aws elb register-instances-with-load-balancer \
    --load-balancer-name $ocp_clusterid-infra-external \
    --instances \
      $(echo $ocp_ec2_infra1 | jq -r '.Instances[].InstanceId') \
      $(echo $ocp_ec2_infra2 | jq -r '.Instances[].InstanceId') \
      $(echo $ocp_ec2_infra3 | jq -r '.Instances[].InstanceId') \
  )
  export ocp_elb_infrareg=$(aws elb register-instances-with-load-balancer \
    --load-balancer-name $ocp_clusterid-infra-internal \
    --instances \
      $(echo $ocp_ec2_infra1 | jq -r '.Instances[].InstanceId') \
      $(echo $ocp_ec2_infra2 | jq -r '.Instances[].InstanceId') \
      $(echo $ocp_ec2_infra3 | jq -r '.Instances[].InstanceId') \
  )
fi
if [ ! "$ocp_ec2_node1" ]; then
  export ocp_ec2_node1=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_node_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_node | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
(??)    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=node1},{Key=Clusterid,Value=$ocp_clusterid}]'
  )
fi
if [ ! "$ocp_ec2_node2" ]; then
  export ocp_ec2_node2=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_node_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_node | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
(??)    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=node2},{Key=Clusterid,Value=$ocp_clusterid}]'
  )
fi
if [ ! "$ocp_ec2_node3" ]; then
  export ocp_ec2_node3=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_node_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_node | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
(??)    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=node3},{Key=Clusterid,Value=$ocp_clusterid}]'
  )
fi
if [ ! "$ocp_ec2_node4" ]; then
  export ocp_ec2_node4=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_node_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_node | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
(??)    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=node4},{Key=Clusterid,Value=$ocp_clusterid}]'
  )
fi
if [ ! "$ocp_ec2_node5" ]; then
  export ocp_ec2_node5=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_node_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_node | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
(??)    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=node5},{Key=Clusterid,Value=$ocp_clusterid}]'
  )
fi
if [ ! "$ocp_ec2_node6" ]; then
  export ocp_ec2_node6=$(aws ec2 run-instances \
    --image-id ${ocp_ec2ami[1]} \
    --count 1 \
    --instance-type $ocp_ec2_node_type \
    --key-name $(echo $ocp_keypair | jq -r '.KeyName') \
    --security-group-ids $(echo $ocp_awssg_node | jq -r '.GroupId') \
    --subnet-id $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=False,VolumeSize=100}" \
(??)    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=node6},{Key=Clusterid,Value=$ocp_clusterid}]'
  )
fi

export ocp_hostinv="\
{ \"masters\": [ \
    \"$(echo $ocp_ec2_master1 | jq -r '.Instances[].PrivateDnsName')\", \
    \"$(echo $ocp_ec2_master2 | jq -r '.Instances[].PrivateDnsName')\", \
    \"$(echo $ocp_ec2_master3 | jq -r '.Instances[].PrivateDnsName')\" \
  ], \
  \"etcd\": [ \
    \"masters\" \
  ], \
  \"routers\": [ \
    \"$(echo $ocp_ec2_infra1 | jq -r '.Instances[].PrivateDnsName')\", \
    \"$(echo $ocp_ec2_infra2 | jq -r '.Instances[].PrivateDnsName')\", \
    \"$(echo $ocp_ec2_infra3 | jq -r '.Instances[].PrivateDnsName')\" \
  ], \
  \"nodes\": [ \
    \"$(echo $ocp_ec2_node1 | jq -r '.Instances[].PrivateDnsName')\", \
    \"$(echo $ocp_ec2_node2 | jq -r '.Instances[].PrivateDnsName')\", \
    \"$(echo $ocp_ec2_node3 | jq -r '.Instances[].PrivateDnsName')\", \
    \"$(echo $ocp_ec2_node4 | jq -r '.Instances[].PrivateDnsName')\", \
    \"$(echo $ocp_ec2_node5 | jq -r '.Instances[].PrivateDnsName')\", \
    \"$(echo $ocp_ec2_node6 | jq -r '.Instances[].PrivateDnsName')\" \
  ] \
}"
