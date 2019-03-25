<h1 align="center">ClusterHadoop</h1>

Here, you will find some scripts and config files to create a small cluster with docker container

<h2 align="center">Todo List</h2>

- [ ] Use alpine image ?
- [ ] Use the configCluster.cfg file to configure the cluster with the script "manageCluster.sh"
- [ ] Add log function (managerCluster)
- [ ] Hadoop configuration files modification to use less memory
- [ ] Management of the docker command return
- [ ] Clean the list of port (expose)
- [ ] Add Scala in the main container
- [ ] Add Spark node in the cluster (container + node)


<h2 align="center">Scripts</h2>

- The main script is `manageCluster.sh`
- To build the centos container `./manageCluster.sh build`
- To deploy the cluster `./manageCluster.sh deploy`
- To destroy the cluster `./manageCluster.sh destroy`
- To configure the cluster (ssh & hosts) `./manageCluster.sh config`


<h2 align="center">Docker Tips</h2>

- Build an Image : `docker build <folder>/. -t <image_name> -f <dockerfile>`
- to Run a container : `docker run -Pd -v <folder_host>:<folder_container> --network <network_name> --name <container_name> -it -h <container_name> <image_name>`
- Enter in the container : `docker exec -u <user> -it <container_name> bash`
- To kill a container : `docker kill <container_name>`
- To remove a container : `docker rm <container_name>`
- To list the container : `docker ps -a`
- To list the network : `docker network list`


<h2 align="center">Install Docker on OpenSuse</h2>

- Install docker package : `sudo zypper in docker`
- Start the systemd service : `sudo systemctl start docker`
- Activate the systemd service (boot) : `sudo systemctl enable docker`
- Add group "docker" for the user : `sudo usermod -G docker -a <username>`
