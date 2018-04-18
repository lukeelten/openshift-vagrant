if [ ! "$ocp_vpc" ]; then
  export ocp_vpc=$(aws ec2 create-vpc --cidr-block $ocp_cidrblock | jq -r '.')
fi

if [ ! "$ocp_vpcdhcpopts" ]; then
  export ocp_vpcdhcpopts=$(aws ec2 create-dhcp-options \
    --dhcp-configuration " \
    [ \
      { \"Key\" : \"domain-name\", \"Values\" : [ \"ec2.internal\" ] }, \
      { \"Key\" : \"domain-name-servers\", \"Values\" : [ \"AmazonProvidedDNS\" ] }, \
      { \"Key\" : \"ntp-servers\", \"Values\" : [ \
                                                \"$(dig 0.rhel.pool.ntp.org +short | head -1)\", \
                                                \"$(dig 1.rhel.pool.ntp.org +short | head -1)\", \
                                                \"$(dig 2.rhel.pool.ntp.org +short | head -1)\", \
                                                \"$(dig 3.rhel.pool.ntp.org +short | head -1)\" \
                                                ] \
      } \
    ]" | \
    jq -r '.')
  aws ec2 modify-vpc-attribute \
    --enable-dns-hostnames \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId')
  aws ec2 modify-vpc-attribute \
    --enable-dns-support \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId')
  aws ec2 associate-dhcp-options \
    --dhcp-options-id $(echo $ocp_vpcdhcpopts | jq -r '.DhcpOptions.DhcpOptionsId') \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId')
fi

if [ ! "$ocp_az" ]; then
  export ocp_az=($(aws ec2 describe-availability-zones \
    --filters "Name=region-name,Values=$ocp_region" | \
    jq -r '.[][].ZoneName' | \
    head -3 | \
    tr '\n' ' ' | \
    sed -e "s/ $//g"))
fi

if [ ! "$ocp_subnet1_routing" ]; then
  export ocp_subnet1_routing=$(aws ec2 create-subnet \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --cidr-block ${ocp_cidrsubnets_routing[0]} \
    --availability-zone ${ocp_az[0]})
fi
if [ ! "$ocp_subnet2_routing" ]; then
  export ocp_subnet2_routing=$(aws ec2 create-subnet \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --cidr-block ${ocp_cidrsubnets_routing[1]} \
    --availability-zone ${ocp_az[1]})
fi
if [ ! "$ocp_subnet3_routing" ]; then
  export ocp_subnet3_routing=$(aws ec2 create-subnet \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --cidr-block ${ocp_cidrsubnets_routing[2]} \
    --availability-zone ${ocp_az[2]})
fi

if [ ! "$ocp_subnet1" ]; then
  export ocp_subnet1=$(aws ec2 create-subnet \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --cidr-block ${ocp_cidrsubnets[0]} \
    --availability-zone ${ocp_az[0]})
fi
if [ ! "$ocp_subnet2" ]; then
  export ocp_subnet2=$(aws ec2 create-subnet \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --cidr-block ${ocp_cidrsubnets[1]} \
    --availability-zone ${ocp_az[1]})
fi
if [ ! "$ocp_subnet3" ]; then
  export ocp_subnet3=$(aws ec2 create-subnet \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --cidr-block ${ocp_cidrsubnets[2]} \
    --availability-zone ${ocp_az[2]})
fi

if [ ! "$ocp_igw" ]; then
  export ocp_igw=$(aws ec2 create-internet-gateway)
  aws ec2 attach-internet-gateway \
  --internet-gateway-id $(echo $ocp_igw | jq -r '.InternetGateway.InternetGatewayId') \
  --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId')
fi

if [ ! "$ocp_eip0" ]; then
  export ocp_eip0=$(aws ec2 allocate-address --domain vpc)
fi
if [ ! "$ocp_eip1" ]; then
  export ocp_eip1=$(aws ec2 allocate-address --domain vpc)
fi
if [ ! "$ocp_eip2" ]; then
  export ocp_eip2=$(aws ec2 allocate-address --domain vpc)
fi
if [ ! "$ocp_eip3" ]; then
  export ocp_eip3=$(aws ec2 allocate-address --domain vpc)
fi

