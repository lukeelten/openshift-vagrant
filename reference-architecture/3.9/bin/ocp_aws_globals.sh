if [ ! "$ocp_ec2ami" ]; then
  export ocp_ec2ami=($(aws ec2 describe-images --owners 309956199498 | \
    jq -r '.Images[] | [.Name,.ImageId] | @csv' | \
    sed -e 's/,/ /g' | \
    sed -e 's/"//g' | \
    grep -v Beta | \
    grep RHEL-7 | \
    grep Access2-GP2 | \
    sort | \
    tail -1))
fi

if [ ! -f $HOME/.ssh/${ocp_clusterid} ]; then
  echo 'Enter ssh key password'
  read -r passphrase
  ssh-keygen -P $passphrase -o -t rsa -f ~/.ssh/${ocp_clusterid}
fi
export sshkey=($(cat ~/.ssh/${ocp_clusterid}.pub))

if [ ! "$(env | grep SSH_AGENT_PID)" ] || [ ! "$(ps -ef | grep $SSH_AGENT_PID)" ]; then
  rm -rf $SSH_AUTH_SOCK
  unset SSH_AUTH_SOCK
  pkill ssh-agent
  export sshagent=$(nohup ssh-agent &)
  export sshagent=($(echo $sshagent | awk -F'; ' {'print $1 " " $3'}))
  export ${sshagent[0]}
  export ${sshagent[1]}
  unset sshagent
fi

IFS=$'\n'
if [ ! $(ssh-add -L | grep ${sshkey[1]}) ]; then
  echo ssh-add
  ssh-add ~/.ssh/${ocp_clusterid}
fi
unset IFS

if [ ! "$ocp_keypair" ]; then
  export ocp_keypair=$(aws ec2 import-key-pair \
                       --key-name ${ocp_clusterid} \
                       --public-key-material file://~/.ssh/$ocp_clusterid.pub \
                       )
fi
if [ ! "$ocp_s3user" ]; then
  export ocp_s3user=$(aws iam create-user --user-name ${ocp_clusterid}-registry)
  sleep 30
  aws iam attach-user-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
    --user-name ${ocp_clusterid}-registry
fi
if [ ! "$ocp_s3user_accesskey" ]; then
  export ocp_s3user_accesskey=$(aws iam create-access-key --user-name ${ocp_clusterid}-registry)
fi

if [ ! "$ocp_aws_s3bucket" ]; then
  export ocp_aws_s3bucket=$(aws s3api create-bucket --bucket $(echo ${ocp_clusterid}-registry))
  aws s3api put-bucket-policy \
    --bucket $(echo ${ocp_clusterid}-registry) \
    --policy "\
{ \
  \"Statement\": [ \
    { \
      \"Action\": \"s3:*\", \
      \"Effect\": \"Allow\", \
      \"Principal\": { \
        \"AWS\": \"$(echo $ocp_s3user | jq -r '.User.Arn')\" \
      }, \
      \"Resource\": \"arn:aws:s3:::$(echo $ocp_aws_s3bucket | jq -r '.Location' | sed -e 's/^\///g')\" \
    } \
  ] \
}"
fi

if [ ! "$ocp_iamuser" ]; then
  export ocp_iamuser=$(aws iam create-user --user-name ${ocp_clusterid}-admin)
  sleep 30
cat > .iamuser_policy << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "1",
            "Action": [
                "ec2:DescribeVolume",
                "ec2:CreateVolume",
                "ec2:CreateTags",
                "ec2:DescribeInstance",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:DeleteVolume",
                "ec2:DescribeSubnets",
                "ec2:CreateSecurityGroup",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeRouteTables",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:CreateLoadBalancerListeners",
                "elasticloadbalancing:ConfigureHealthCheck",
                "elasticloadbalancing:DeleteLoadBalancerListeners",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:DescribeLoadBalancerAttributes"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::{{ clusterid }}-admin"
        }
    ]
}
EOF
  aws iam create-policy --policy-name Admin --policy-document file://.iamuser_policy
  aws iam attach-user-policy \
    --policy-arn arn:aws:iam::aws:policy/Admin \
    --user-name ${ocp_clusterid}-admin
fi
