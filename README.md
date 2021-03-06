<h1 align="center">ClusterHadoop</h1>

Here, you will find some scripts and config files to create a small cluster with docker container

<h2 align="center">Todo List</h2>

- [ ] Use the configCluster.cfg file to configure the cluster with the script "manageCluster.sh"

<h2 align="center">Scripts</h2>

### Prerequisite

Create the following folder :
- data : used to store persisten data from the cluster (mapping volume) (and notebook for zeppelin)
- package : used to store hadoop/spark/scala/.. archive to build the docker image
- tmp : used to store the temporary files


### Main script : manageCluster.sh

- To build the centos container : `./manageCluster.sh build`
- To deploy the cluster : `./manageCluster.sh deploy`
- To destroy the cluster : `./manageCluster.sh destroy`
- To configure the cluster (ssh & hosts) : `./manageCluster.sh config`
- To format hdfs namenode : `./manageCluster.sh format_hadoop`
- To start hdfs & yarn services : `./manageCluster.sh start_hadoop`
- To start spark & history server services : `./manageCluster.sh start_spark`
- To start zeppelin server services : `./manageCluster.sh start_zeppelin`
- To stop zeppelin server services : `./manageCluster.sh stop_zeppelin`
- To stop spark & history server services : `./manageCluster.sh stop_spark`
- To stop hdfs & yarn services : `./manageCluster.sh stop_hadoop`
- To stop all the docker container : `./manageCluster.sh stop_container`
- To start all the docker container : `./manageCluster.sh start_container`
- To start hdfs, yarn, spark, history server and zeppelin server services : `./managerCluster.sh start_all`


<h2 align="center">Docker Tips</h2>

- Build an Image : `docker build <folder>/. -t <image_name> -f <dockerfile>`
- to Run a container : `docker run -Pd -v <folder_host>:<folder_container> --network <network_name> --name <container_name> -it -h <container_name> <image_name>`
- Enter in the container : `docker exec -u <user> -it <container_name> bash`
- To kill a container : `docker kill <container_name>`
- To remove a container : `docker rm <container_name>`
- To list the container : `docker ps -a`
- To list the image : `docker image ls`
- To list the network : `docker network list`


<h2 align="center">Install Docker on OpenSuse</h2>

### General install
- Install docker package : `sudo zypper in docker`
- Start the systemd service : `sudo systemctl start docker`
- Activate the systemd service (boot) : `sudo systemctl enable docker`
- Add group "docker" for the user : `sudo usermod -G docker -a <username>`

### Proxy config
 1. Create systemd/docker folder : `mkdir -p /etc/systemd/system/docker.service.d`
 2. Create the file http-proxy.conf
   1. `sudo echo "[Service]" > /etc/systemd/system/docker.service.d/http-proxy.conf`
   2. `sudo echo "Environment=\"HTTP_PROXY=http://user:pwd@ip:port/\"" >> /etc/systemd/system/docker.service.d/http-proxy.conf`
   3. `sudo echo "Environment=\"HTTPS_PROXY=http://user:pwd@ip:port/\"" >> /etc/systemd/system/docker.service.d/http-proxy.conf`
 3. Restart docker service : `sudo systemctl restart docker`


<h2 align="center">Deploy full cluster</h2>

 1. Go to the foder "clusterhadoop"
 2. Build the docker image : `./manageCluster.sh build`
 3. Deploy the docker image : `./manageCluster.sh deploy`
 4. Configure the ssh access in the cluster : `./manageCluster.sh config`
 5. Start all the needed service (hadoop, spark et zeppelin) : `./manageCluster.sh start_all`


<h2 align="center">Cluster checking</h2>

### HDFS
 1. Connection to masternode : `docker exec -u hadoop -it nodemaster bash`
 2. Create a test folder for the user hadoop : `hdfs dfs -mkdir -p /user/hadoop/test`
 3. Create a text file in the test folder : `echo "this is just a little writing test" > sample.txt && hdfs dfs -put sample.txt test && rm sample.txt`
 4. Check if the file is in the hdfs test folder : `hdfs dfs -ls test/*`

### Yarn
 1. Connection to masternode : `docker exec -u hadoop -it nodemaster bash`
 2. Execute the following commande (pi calcul) : `yarn jar ~/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.0.jar pi 10 10`

### Spark
 1. Connection to masternode : `docker exec -u hadoop -it nodemaster bash`
 2. Execute the spark shell : `spark-shell --master yarn --num-executors 1 --executor-memory 512m`
 3. Check the spark version (in the shell) : `sc.version`
 4. Get inputfile (in the shell): `val inputfile = sc.textFile("test/sample.txt")`
 5. Get count (in the shell) : `val counts = inputfile.flatMap(line => line.split(" ")).map(word => (word,1)).reduceByKey(_+_)`
 6. Store result (in the shell) : `counts.saveAsTextFile("output")`
 7. Check on hdfs if the file is stored : `hdfs dfs -ls output/*` and `hdfs dfs -cat output/part*`
 8. Execute a calcul with client mode : `spark-submit --deploy-mode client --class org.apache.spark.examples.SparkPi ${SPARK_HOME}/examples/jars/spark-examples_2.11-2.4.3.jar 10`
 9. Execute a calcul with cluster mode : `spark-submit --deploy-mode cluster --class org.apache.spark.examples.SparkPi ${SPARK_HOME}/examples/jars/spark-examples_2.11-2.4.3.jar 10`

### Zeppelin
 1. Open Firefox and go to the zeppelin url : `http://<nodemaster>:8081` (see with `./manageCluster.sh info`)
 2. Create a note and try to run the following command in the first cell : 
```
%spark
sc
```


<h2 align="center">Info</h2>

### Using Alpine container

- Alpine Java don't work with hadoop cluster (java issues / musl instead of glibc)


### Software

- [Hadoop](https://hadoop.apache.org/releases.html)
- [Scala](https://www.scala-lang.org/download/)
- [Spark](https://spark.apache.org)
- [Zeppelin](http://zeppelin.apache.org)


<h2 align="center">Spark</h2>

- [General Doc](https://spark.apache.org/docs/latest/)
- [https://spark.apache.org/docs/latest/sql-data-sources-load-save-functions.html](https://spark.apache.org/docs/latest/sql-data-sources-load-save-functions.html)

### test config : interpreter.json
Master : spark://nodemaster:7077 
Master : yarn-client


### Exo

- Load CSV files (and check options)
- Load JSON files (and check options)
- select from dataframe
- filter on dataframe
- group by on dataframe
- agregates on dataframe
- ...