if [ ! "$ocp_natgw1" ]; then
  export ocp_natgw1=$(aws ec2 create-nat-gateway \
    --subnet-id $(echo $ocp_subnet1_routing | jq -r '.Subnet.SubnetId') \
    --allocation-id $(echo $ocp_eip1 | jq -r '.AllocationId') \
    )
fi
if [ ! "$ocp_natgw2" ]; then
  export ocp_natgw2=$(aws ec2 create-nat-gateway \
    --subnet-id $(echo $ocp_subnet2_routing | jq -r '.Subnet.SubnetId') \
    --allocation-id $(echo $ocp_eip2 | jq -r '.AllocationId') \
    )
fi
if [ ! "$ocp_natgw3" ]; then
  export ocp_natgw3=$(aws ec2 create-nat-gateway \
    --subnet-id $(echo $ocp_subnet3_routing | jq -r '.Subnet.SubnetId') \
    --allocation-id $(echo $ocp_eip3 | jq -r '.AllocationId') \
    )
fi

if [ ! "$ocp_routetable0" ]; then
  export ocp_routetable0=$(aws ec2 create-route-table \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId')
    )
  aws ec2 create-route \
    --route-table-id $(echo $ocp_routetable0 | jq -r '.RouteTable.RouteTableId') \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id $(echo $ocp_igw | jq -r '.InternetGateway.InternetGatewayId') \
    > /dev/null 2>&1
fi
if [ ! "$ocp_rtba0_subnet1_routing" ]; then
  export ocp_rtba0_subnet1_routing=$(aws ec2 associate-route-table \
    --route-table-id $(echo $ocp_routetable0 | jq -r '.RouteTable.RouteTableId') \
    --subnet-id $(echo $ocp_subnet1_routing | jq -r '.Subnet.SubnetId')
    )
fi
if [ ! "$ocp_rtba0_subnet2_routing" ]; then
  export ocp_rtba0_subnet2_routing=$(aws ec2 associate-route-table \
    --route-table-id $(echo $ocp_routetable0 | jq -r '.RouteTable.RouteTableId') \
    --subnet-id $(echo $ocp_subnet2_routing | jq -r '.Subnet.SubnetId')
    )
fi
if [ ! "$ocp_rtba0_subnet3_routing" ]; then
  export ocp_rtba0_subnet3_routing=$(aws ec2 associate-route-table \
    --route-table-id $(echo $ocp_routetable0 | jq -r '.RouteTable.RouteTableId') \
    --subnet-id $(echo $ocp_subnet3_routing | jq -r '.Subnet.SubnetId')
    )
fi
if [ ! "$ocp_routetable1" ]; then
  export ocp_routetable1=$(aws ec2 create-route-table \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId')
    )
  aws ec2 create-route \
    --route-table-id $(echo $ocp_routetable1 | jq -r '.RouteTable.RouteTableId') \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id $(echo $ocp_natgw1 | jq -r '.NatGateway.NatGatewayId') \
    > /dev/null 2>&1
