# SqlCD AWS Cloud Tutorial
This tutorial will walk you through setting up a cloud data platform using SqlCD from scratch using Amazon Elastic Container Services (ECS). The components included are:
* SqlCD server 
* GitLab 12.0.3 with existing demo repositories
* Postgres 11.5 (Python 3 UDFs extension) with existing demo data
* PgAdmin
* Apache Spark 2.4.4, Hive, HDFS 3.2.1 with existing demo data

Please read the [accompanying tutorials](https://support.sqlcd.com/hc/en-us/articles/360034551572) for this demo.

You can include either Postgres or Spark or both.

* For support and SqlCD tutorials visit https://support.sqlcd.com
* This tutorial uses ecs-cli version 1.15.1 

*For a production data platform you may want to use [managed services](#managed-services)*

The approximate AWS costs for running this tutorial is less than USD $1/hour (depending on your region and services started). Please calculate the exact costs yourself & remember to shutdown un-used services.
## Prerequisites
* AWS root account (signup at https://portal.aws.amazon.com/billing/signup)
* Linux/macOS system
* Very basic knowledge about AWS. eg. What is a VPC, ECS, Security Group
* Latest version of Google Chrome browser

## Parts

This tutorial is split into 5 parts. Each part builds on the previous and adds additional functionality

* Part 1 (20 minutes) : Setup a dev cloud data platform
* Part 2 (20 minutes) : Secure the data platform
* Part 3 (20 minutes) : Using an internal DNS
* Part 4 (10 minutes) : Using an EC2 ECS cluster
* Part 5 : Towards production




# Part 1: Setup a dev cloud data platform
We will set up a SqlCD data platform in AWS

## Step 1: Install & Configure AWS Command tools 
Install these AWS command-line tools
1) [Amazon ECS-CLI (Container Service)](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html)
2) [Amazon AWS CLI (General)](https://docs.aws.amazon.com/cli/latest/userguide/install-bundle.html)


Configure these tools to use your *Access Key* and *Secret Access Key*. For more information about best practices please read [AWS Security & Credentials](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#email-and-password-for-your-AWS-account) or just continue to the step below

1) [Configure Amazon AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration)
2) Configure ECS-CLI, run the following command _(replace the placeholders with your key ID and secret key)_
```
ecs-cli configure profile --profile-name my-profile --access-key $AWS_ACCESS_KEY_ID --secret-key $AWS_SECRET_ACCESS_KEY
```

## Step 2: Configure and start an ECS cluster 

### Step 2.1: Set region
Choose your AWS [region](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html) and and set this region in *configure.sh* (in this folder).
The following regions are preferable as they support [Simple Active Directory](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html) which is needed in part 3. 
* US East (N. Virginia)
* US West (Oregon)
* Asia Pacific (Singapore)
* Asia Pacific (Sydney)
* Asia Pacific (Tokyo)
* EU (Ireland)

Select a region where the clients are physically located to avoid unnecessary latency.

eg. Setting *configure.sh* to use the Sydney region.
```
#!/usr/bin/env bash
export REGION=ap-southeast-2
export VPC=
export SUBNET_1=
export SUBNET_2=
export SECURITY_GROUP=
```

### Step 2.2: Configure and create the ECS cluster
Setup an ECS EC2 cluster (and associated VPC resources). Remember to execute the commands from the directory of this _readme_
```
source ./configure.sh
# Setup Task Role
aws iam --region $REGION create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://task-execution-assume-role.json
aws iam --region $REGION attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Create EC2 ECS Cluster
ecs-cli configure --region $REGION --default-launch-type EC2 --cluster default-ec2 --config-name default-ec2
ecs-cli up --capability-iam --size 0 --cluster-config default-ec2 --ecs-profile my-profile --force
echo 'Finished EC2 ECS cluster & VPC setup'
```
_Note: The 'aws iam..' commands only need to be run once for your account_

The _'ecs-cli up'_ command will output your VPC, a security group, and 2 subnets, add these values to _configure.sh_.

Your _configure.sh_ file will now look like
```
#!/usr/bin/env bash
export REGION=ap-southeast-2
export VPC=vpc-0caed55b4789aeab6
export SUBNET_1=subnet-042f110de39a166ed
export SUBNET_2=subnet-049a6fb57ef9ef121
export SECURITY_GROUP=sg-00d1fe7b1af32bb7d
```

Setup an ECS Fargate cluster (using the VPC and associated resources used by the EC2 cluster)
```
source ./configure.sh
ecs-cli configure --cluster default-fargate --default-launch-type FARGATE --config-name default-fargate --region $REGION
ecs-cli up --size 0 --cluster-config default-fargate --ecs-profile my-profile --force --vpc $VPC --subnets $SUBNET_1,$SUBNET_2 --security-group $SECURITY_GROUP
echo 'Finished Fargate ECS cluster setup'
```

### Step 2.3: Configure security group

We will allow temporary access to your applications from the internet. 
Using AWS CLI, add the following security group ingress rule.
```
source ./configure.sh
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP --protocol tcp --port 1-65535 --cidr 0.0.0.0/0 --region $REGION
echo 'Security groups configured'
```
*This ingress rules will be removed in part 2 and should be skipped altogether if building a production cluster (real data). Remember to still set the security group in configure.sh*


---
Step 2 is now complete

The following components have been created and configured
* VPC
* Internet gateway
* Routing tables
* Subnets
* Security group
* Elastic Container Service cluster

Note: If you change regions, you will need to re-do step 2.
## Step 3: Start Services

Start GitLab, SqlCD, and Postgres. You may start these in separate shells
```
./compose-up.sh gitlab vcs 2048 8192
./compose-up.sh app sqlcd 2048 8192
./compose-up.sh postgres db 2048 8192
echo 'Started services'
```

Optionally start Spark instead of (or also with) Postgres. Start the worker service after the master service has successfully started.
```
./compose-up.sh master spark 1024 2048
./compose-up.sh worker spark 4096 8192
echo 'Started spark'
```
_Please edit SPARK_WORKER_CORES and SPARK_WORKER_MEMORY values in worker.yml to reflect the CPU cores and memory allocated_

<br/>

The *compose-up.sh* script requires 4 command line parameters
1) Name of service (accompanying docker-compose file should be named this followed by .yml)
2) Namespace. This along with the service name will be used to form the hostname *service.namespace*, eg. *app.sqlcd*. See [awsvpc](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html) for more details
3) Allocated CPU cores. For valid options please read [this](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html)
4) Allocated Memory. For valid options please read [this](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html)


