aws ec2 create-tags --resources $(echo $ocp_vpc | jq -r '.Vpc.VpcId') --tags Key=Name,Value=$ocp_clusterid
aws ec2 create-tags --resources $(echo $ocp_vpcdhcpopts | jq -r '.DhcpOptions.DhcpOptionsId') --tags Key=Name,Value=$ocp_clusterid
aws ec2 create-tags --resources $(echo $ocp_igw | jq -r '.InternetGateway.InternetGatewayId') --tags Key=Name,Value=$ocp_clusterid
aws ec2 create-tags --resources $(echo $ocp_subnet1_routing | jq -r '.Subnet.SubnetId') --tags Key=Name,Value=${ocp_az[0]}_routing
aws ec2 create-tags --resources $(echo $ocp_subnet2_routing | jq -r '.Subnet.SubnetId') --tags Key=Name,Value=${ocp_az[1]}_routing
aws ec2 create-tags --resources $(echo $ocp_subnet3_routing | jq -r '.Subnet.SubnetId') --tags Key=Name,Value=${ocp_az[2]}_routing
aws ec2 create-tags --resources $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') --tags Key=Name,Value=${ocp_az[0]}
aws ec2 create-tags --resources $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') --tags Key=Name,Value=${ocp_az[1]}
aws ec2 create-tags --resources $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') --tags Key=Name,Value=${ocp_az[2]}
aws ec2 create-tags --resources $(echo $ocp_eip0 | jq -r '.AllocationId') --tags Key=Name,Value=bastion
aws ec2 create-tags --resources $(echo $ocp_eip1 | jq -r '.AllocationId') --tags Key=Name,Value=${ocp_az[0]}
aws ec2 create-tags --resources $(echo $ocp_eip2 | jq -r '.AllocationId') --tags Key=Name,Value=${ocp_az[1]}
aws ec2 create-tags --resources $(echo $ocp_eip3 | jq -r '.AllocationId') --tags Key=Name,Value=${ocp_az[2]}
aws ec2 create-tags --resources $(echo $ocp_natgw1 | jq -r '.NatGateway.NatGatewayId') --tags Key=Name,Value=${ocp_az[0]}
aws ec2 create-tags --resources $(echo $ocp_natgw2 | jq -r '.NatGateway.NatGatewayId') --tags Key=Name,Value=${ocp_az[1]}
aws ec2 create-tags --resources $(echo $ocp_natgw3 | jq -r '.NatGateway.NatGatewayId') --tags Key=Name,Value=${ocp_az[2]}
aws ec2 create-tags --resources $(echo $ocp_routetable1 | jq -r '.RouteTable.RouteTableId') --tags Key=Name,Value=${ocp_az[0]}
aws ec2 create-tags --resources $(echo $ocp_routetable2 | jq -r '.RouteTable.RouteTableId') --tags Key=Name,Value=${ocp_az[1]}
aws ec2 create-tags --resources $(echo $ocp_routetable3 | jq -r '.RouteTable.RouteTableId') --tags Key=Name,Value=${ocp_az[2]}
aws ec2 create-tags --resources $(echo $ocp_awssg_bastion | jq -r '.GroupId') --tags Key=Name,Value=bastion
aws ec2 create-tags --resources $(echo $ocp_awssg_bastion | jq -r '.GroupId') --tags Key=clusterid,Value=${ocp_clusterid}
aws ec2 create-tags --resources $(echo $ocp_awssg_master | jq -r '.GroupId') --tags Key=Name,Value=Master
aws ec2 create-tags --resources $(echo $ocp_awssg_master | jq -r '.GroupId') --tags Key=clusterid,Value=${ocp_clusterid}
aws ec2 create-tags --resources $(echo $ocp_awssg_infra | jq -r '.GroupId') --tags Key=Name,Value=Infra
aws ec2 create-tags --resources $(echo $ocp_awssg_infra | jq -r '.GroupId') --tags Key=clusterid,Value=${ocp_clusterid}
aws ec2 create-tags --resources $(echo $ocp_awssg_node | jq -r '.GroupId') --tags Key=Name,Value=Node
aws ec2 create-tags --resources $(echo $ocp_awssg_node | jq -r '.GroupId') --tags Key=clusterid,Value=${ocp_clusterid}

