aws ec2 create-tags --resources $(echo $ocp_vpc | jq -r '.Vpc.VpcId') --tags Key=Name,Value=$ocp_clusterid
aws ec2 create-tags --resources $(echo $ocp_vpcdhcpopts | jq -r '.DhcpOptions.DhcpOptionsId') --tags Key=Name,Value=$ocp_clusterid
aws ec2 create-tags --resources $(echo $ocp_igw | jq -r '.InternetGateway.InternetGatewayId') --tags Key=Name,Value=$ocp_clusterid
aws ec2 create-tags --resources $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') --tags Key=Name,Value=${ocp_regionazs[0]}
aws ec2 create-tags --resources $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') --tags Key=Name,Value=${ocp_regionazs[1]}
aws ec2 create-tags --resources $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') --tags Key=Name,Value=${ocp_regionazs[2]}
aws ec2 create-tags --resources $(echo $ocp_eip1 | jq -r '.AllocationId') --tags Key=Name,Value=${ocp_regionazs[0]}
aws ec2 create-tags --resources $(echo $ocp_eip2 | jq -r '.AllocationId') --tags Key=Name,Value=${ocp_regionazs[1]}
aws ec2 create-tags --resources $(echo $ocp_eip3 | jq -r '.AllocationId') --tags Key=Name,Value=${ocp_regionazs[2]}
aws ec2 create-tags --resources $(echo $ocp_eip4 | jq -r '.AllocationId') --tags Key=Name,Value=Bastion
aws ec2 create-tags --resources $(echo $ocp_natgw1 | jq -r '.NatGateway.NatGatewayId') --tags Key=Name,Value=${ocp_regionazs[0]}
aws ec2 create-tags --resources $(echo $ocp_natgw2 | jq -r '.NatGateway.NatGatewayId') --tags Key=Name,Value=${ocp_regionazs[1]}
aws ec2 create-tags --resources $(echo $ocp_natgw3 | jq -r '.NatGateway.NatGatewayId') --tags Key=Name,Value=${ocp_regionazs[2]}
aws ec2 create-tags --resources $(echo $ocp_routetable1 | jq -r '.RouteTable.RouteTableId') --tags Key=Name,Value=${ocp_regionazs[0]}
aws ec2 create-tags --resources $(echo $ocp_routetable2 | jq -r '.RouteTable.RouteTableId') --tags Key=Name,Value=${ocp_regionazs[1]}
aws ec2 create-tags --resources $(echo $ocp_routetable3 | jq -r '.RouteTable.RouteTableId') --tags Key=Name,Value=${ocp_regionazs[2]}
aws ec2 create-tags --resources $(echo $ocp_awssg_bastion | jq -r '.GroupId') --tags Key=Name,Value=Bastion
aws ec2 create-tags --resources $(echo $ocp_awssg_bastion | jq -r '.GroupId') --tags Key=clusterid,Value=${ocp_clusterid}
aws ec2 create-tags --resources $(echo $ocp_awssg_master | jq -r '.GroupId') --tags Key=Name,Value=Master
aws ec2 create-tags --resources $(echo $ocp_awssg_master | jq -r '.GroupId') --tags Key=clusterid,Value=${ocp_clusterid}
aws ec2 create-tags --resources $(echo $ocp_awssg_infra | jq -r '.GroupId') --tags Key=Name,Value=Infra
aws ec2 create-tags --resources $(echo $ocp_awssg_infra | jq -r '.GroupId') --tags Key=clusterid,Value=${ocp_clusterid}
aws ec2 create-tags --resources $(echo $ocp_awssg_node | jq -r '.GroupId') --tags Key=Name,Value=Node
aws ec2 create-tags --resources $(echo $ocp_awssg_node | jq -r '.GroupId') --tags Key=clusterid,Value=${ocp_clusterid}

echo '[masters]'
echo $ocp_hostinv | jq -r '.masters[]'
echo
echo '[etcd]
echo $ocp_hostinv | jq -r '.etcd[]'
echo
echo $ocp_hostinv | jq -r '.routers[]'
echo
echo '[nodes]'
echo $ocp_hostinv | jq -r '.nodes[]'
echo
echo '[nodes:children]'
echo masters