You may find the IP address and status of the services with the following command. 
```
ecs-cli ps --cluster-config default-fargate --ecs-profile my-profile
```

Wait a few minutes for everything to initialize. Spark and GitLab may need up to 5 minutes to pre-populate data

The demo will be ready when you can: 
1. _ecs-cli ps_ displays an output similar to the following (depending on services started)
```
Name State Ports TaskDefinition Health
4a24b8d8-fae0-4363-90c4-fdae3db11503/db RUNNING postgres:10 UNKNOWN
4a24b8d8-fae0-4363-90c4-fdae3db11503/pgadmin RUNNING 52.78.18.47:80->80/tcp postgres:10 UNKNOWN
8c6bd02c-acaa-45fd-b062-ab4a85607d6d/master RUNNING 52.78.67.1:8080->8080/tcp master:3 UNKNOWN
c6f9d12f-ceac-4dbf-94f6-57544451c446/gitlab RUNNING 13.125.124.189:80->80/tcp gitlab:5 UNKNOWN
eb53ea52-45a6-4b12-adee-f6bdc251e45c/backend RUNNING app:8 UNKNOWN
eb53ea52-45a6-4b12-adee-f6bdc251e45c/frontend RUNNING 13.125.159.174:80->80/tcp app:8 UNKNOWN
f79b8586-b770-459c-bb06-800138d55a44/worker RUNNING 52.78.184.74:8081->8081/tcp worker:4 UNKNOWN
```
2. Successfully log in to gitlab using username: robert.jenkins password: password. 
The system is still initializing if any of the following occurs (please try again in a few minutes): 
    1. Asking to change your password (accounts not setup)
    2. ERR_EMPTY_RESPONSE (updating database)
    3. 502 error (updating database)
3. If using Spark: 'Thrift JDBC/ODBC Server' app should be in state READY
4. If using Postgres: can log in to PgAdmin

Now you can log in to SqlCD and select a demo. 

### Web Access (HTTP)
| Description | Port | Hostname* | Public URL (using example above)
| ------------- |-----|------- |-------
| SqlCD ** | 80 | app.sqlcd | http://13.125.159.174
| Gitlab | 80 | gitlab.vcs| http://13.125.124.189
| Postgres *** | 80 | postgres.db| http://52.78.18.47
| Spark cluster | 8080 | master.spark | http://52.78.67.1:8080
| Spark Sql App | 4040 | master.spark | http://52.78.67.1:4040
| Spark history | 18080 | master.spark | http://52.78.67.1:18080
| HDFS browser | 9870 | master.spark | http://52.78.67.1:9870
| Spark worker | 8081 | worker.spark | http://52.78.184.74:8081