echo "Land clusterid SSH config (${ocp_clusterid})"
cat >> ~/.ssh/config-${ocp_clusterid} < EOF
Host bastion
  HostName                 $(echo $ocp_eip0 | jq -r '.PublicIp')
  User                     ec2-user
  CheckHostIP              no
  ForwardAgent             yes
  ProxyCommand             none
  StrictHostKeyChecking    no
  IdentityFile             ~/.ssh/${ocp_clusterid}

Host *.compute-1.amazonaws.com
  user                     ec2-user
  StrictHostKeyChecking    no
  CheckHostIP              no
  IdentityFile             ~/.ssh/${ocp_clusterid}

Host *.ec2.internal
  ProxyCommand             ssh ec2-user@bastion -W %h:%p
  user                     ec2-user
  StrictHostKeyChecking    no
  CheckHostIP              no
  IdentityFile             ~/.ssh/${ocp_clusterid}"
EOF

echo
echo

echo "NOTICE!  Update domain delegation (~/.ssh/config-${ocp_clusterid}-domaindelegation)"
Domain $ocp_domain will need delegation set to the following nameservers"

$(echo $ocp_route53_extzone | jq -r '.DelegationSet.NameServers[]')
EOF

echo
echo

echo "NOTICE!  Update openshift-ansible installer inventory with cloudprovider_kind and credentials (~/.ssh/config-${ocp_clusterid}-ocpinstallercpk)"
cat >> ~/.ssh/config-${ocp_clusterid}-ocpinstallercpk << EOF
Update openshift-ansible installer inventory with cloudprovider_kind=aws and credentials

openshift_cloudprovider_kind=aws
openshift_clusterid={{ clusterid }}
openshift_cloudprovider_aws_access_key=
openshift_cloudprovider_aws_secret_key=
EOF

echo
echo

echo "NOTICE!  Update openshift-ansible installer inventory with Registry S3 storage credentials (~/.ssh/config-${ocp_clusterid}-ocpinstallers3creds)"
cat ~/.ssh/config-${ocp_clusterid}-ocpinstallers3creds < EOF
Add the following to openshift-ansible installer inventory registry storage section

openshift_hosted_registry_storage_kind=object
openshift_hosted_registry_storage_provider=s3
openshift_hosted_registry_storage_s3_accesskey=$(echo $ocp_s3user_accesskey | jq -r '.AccessKey.AccessKeyId')
openshift_hosted_registry_storage_s3_secretkey=$(echo $ocp_s3user_accesskey | jq -r '.AccessKey.SecretAccessKey')
openshift_hosted_registry_storage_s3_bucket=${ocp_clusterid}-registry
openshift_hosted_registry_storage_s3_region=${region}
EOF

echo
echo

echo "NOTICE!  Update openshift-ansible installer inventory with endpoint urls (~/.ssh/config-${ocp_clusterid}-ocpinstallerurls)"
cat >> ~/.ssh/config-${ocp_clusterid}-ocpinstallerurls << EOF
EOF

echo
echo

echo "NOTICE!  Update openshift-ansible installer inventory with OCP hosts (./inventory/hosts-${ocp_clusterid})"
cat >> hosts-${ocp_clusterid} < EOF
[masters]
$(echo $ocp_hostinv | jq -r '.masters[]')

[etcd]
masters

[nodes]
$(echo $ocp_hostinv | jq -r '.nodes[]')
$(echo $ocp_hostinv | jq -r '.routers[]')

[nodes:children]
masters
EOF
