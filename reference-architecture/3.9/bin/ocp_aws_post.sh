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

if [ "$ocp_route53_extzone" ]; then
  echo "Domain $ocp_domain will need delegation set to the following nameservers"
  echo $ocp_route53_extzone | jq -r '.DelegationSet.NameServers[]'
fi

echo
echo

echo "Add the following to ~/.ssh/config
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

echo
echo

echo "Add the following to openshift-ansible installer inventory
[masters]
$(echo $ocp_hostinv | jq -r '.masters[]')

[etcd]
$(echo $ocp_hostinv | jq -r '.etcd[]'))

[routers]
$(echo $ocp_hostinv | jq -r '.routers[]')

[nodes]
$(echo $ocp_hostinv | jq -r '.nodes[]')

[nodes:children]
masters"