_*Hostnames are not available to the client yet (see part 3 to enable these)<br/>_
_** Google Chrome browser is recommended<br/>_
_*** PgAdmin Web client for Postgres_

### Other Access

| Description | Port |
| ------------- |:-----:| 
| Gitlab SSH | 22 | 
| Postres JDBC | 5432 |
| Thrift JDBC | 10000 |

### Logs
You may view a tasks logs by executing the following command
eg. for task-id _eb53ea52-45a6-4b12-adee-f6bdc251e45c_ and container _backend_ from the example above 
```
ecs-cli logs --task-id eb53ea52-45a6-4b12-adee-f6bdc251e45c --container-name backend --cluster-config default-fargate --ecs-profile my-profile
```
task_id and container-name can be found from the name column (task-id/container-name) of ecs-cli ps


### Troubleshooting
| Error | Solution |
| ------------- |-----| 
| Failed to find output PrivateDNSNamespaceID | In AWS Console go to 'AWS cloud map' and delete 1) Service then 2) Name-space in that order | 
| Private DNS Namespace CloudFormation stack for app already exists | Same solution as above|


### Account Logins
|Name | GitLab Username | Postgres Username |
| ------------- |------------------|-------------------| 
|Robert Jenkins |robert.jenkins |rjenkins |
|Mary Kim |mary.kim |mkim |
|John Smith |john.smith |jsmith |
|Susan Fox |susan.fox |sfox |

- Passwords for all above accounts (gitlab and postgres) are set as the word *password*
- Spark has no login credentials. Please leave username & password blank
- Gitlab root account is username: *root*, password: *password*
- PgAdmin login is email: *admin@localhost* password: *password*. The hostname for the postgres DB is *postgres.db*, not ~~localhost~~
- Postgres superuser account is username:*postgres* password:*password*


*Some parts of GitLab will not work properly (eg. WebIDE, Merge Requests) until you use an internal DNS to access your applications ([Part 3](#part-3---using-internal-dns) of this tutorial). This is because the external_url in the docker-compose file needs to be the same as hostname used by the client - [more details](https://gitlab.com/gitlab-org/gitlab/issues/22111)*

## Shut down services
This will also delete any persisted data. Please see part 4 about persistence.
```
./compose-down.sh gitlab
./compose-down.sh app
./compose-down.sh postgres
./compose-down.sh master
./compose-down.sh worker
echo 'Services shutdown'
```

## Delete cluster
You may delete the ECS cluster (and all resources) - but this is not recommended unless you wish to permanently delete your data platform. 
There is no (minimal) cost with keeping an idle ECS cluster up. The majority of costs are associated with 1) Fargate Compute 2) Directory services 3) VPN or Virtual Clients (AWS WorkSpaces).
To create a new cluster you will need to redo part 2.
```
ecs-cli down --cluster default-fargate --cluster-config default-fargate --ecs-profile my-profile
ecs-cli down --cluster default-ec2 --cluster-config default-ec2 --ecs-profile my-profile
echo 'Deleted cluster'
```


# Part 2 - Secure the data platform
We will secure the SqlCD data platform (set up in part 1) as a public [subnet](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html). Only clients using a VPN Client or a virtual desktop (Amazon Workspaces) will be able to access the data platform. 

_For a production data platform may want to be segregate it from the internet or use a private subnet (outbound connections through NAT)._

Block in-bound internet traffic, but enable traffic from within the security group
```
source ./configure.sh
aws ec2 revoke-security-group-ingress --group-id $SECURITY_GROUP --protocol tcp --port 1-65535 --cidr 0.0.0.0/0 --region $REGION
aws ec2 revoke-security-group-ingress --group-id $SECURITY_GROUP --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP --protocol tcp --port 1-65535 --source-group $SECURITY_GROUP --region $REGION
echo 'Updated security group'
```

## Option 1: VPN Client
You may create a VPN tunnel from your own client system to the data platform.

1. Set up an [VPN Endpoint](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/what-is.html) per client by following this [AWS tutorial](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-getting-started.html) example
    * Select the same region as your ECS cluster
    * Example of a client IPv4 CIDR is: 10.0.100.0/22
    * Use mutual authentication (later on, you may wish to use AD)
    * Use VPN split tunnel to enable local traffic (eg. internet access from your system)    
2. Configure every VPN client endpoint to your data platform 
    1. Associate the target network as one of the subnets of your ECS cluster, which can found in _configure.sh_ (choose the VPN and either SUBNET_1 or SUBNET2)
    2. Apply the security group of your ECS cluster. This is found in ./configure.sh
    3. Authorize ingress rule of 0.0.0.0/0 (Allow access to all users) 


