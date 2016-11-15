# `vpcjump`

`vpcjump` is a helper tool to make it as easy as possible to connect to a jumpbox in an AWS [VPC](https://aws.amazon.com/vpc/). 

What makes `vpcjump` unique is that your jumpbox doesn't need a public IP nor needs to open any ports in a security group. What it _does_ need is outbound Internet connectivity on port 443 - whether via a [NAT instance](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_NAT_Instance.html), Amazon-managed [NAT gateway](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-nat-gateway.html) or some custom solution. 

## Setup

* Install the tool: `gem install vpcjump`
* Sign up for [ngrok](https://ngrok.com/) and note down your authentication token
* Start an instance in EC2 - this only needs to be done once.

You can launch the EC2 instance from the AWS web console. Amazon Linux on a t2.nano is sufficient. The t2.nano is less than $5/month (as little as $2.16/month if paid upfront!) so leaving it always up is quite affordable.

When on step 3 (**Configure Instance Details**), expand **Advanced Details** and paste the following into **User data**:

```
#!/bin/bash
cd /tmp
curl https://amazon-ssm-ap-southeast-2.s3.amazonaws.com/latest/linux_amd64/amazon-ssm-agent.rpm -o amazon-ssm-agent.rpm
yum install -y amazon-ssm-agent.rpm
curl https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -o ngrok.zip
unzip ngrok.zip
mv ngrok /usr/bin/
```

You will also need to create and select an **IAM Role** for this instance to grant it permission to use [SSM](http://docs.aws.amazon.com/ssm/latest/APIReference/Welcome.html). To do this, you:

* Click **Create new IAM role**
* Click **Create New Role**
* Specify a role name of your choice, e.g.`SSMForVpcjump`, then hit next.
* Under **AWS Service Roles**, select **Amazon EC2 Role for Simple Systems Manager**, then hit next.
* Tick the checkbox for **AmazonEC2RoleforSSM**, then next.
* Click **Create Role**.
* Return to the instance creation screen, hit refresh next to **IAM Role**, then select the role you just created.

You can now proceed through the instance creation process - all the default values are fine. You can delete the security group rule opening up access to port 22 if you wish, this is unneeded. Once the instance has launched, note down the instance ID (looks like `i-abcdef`) as you will use it later.

## Usage

Invocation can be as simple as `vpcjump --ngrok-token <auth token> --instance-id i-abc123 ssh`. This takes about 30 seconds and will SSH you into the jumpbox instance. The complete list of options is:

```
$ vpcjump --help
Usage:
    vpcjump [OPTIONS] SUBCOMMAND [ARG] ...

Parameters:
    SUBCOMMAND                    subcommand
    [ARG] ...                     subcommand arguments

Subcommands:
    kill                          Terminate ngrok tunnel
    ssh                           SSH into the jumpbox

Options:
    --instance-id INSTANCE ID     EC2 instance id of jump box (e.g. i-abc123)
    --name INSTANCE NAME          EC2 instance name of jump box
    --ngrok-token NGROK TOKEN     ngrok auth token
    --ngrok-region NGROK REGION   ngrok region (default: "us")
    -v, --verbose                 Output AWS API calls
    -h, --help                    print help
    
$ vpcjump ssh --help
Usage:
    vpcjump ssh [OPTIONS] [SSHPARAMS] ...

Parameters:
    [SSHPARAMS] ...               Arguments to pass to SSH

Options:
    --ssh-user SSH USER           SSH user (default: "ec2-user")
```

Often you will want to use the jumpbox as an intermediary in order to connect to a second instance. This can be done using SSH port forwarding, e.g. `vpcjump --ngrok-token <auth token> --instance-id i-abc123 ssh -- -L 3389:172.16.0.1:3389` - This will let you to connect to Microsoft Remote Desktop on 127.0.0.1 and it will connect to the remote instance!

Finally, you may wish to terminate the jumpbox tunnel early. This can be done as such: `vpcjump --instance-id i-abc123 kill`. 

## How it works

`vpcjump` uses AWS SSM to remotely execute shell commands on your jumpbox. You can see the precise SSM and SSH commands it executes on your behalf by passing the `--verbose` flag during execution. It does the following:

* Use SSM to execute `ngrok tcp 22` with your provided auth token. This creates a tunnel over HTTPS between the instance and ngrok's tunnelling service.
* Use SSM to query ngrok's local API: `curl -s http://localhost:4040/api/tunnels`. This returns the ngrok hostname and port that are forwarded to port 22 on your jump box.
* Execute `ssh -p <ngrok port> <ssh user>@<ngrok host>` to log into your jumpbox through the ngrok tunnel. 
* Use SSM to execute `killall ngrok` on the remote instance when you explicitly terminate the tunnel. If you don't do this, the SSM agent process on the remote instance will terminate the ngrok tunnel after a predefined period.

