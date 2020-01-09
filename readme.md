# SqlCD Demo

## Quick Start
To start your data platform execute the following commands from this directory (containing this *readme*). For more details please read this entire guide.
```
docker network create app_default
docker-compose --file gitlab.yml pull
docker-compose --file gitlab.yml up -d
docker-compose --file postgres.yml pull
docker-compose --file postgres.yml up -d
docker-compose --file app.yml pull
docker-compose --file app.yml up -d
echo 'Initializing all applications... This will take a few minutes'
docker exec -it gitlab-demo /bin/bash /poll-complete.sh
echo 'Finished'
```

Start using SqlCD at http://localhost:8081, along with GitLab at http://localhost:8082

## Applications

This demo will run the following applications on a single server/desktop system using docker-compose
* SqlCD
* GitLab 12.0.3 with existing demo repositories
* Postgres 11.5 (Python 3 UDFs extension) with existing demo data
* Apache Spark 2.4.4, Hive, HDFS 3.2.1 with existing demo data

Please read the [accompanying tutorials](https://support.sqlcd.com/hc/en-us/articles/360034551572) for this demo.

For a more stable multi-node cloud deployment (using Amazon Elastic Cloud) please read [this guide](https://github.com/chifleytech/sqlcd-public/tree/aws#sqlcd-aws-cloud-tutorial).

You can use this demo with Postgres or Spark - or even both. Please note that Spark is resource intense and may cause your desktop system to lag. 

The first time startup of GitLab and Apache Spark can take up 5-10 minutes due to their complexity and need to populate their data stores. This is dependant on your system specifications

For more information about using docker-compose please read https://docs.docker.com/compose/

## Pre-requisites 
* Latest version of docker installed (Configure maximum cores and memory are available to docker engine)
* Free ports numbers: 8081 - 8090, 5433-5434, 9090, and 2222
* Latest version of Google Chrome browser
* Postgres Demo: 4GB memory, 2 cores
* Spark Demo: 8GB memory, 2 cores


Ideally, your system should have 16GB of memory and 4 cores. With lower specifications, the system may significantly slow down due to resource contention. If your desktop computer is not sufficient, try the [multi-node cloud deployment](https://github.com/chifleytech/sqlcd-public/tree/aws#sqlcd-aws-cloud-tutorial). 

If Spark stops functioning you may need to increase the open file limits in docker and your system.

You may need to change the ports of the docker-compose files if they are already in use.

## Applications web access

Please access the applications using http://localhost and the following ports


### Web Access (HTTP)


| Description | Port |
| ------------- |:-----:| 
| SqlCD * | 8081 | 
| Gitlab | 8082 |
| Postgres ** | 8083 |
| Spark cluster | 8084 | 
| Spark Sql App | 8085 |
| Spark history | 8086 |
| HDFS browser | 8087 |
| Spark worker | 8088 |

_* Google Chrome browser is recommended_<br/>
_** PgAdmin Web client for Postgres_

### Other

| Description | Port |
| ------------- |:-----:| 
| Gitlab SSH | 2222 | 
| Postres JDBC | 5433 |
| Thrift JDBC | 5434 |


## Account Logins
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


## Commands
**Execute the commands from this current directory** (containing the readme.md you are now reading)
#### Step 1: Create network 
```
docker network create app_default
```

#### Step 2: Start GitLab and SqlCD 
```
docker-compose --file gitlab.yml pull
docker-compose --file app.yml pull
docker-compose --file gitlab.yml up -d
docker-compose --file app.yml up -d
echo 'Initializing all applications... This will take a few minutes'
docker exec -it gitlab-demo /bin/bash /poll-complete.sh
echo 'Finished'
```
---
You may either run step 2 or step 3, or both

#### Step 3: Start Postgres
```
docker-compose --file postgres.yml pull
docker-compose --file postgres.yml up -d
echo 'Initialized Postgres.'
```

#### Step 4: Start Spark (optional)
```
docker-compose --file spark.yml pull
docker-compose --file spark.yml up -d
echo 'Initializing Spark... This will take a few minutes'
docker exec -it spark-demo-master /bin/bash /poll-complete.sh
echo 'Finished'
```
---
#### Step 5: Use SqlCD Demo
Wait a few minutes for everything to initialise

The demo will be ready when you can: 
1. Successfully log in to gitlab http://localhost:8080 using username: *robert.jenkins* password: *password*. Check the state of Git by running
```docker exec -it gitlab-demo /bin/bash /poll-complete.sh```
2. If using Spark: 'Thrift JDBC/ODBC Server' app should be in state READY - http://localhost:8084. Check the state of Spark by running ```docker exec -it spark-demo-master /bin/bash /poll-complete.sh```
3. If using Postgres: can log in to PgAdmin - http://localhost:8083

Now you can log in to SqlCD : http://localhost:8081. (Select a demo)

---
#### Stop Containers
You may stop the containers with the following commands (data is retained)
```
docker-compose --file gitlab.yml stop
docker-compose --file app.yml stop
docker-compose --file postgres.yml stop 
docker-compose --file spark.yml stop
echo 'Stopped conainers'
```

You may start the containers again with the following commands 

```
docker-compose --file gitlab.yml start
docker-compose --file app.yml start
docker-compose --file postgres.yml start 
docker-compose --file spark.yml start
echo 'Started containers'
```


#### Remove Containers
You may stop and remove the containers with the following commands. All application data will be deleted.
```
docker-compose --file gitlab.yml down
docker-compose --file app.yml down
docker-compose --file postgres.yml down 
docker-compose --file spark.yml down
echo 'Removed containers'
```
---
#### View Streaming Logs
To view the SqlCD logs run the following command
```
docker exec sqlcd-service tail -f /root/logs/all.log
```

---
#### Local File System Persistence
To persist application data to your home directory in the folder 'sqlcd-demo' also include the compose file *-prod.yml in the up command.

This persisted data can be re-used even after the containers are removed and fresh containers started (include the respective *-prod.yml file every time docker-compose...up is run) 

```
docker-compose --file gitlab.yml --file gitlab-prod.yml up -d
docker-compose --file app.yml --file app-prod.yml up -d
docker-compose --file postgres.yml --file postgres-prod.yml up -d
docker-compose --file spark.yml --file spark-prod.yml up -d
echo 'Initializing all applications... Please wait a few minutes'
docker exec -it gitlab-demo /bin/bash /poll-complete.sh
docker exec -it spark-demo-master /bin/bash /poll-complete.sh
echo 'Finished'
```

# Non Docker Deployment
To deploy SqlCD without a container

### Requirements
* Linux based or MacOS system
* Latest version of docker installed - to pull artifacts
* Java 8 with an unrestricted encryption policy
* Node 12.8+
* Admin permissions to install node modules


**Execute the commands from this current directory** (containing the readme.md you are now reading)

### Clear existing data
Warning: This will clear all persisted application data too
```
rm -rf deploy/backend
rm -rf deploy/frontend
echo 'Removed persisted data'
```

### Download Artifacts
Download the latest application by extracting relevant resources from the latest running docker containers. 
If the folders 'backend' and 'frontend' already exist they will not be overwritten
```
docker-compose --file app.yml pull
docker-compose --file app.yml up -d
sleep 10 # wait 10 seconds for the application to initialize
[ ! -d "deploy/backend" ] && docker cp sqlcd-service:/bare-metal-deploy deploy/backend || echo "deploy/backend already exists"
[ ! -d "deploy/frontend" ] && docker cp sqlcd-ui:/root deploy/frontend || echo "deploy/frontend already exists"
docker-compose --file app.yml down # Remember to shut the container down, or the ports will clash with non-containerised deployment
echo 'Downloaded application'
```
The directories 'deploy/backend' and 'deploy/frontend' will be created

### Start Backend
By default the backend will listen on port 7080
```
cd deploy/backend
nohup ./start-sqlcd.sh > sqlcd-backend.log 2>&1 &
cd ../..
echo 'Started SqlCD backend'
```


### Start Frontend
Install NPM serve
```
sudo npm install -g serve
```

By default the frontend will listen on 5000, and proxy will listen on port 8080
```
cd deploy/frontend
export PROXY_BACKEND=localhost:7080
export PROXY_FRONTEND=localhost:5000
export PROXY_LISTEN_PORT=8080
./start-sqlcd-ui.sh
cd ../..
echo 'Started SqlCD frontend'
```

### Use
Access the (non-containerized) application on http://localhost:8080

### Shutdown
```
./deploy/frontend/stop-sqlcd-ui.sh
./deploy/backend/stop-sqlcd.sh
echo 'SqlCD shutdown'
```

You may want to configure the system to store data and logs in other directories. Please read [this guide](https://support.sqlcd.com/hc/en-us/articles/360035072091-Server-Configuration) for configuration options

## Support
Try out [support pages](https://support.sqlcd.com/) or [contact us](https://support.sqlcd.com/hc/en-us/requests/new).

## Disclaimer
THIS TUTORIAL & ACCOMPANYING SCRIPTS ARE PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