## Option 2: AWS Workspaces
You may create a virtual desktop using [AWS workspaces](https://docs.aws.amazon.com/workspaces/latest/adminguide/amazon-workspaces.html)
1. Setup an AWS workspace by following this [tutorial](https://docs.aws.amazon.com/workspaces/latest/adminguide/getting-started.html)
    1. Ensure you create a directory in the same VPC as your ECS cluster and use the existing subnets - these values can be found in _configure.sh_  
    2. Try to use a simple directory if it's available in your region - this can be used in part 3 of the tutorial. Alternatively, use a Managed Microsoft AD (more complicated and expensive)
2. Download the client and start a session
3. Add the workspace security group to the ECS cluster security group
    1. Find the workspace security group
        ```
        source ./configure.sh
        aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC Name=description,Values="Amazon WorkSpaces Security Group" --region $REGION | grep GroupId | head -n 1 
        ```
    2. Add this group as an ingress rule to the security group of your ECS cluster. Replace _XXX_ below with the security group found above (eg. sg-009913967f83df684)
        ```
        WORKSPACE_SECURITY_GROUP=XXX
        source ./configure.sh
        aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP --protocol tcp --port 1-65535 --source-group $WORKSPACE_SECURITY_GROUP --region $REGION
        ```     

## Services

Start & stop the services in the same way as part 2. Existing services (started in part 1) may still be used. 

To access the services you must now use the service's internal IP address which can be accessed in the AWS console by going to (ECS -> cluster -> Service -> task)

## Delete cluster
To delete the data platform's VPC you must dissociate any client VPN endpoints first.

### Troubleshooting
| Error | Solution |
| ------------- |-----| 
| Client connection timeout (WorkSpaces) | Ensure your ECS cluster security group has an ingress rule to accept all traffic from the security group 'Amazon WorkSpaces Security Group' | 
| Client connection timeout (VPN) | 1) Ensure your _VPN client end point_ has the same security group as your ECS cluster 2) Ensure Authorized ingress is set to a CIDR of 0.0.0.0/0|



# Part 3 - Using an internal DNS
This will enable your clients to use application host-names instead of IP addresses. Additionally, all GitLab functionality can now be used (MergeRequests, WebIDE)

| Description | Port | Hostname
| ------------- |-----|-------
| SqlCD | 80 | app.sqlcd 
| Gitlab | 80 | gitlab.vcs|
| Postgres | 80 | postgres.db|
| Spark cluster | 8080 | master.spark
| Spark Sql App | 4040 | master.spark 
| Spark history | 18080 | master.spark 
| HDFS browser | 9870 | master.spark 
| Spark worker | 8081 | worker.spark

## Step 1: Create an Active Directory service 
Follow [this tutorial](https://aws.amazon.com/premiumsupport/knowledge-center/private-hosted-zone-directory-service/)
* Preferably use a SimpleAD Small directory. Alternatively, an [AWS managed Microsoft AD](https://aws.amazon.com/blogs/security/how-to-set-up-dns-resolution-between-on-premises-networks-and-aws-using-aws-directory-service-and-microsoft-active-directory/) may be used but requires additional configuration.
* Use the VPC and the subnets from your ECS cluster (these can be found in _configure.sh_)
* You may skip this step if you are using AWS WorkSpaces from part 2 and a directory already exists.

## Step 2: Add the DNS Server to VPN Endpoints
If you are using a Client VPN (from part 2) you are required to add the directory DNS IP addresses to the VPN endpoint. In the AWS web console
1) Find the 2 IP addresses from the directory's details (in directory service)
2) Navigate to (VPC -> Client VPN Endpoints)
3) Select the VPN Endpoint -> Actions -> Modify Client VPN Endpoint
4) Enable 'DNS Servers Enabled' and enter the 2 IP addresses from the above sub-step 1
5) Save

### Troubleshooting
| Error | Solution |
| ------------- |-----| 
| When creating a directory the following error occurs: Failed to locate Availability Zone...This availability zone may be capacity constrained | Create a new subnet (in the other availability zone) with the same route table as the 2 existing availability zones. Use this subnet while creating the directory

# Part 4 - Using an EC2 cluster
An ECS cluster supports Fargate and EC2 [launch types](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html). 