fi
if [ ! "$ocp_rtba1" ]; then
  export ocp_rtba1=$(aws ec2 associate-route-table \
    --route-table-id $(echo $ocp_routetable1 | jq -r '.RouteTable.RouteTableId') \
    --subnet-id $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') \
    )
fi
if [ ! "$ocp_routetable2" ]; then
  export ocp_routetable2=$(aws ec2 create-route-table \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId')
    )
  aws ec2 create-route \
    --route-table-id $(echo $ocp_routetable2 | jq -r '.RouteTable.RouteTableId') \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id $(echo $ocp_natgw2 | jq -r '.NatGateway.NatGatewayId') \
    > /dev/null 2>&1
fi
if [ ! "$ocp_rtba2" ]; then
  export ocp_rtba2=$(aws ec2 associate-route-table \
    --route-table-id $(echo $ocp_routetable2 | jq -r '.RouteTable.RouteTableId') \
    --subnet-id $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') \
    )
fi
if [ ! "$ocp_routetable3" ]; then
  export ocp_routetable3=$(aws ec2 create-route-table \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId')
    )
  aws ec2 create-route \
    --route-table-id $(echo $ocp_routetable3 | jq -r '.RouteTable.RouteTableId') \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id $(echo $ocp_natgw3 | jq -r '.NatGateway.NatGatewayId') \
    > /dev/null 2>&1
fi
if [ ! "$ocp_rtba3" ]; then
  export ocp_rtba3=$(aws ec2 associate-route-table \
    --route-table-id $(echo $ocp_routetable3 | jq -r '.RouteTable.RouteTableId') \
    --subnet-id $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') \
    )
fi

if [ ! "$ocp_awssg_bastion" ]; then
  export ocp_awssg_bastion=$(aws ec2 create-security-group \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --group-name bastion \
    --description "bastion")
  aws ec2 authorize-security-group-ingress \
    --group-id $(echo $ocp_awssg_bastion | jq -r '.GroupId') \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
fi
if [ ! "$ocp_awssg_master" ]; then
  export ocp_awssg_master=$(aws ec2 create-security-group \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --group-name master \
    --description "master")
  aws ec2 authorize-security-group-ingress \
    --group-id $(echo $ocp_awssg_master | jq -r '.GroupId') \
    --protocol tcp \
    --port 1-65535 \
    --cidr 0.0.0.0/0
fi
if [ ! "$ocp_awssg_infra" ]; then
  export ocp_awssg_infra=$(aws ec2 create-security-group \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --group-name infra \
    --description "infra")
  aws ec2 authorize-security-group-ingress \
    --group-id $(echo $ocp_awssg_infra | jq -r '.GroupId') \
    --protocol tcp \
    --port 1-65535 \
    --cidr 0.0.0.0/0
fi
if [ ! "$ocp_awssg_node" ]; then
  export ocp_awssg_node=$(aws ec2 create-security-group \
    --vpc-id $(echo $ocp_vpc | jq -r '.Vpc.VpcId') \
    --group-name node \
    --description "node")
  aws ec2 authorize-security-group-ingress \
    --group-id $(echo $ocp_awssg_node | jq -r '.GroupId') \
    --protocol tcp \
    --port 1-65535 \
    --cidr 0.0.0.0/0
fi

if [ ! "$ocp_elb_masterext" ]; then
  export ocp_elb_masterext=$(aws elb create-load-balancer \
    --load-balancer-name $ocp_clusterid-master-external \
    --subnets \
      $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') \
      $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') \
      $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') \
    --listener Protocol=TCP,LoadBalancerPort=443,InstanceProtocol=TCP,InstancePort=443 \
    --security-groups $(echo $ocp_awssg_master | jq -r '.GroupId') \
    --scheme internet-facing \
    --tags Key=Clusterid,Value=$ocp_clusterid Key=kubernetes.io/cluster/$ocp_clusterid,Value=$ocp_clusterid)
fi
if [ ! "$ocp_elb_masterint" ]; then
  export ocp_elb_masterint=$(aws elb create-load-balancer \
    --load-balancer-name $ocp_clusterid-master-internal \
    --subnets \
      $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') \
      $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') \
      $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') \
    --listener Protocol=TCP,LoadBalancerPort=443,InstanceProtocol=TCP,InstancePort=443 \
    --security-groups $(echo $ocp_awssg_master | jq -r '.GroupId') \
    --scheme internal \
    --tags Key=Clusterid,Value=$ocp_clusterid Key=kubernetes.io/cluster/$ocp_clusterid,Value=$ocp_clusterid)
fi
if [ ! "$ocp_elb_infraext" ]; then
  export ocp_elb_infraext=$(aws elb create-load-balancer \
    --load-balancer-name $ocp_clusterid-infra-external \
    --subnets \
      $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') \
      $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') \
      $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') \
    --listener Protocol=TCP,LoadBalancerPort=443,InstanceProtocol=TCP,InstancePort=443 \
    --security-groups $(echo $ocp_awssg_infra | jq -r '.GroupId') \
    --scheme internet-facing \
    --tags Key=Clusterid,Value=$ocp_clusterid Key=kubernetes.io/cluster/$ocp_clusterid,Value=$ocp_clusterid)
fi
if [ ! "$ocp_elb_infraint" ]; then
  export ocp_elb_infraint=$(aws elb create-load-balancer \
    --load-balancer-name $ocp_clusterid-infra-internal \
    --subnets \
      $(echo $ocp_subnet1 | jq -r '.Subnet.SubnetId') \
      $(echo $ocp_subnet2 | jq -r '.Subnet.SubnetId') \
      $(echo $ocp_subnet3 | jq -r '.Subnet.SubnetId') \
    --listener Protocol=TCP,LoadBalancerPort=443,InstanceProtocol=TCP,InstancePort=443 \
    --security-groups $(echo $ocp_awssg_infra | jq -r '.GroupId') \
    --scheme internal \
    --tags Key=Clusterid,Value=$ocp_clusterid Key=kubernetes.io/cluster/$ocp_clusterid,Value=$ocp_clusterid)
fi

if [ ! "$ocp_route53_extzone" ]; then
export ocp_route53_extzone=$(aws route53 create-hosted-zone \
  --caller-reference $(date +%s) \
  --name $ocp_domain \
  --hosted-zone-config "PrivateZone=False")
fi
if [ ! "$ocp_route53_intzone" ]; then
export ocp_route53_intzone=$(aws route53 create-hosted-zone \
  --caller-reference $(date +%s) \
  --name $ocp_domain \
  --vpc "VPCRegion=$ocp_region,VPCId=$(echo $ocp_vpc | jq -r '.Vpc.VpcId')" \
  --hosted-zone-config "PrivateZone=True")
fi

if [ ! "$aws_route53rrset_masterext" ]; then
  export aws_route53rrset_masterext=$(aws route53 change-resource-record-sets \
    --hosted-zone-id $(echo $ocp_route53_extzone | jq -r '.HostedZone.Id' | sed 's/\/hostedzone\///g') \
    --change-batch "\
{ \
  \"Changes\": [ \
    { \
      \"Action\": \"CREATE\", \
      \"ResourceRecordSet\": { \
        \"Name\": \"api.$ocp_domain\", \
        \"Type\": \"CNAME\", \
        \"TTL\": 300, \
        \"ResourceRecords\": [ \
          { \"Value\": \"$(echo $ocp_elb_masterext | jq -r '.DNSName')\" } \
        ] \
      } \
    } \
  ] \
}")
fi
if [ ! "$aws_route53rrset_masterint" ]; then
  export aws_route53rrset_masterint=$(aws route53 change-resource-record-sets \
    --hosted-zone-id $(echo $ocp_route53_intzone | jq -r '.HostedZone.Id' | sed 's/\/hostedzone\///g') \
    --change-batch "\
{ \
  \"Changes\": [ \
    { \
      \"Action\": \"CREATE\", \
      \"ResourceRecordSet\": { \
        \"Name\": \"api.$ocp_domain\", \
        \"Type\": \"CNAME\", \
        \"TTL\": 300, \
        \"ResourceRecords\": [ \
          { \"Value\": \"$(echo $ocp_elb_masterint | jq -r '.DNSName')\" } \
        ] \
      } \
    } \
  ] \
}")
fi
if [ ! "$aws_route53rrset_infraext" ]; then
  export aws_route53rrset_infraext=$(aws route53 change-resource-record-sets \
    --hosted-zone-id $(echo $ocp_route53_extzone | jq -r '.HostedZone.Id' | sed 's/\/hostedzone\///g') \
    --change-batch "\
{ \
  \"Changes\": [ \
    { \
      \"Action\": \"CREATE\", \
      \"ResourceRecordSet\": { \
        \"Name\": \"*.apps.$ocp_domain\", \
        \"Type\": \"CNAME\", \
        \"TTL\": 300, \
        \"ResourceRecords\": [ \
          { \"Value\": \"$(echo $ocp_elb_infraext | jq -r '.DNSName')\" } \
        ] \
      } \
    } \
  ] \
}")
fi
if [ ! "$aws_route53rrset_infraint" ]; then
  export aws_route53rrset_infraint=$(aws route53 change-resource-record-sets \
    --hosted-zone-id $(echo $ocp_route53_intzone | jq -r '.HostedZone.Id' | sed 's/\/hostedzone\///g') \
    --change-batch "\
{ \
  \"Changes\": [ \
    { \
      \"Action\": \"CREATE\", \
      \"ResourceRecordSet\": { \
        \"Name\": \"*.apps.$ocp_domain\", \
        \"Type\": \"CNAME\", \
        \"TTL\": 300, \
        \"ResourceRecords\": [ \
          { \"Value\": \"$(echo $ocp_elb_infraint | jq -r '.DNSName')\" } \
        ] \
      } \
    } \
  ] \
}")
fi