This tutorial has used Fargate to introduce ECS clusters due its shallower learning curve (can access Fargate services publicly).
For a production cluster, EC2 may be more appropriate as there is finer-grained control over hardware specifications and [volume persistence](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-volumes.html) is available (eg. using [EBS](https://aws.amazon.com/ebs/), [EFS](https://aws.amazon.com/efs/)). 
Currently (Nov 2019) Fargate does not support persistence and only a 10GB ephemeral volume. SqlCD requires file system persistence in production (Docker Volume). Additionally, databases / compute-engines may require large / co-located store volumes (using SSDs)

## Creating ECS EC2 clusters & services
We will create a new EC2 cluster per application, as each EC2 cluster can only accommodate a single EC2 instance type. 

1) Continue using all the resources you have created from part 3.
0) [Shut down](#shut-down-services) all existing Fargate services started previously 
1) Import or create an EC2 [key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html). You may want to import the public key from your home _.ssh_ folder. 
    * The key pair should be named **id_rsa** by default, if you use a different name update _KEY_PAIR_NAME_ in _ec2/cluster-create.sh_ 
2) Start the services by running the script.  Edit the script to only start some of the services
    ```
    cd ec2
    ./start-all.sh
    ```
    Use the AWS web console to monitor the status of your services. 
3) (Optional) To SSH into your EC2 instances you need to authorize an ingress rule from the default security group (you VPN client uses) to the security group used by your EC2 cluster (found in *configure.sh*)    
## Remove ECS EC2 Clusters & Services    
Remove all services (and data) by running the script.
```
cd ec2
./stop-all.sh

``` 
## Persistence
* Your data will be persisted even after a service restart
* Data is persisted into the directory _/home/ec2-user/data_ in the EC2 instance
* The default EBS volume is 30GB and is deleted on the ECS cluster shutdown
* To use a larger EBS volume that persists after a cluster deletion do the following (this is viable for smaller ECS EC2 clusters). We will use postgres as an example
    1) Start the cluster using _create-cluster.sh_. ```./cluster-create.sh db m5.large 1```
    2) Create and attach a volume to every EC2 instance in your cluster [as shown here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-attaching-volume.html) 
    3) SSH into every EC2 instance
        1) Create the folder _/home/ec2-user/data_
        2) Mount the newly created EBS volume as _/home/ec2-user/data_ [as shown here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html)
    3) Start the service(s) _compose-up.sh_   ```./compose-up.sh postgres db 2048 7681```
* You may automate the above process by using a plugin. This is useful to deploy larger clusters
    * [Tutorial](https://aws.amazon.com/blogs/compute/amazon-ecs-and-docker-volume-drivers-amazon-ebs/)
    * [ECS-ClI notes](https://github.com/aws/amazon-ecs-cli/issues/927)
## Considerations 
* You must specify cpu/memory values less than what is available in your EC2 instances in the cluster 
* You may want to edit the scripts in the _ec2_ folder to be start / stop services individually, scale services, etc..
* ECS EC2 services (with awsvpc network mode) are not accessible publicly (without using NAT). 

### Troubleshooting
| Error | Solution |
| ------------- |-----| 
| The key pair 'id_rsa' does not exist (Service: AmazonAutoScaling; Status Code: 400;" | Is your SSH key pair named id_rsa? Remember to do step 2 of [Creating ECS EC2 services](#creating-ecs-ec2-services)


# Part 5 - Towards Production
This tutorial can be used as a template for a production data platform, but you will also need to consider
* Managed Services
* Networking
* Identity & Access Management
* Data backup and recovery
* High Availability

## Managed Services
Instead of creating and managing your own Git and DB servers, you may want to use a managed SaaS solution.
Examples include:

### Git & Web IDE
* [GitHub](https://github.com/)
* [BitBucket](https://bitbucket.org/product)
* [GitLab](https://about.gitlab.com/)


### Database
* [Amazon RDS - Postgres](https://aws.amazon.com/rds/postgresql/)
* [Amazon EMR - Spark, Hive etc..](https://aws.amazon.com/emr/)


## Networking
For a production data platform may want to be segregate it from the internet or use a private subnet (outbound connections through NAT). If the data platform has no internet connectivity an internal image registry is required

## Identity & Access Management
Do not use your root AWS account. Use [AWS IAM](https://aws.amazon.com/iam/), or potentially connect your on-premise [Active Directory](https://aws.amazon.com/blogs/security/how-to-connect-your-on-premises-active-directory-to-aws-using-ad-connector/).

## Further Details
[Contact us](https://support.sqlcd.com/hc/en-us/requests/new) for further details / support.

# Disclaimer
We are not liable for any intended or unintended AWS charges you may incur. Please ensure you have appropriate quotas in place.

THIS TUTORIAL & ACCOMPANYING SCRIPTS ARE PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
