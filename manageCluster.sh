#!/bin/bash
#set -x


# Manage cluster hadoop !


#Global parameter Cluster config
Vg_configFileCluster="configCluster.cfg"
Vg_configFileSlaves="configSlaves.cfg"
Vg_dirRoot=${PWD}

# Global parameter docker image
Vg_dirDockerImage="hadoop"
Vg_nameDockerImage="centos_hadoop"
Vg_nameDockerFile="Dockerfile"


# Global parameter Cluster
Vg_nameMasterNode="nodemaster"
Vg_nameNetwork="ClusterNet"
Vg_dirData="${Vg_dirRoot}/data"
Vg_keepNetwork="YES"

#log file
LOG=/tmp/$(basename "$0" .sh).log

function logMessage {
    #gestion des parametres
    type=$1
    message=$2

    statut_date=`date "+%Y-%m-%d"`
    statut_time=`date "+%H:%M:%S"`

    #affichage du message dans la sortie courante
    echo "${statut_date} ${statut_time} - ${type} - ${message}"
}




function buildCluster {
    logMessage "INF" "Start buildCluster"

    mkdir -p ${Vg_dirRoot}/package
    if [ ! -e "${Vg_dirRoot}/package/hadoop-3.2.0.tar.gz" ]
    then
        cd ${Vg_dirRoot}/package
        Vl_cmd="wget http://mirrors.ircam.fr/pub/apache/hadoop/common/stable/hadoop-3.2.0.tar.gz"
        logMessage "INF" "Get Hadoop archive [${Vg_dirRoot}/package] : ${Vl_cmd}"
        ${Vl_cmd}
        CR=$?
        if [ ${CR} -ne 0 ]
        then
            logMessage "ERR" "Get Hadoop archive [${CR}]"
            cd -
            return 1
        fi
        cd -
    fi

    if [ ! -e "${Vg_dirRoot}/package/scala-2.12.8.tgz" ]
    then
        cd ${Vg_dirRoot}/package
        Vl_cmd="wget https://downloads.lightbend.com/scala/2.12.8/scala-2.12.8.tgz"
        logMessage "INF" "Get Scala archive [${Vg_dirRoot}/package] : ${Vl_cmd}"
        ${Vl_cmd}
        CR=$?
        if [ ${CR} -ne 0 ]
        then
            logMessage "ERR" "Get Scala archive [${CR}]"
            cd -
            return 1
        fi
        cd -
    fi

    if [ ! -e "${Vg_dirRoot}/package/spark-2.4.0-bin-hadoop2.7.tgz" ]
    then
        cd ${Vg_dirRoot}/package
        Vl_cmd="wget https://archive.apache.org/dist/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz"
        logMessage "INF" "Get Spark archive [${Vg_dirRoot}/package] : ${Vl_cmd}"
        ${Vl_cmd}
        CR=$?
        if [ ${CR} -ne 0 ]
        then
            logMessage "ERR" "Get Spark archive [${CR}]"
            cd -
            return 1
        fi
        cd -
    fi




    Vl_cmd="docker build . -t ${Vg_nameDockerImage} -f ${Vg_dirDockerImage}/${Vg_nameDockerFile}"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    CR=$?
    if [ ${CR} -ne 0 ]
    then 
        logMessage "ERR" "docker build ${Vg_nameDockerImage} [${CR}]"
        return 1
    fi

    logMessage "INF" "End buildCluster"

    return 0
}


function deployCluster {

    createCluster

    return 0
}



function destroyCluster {

    logMessage "INF" "Start destroyCluster"
    Vl_tmpListContainer="destroyCluster_list_container.tmp"
    
    # Get the potentiel list of image to stop
    rm -f ${Vl_tmpListContainer}
    
    echo ${Vg_nameMasterNode} > ${Vl_tmpListContainer}

    if [ -e ${Vg_configFileSlaves} ]
    then 
        cat ${Vg_configFileSlaves} >> ${Vl_tmpListContainer}
    fi

    logMessage "INF" "Number of node : `cat ${Vl_tmpListContainer} | wc -l`"
    
    #execution on the list of node
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_idContainer=`docker ps -a --filter name=${tmpNode}$ -q`
        if [ "x${Vl_idContainer}" != "x" ]
        then
            logMessage "INF" "Name ${tmpNode} exist [id=${Vl_idContainer}]"
            
            Vl_cmd="docker kill ${Vl_idContainer}"
            logMessage "INF" "${Vl_cmd}"
            ${Vl_cmd}

            Vl_cmd="docker rm ${Vl_idContainer}"
            logMessage "INF" "${Vl_cmd}"
            ${Vl_cmd}

            Vl_exist=`docker ps -a --filter name=${tmpNode}$ -q | wc -l`
            if [ ${Vl_exist} -ne 0 ]
            then
                logMessage "ERR" "Container ${tmpNode} [${Vl_idContainer}] not deleted"
                return 1
            fi

        fi
    done
    
    #delete temporary files
    rm -f ${Vl_tmpListContainer}
    
   
    logMessage "INF" "End destroyCluster"
    return 0
}



function destroyNetwork {
    #don't destroy if the parameter "keepNetwork = YES"
    if [ "${Vg_keepNetwork}" = "YES" -o "${Vg_keepNetwork}" = "yes" ]
    then 
        return 0
    fi

    logMessage "INF" "Start destroyNetwork"
    
    #remove docker network (if exist)
    Vl_idNetwork=`docker network ls --filter name=${Vg_nameNetwork}$ -q`
    if [ "x${Vl_idNetwork}" != "x" ]
    then
        logMessage "INF" "Network ${Vg_nameNetwork} exist [id=${Vl_idNetwork}]"
        
        logMessage "INF" "docker network rm ${Vl_idNetwork}"
        docker network rm ${Vl_idNetwork}
        sleep 2
    fi
    
    logMessage "INF" "End destroyNetwork"
    return 0
}


function createNetwork {

    logMessage "INF" "Start createNetwork"
    
    Vl_nbNetwork=`docker network ls --filter name=${Vg_nameNetwork}$ -q | wc -l`
    if [ ${Vl_nbNetwork} -eq 0 ]
    then 
        #create docker network
        logMessage "INF" "docker network create --driver bridge ${Vg_nameNetwork}"
        docker network create --driver bridge ${Vg_nameNetwork}
        CR=$?
        if [ ${CR} -ne 0 ]
        then
            logMessage "ERR" "Network ${Vg_nameNetwork} not created"
            return 1
        fi
    fi
    
    logMessage "INF" "End createNetwork"
    return 0
}



function createCluster {

    logMessage "INF" "Start createCluster"

    Vl_tmpListContainer="createCluster_list_container.tmp"
    
    # Get the potentiel list of image to stop
    rm -f ${Vl_tmpListContainer}
    
    echo ${Vg_nameMasterNode} > ${Vl_tmpListContainer}

    if [ -e ${Vg_configFileSlaves} ]
    then 
        cat ${Vg_configFileSlaves} >> ${Vl_tmpListContainer}
    fi
    
    logMessage "INF" "Number of node : `cat ${Vl_tmpListContainer} | wc -l`"
    
    


    #execution on the list of node
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        
        #create data folder
        logMessage "INF" "Create the folder (data)"
        Vl_dirData="${Vg_dirData}/${tmpNode}"
        mkdir -p ${Vl_dirData}/logs ${Vl_dirData}/nameNode ${Vl_dirData}/dataNode ${Vl_dirData}/namesecondary ${Vl_dirData}/tmp

        #create container
        Vl_cmd="docker run -Pd -v ${Vg_dirRoot}/config:/config -v ${Vl_dirData}/logs:/home/hadoop/data/logs -v ${Vl_dirData}/nameNode:/home/hadoop/data/nameNode -v ${Vl_dirData}/dataNode:/home/hadoop/data/dataNode -v ${Vl_dirData}/namesecondary:/home/hadoop/data/namesecondary -v ${Vl_dirData}/tmp:/home/hadoop/data/tmp --network ${Vg_nameNetwork} --name ${tmpNode} -it -h ${tmpNode} ${Vg_nameDockerImage}"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        CR=$?
        if [ ${CR} -ne 0 ]
        then 
            logMessage "ERR" "Container ${tmpNode} not started"
            return 1
        fi
    done
    
    #delete temporary files
    rm -f ${Vl_tmpListContainer}
    
    
    logMessage "INF" "End createCluster"
    return 0
}




function configCluster {
    logMessage "INF" "Start configCluster"
    Vl_tmpListContainer="configClusterSSH_list_container.tmp"
    Vl_configAuthSSH=config/authorized_keys
    Vl_configHostsSSH=config/known_hosts
    Vl_configHostsServeur=config/hosts
    Vl_configHadoopWorkers=config/workers
    
    # Get the potentiel list of image to stop
    rm -f ${Vl_tmpListContainer}
    rm -f ${Vl_configAuthSSH}
    rm -f ${Vl_configHostsSSH}
    rm -f ${Vl_configHostsServeur}
    rm -f ${Vl_configHadoopWorkers}
    
    echo ${Vg_nameMasterNode} > ${Vl_tmpListContainer}

    if [ -e ${Vg_configFileSlaves} ]
    then 
        cat ${Vg_configFileSlaves} >> ${Vl_tmpListContainer}
    fi
    
    logMessage "INF" "Number of node : `cat ${Vl_tmpListContainer} | wc -l`"
    
    #get public ssh key from all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} cp /config/manageDockerSSH.sh /home/hadoop/manageDockerSSH.sh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 3
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} chmod +x /home/hadoop/manageDockerSSH.sh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 2
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh get_ssh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 5
    done
    
    #set authorized_keys on all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh set_ssh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 2
    done
    
    
    #start hosts writing
    echo -e "127.0.0.1\tlocalhost" > ${Vl_configHostsServeur}
    echo -e "::1\tlocalhost\tip6-localhost\tip6-loopback" >> ${Vl_configHostsServeur}
    echo -e "fe00::0\tip6-localnet" >> ${Vl_configHostsServeur}
    echo -e "ff00::0\tip6-mcastprefix" >> ${Vl_configHostsServeur}
    echo -e "ff02::1\tip6-allnodes" >> ${Vl_configHostsServeur}
    echo -e "ff02::2\tip6-allrouters" >> ${Vl_configHostsServeur}

    
    
    #get known_hosts from all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_tmpIP=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${tmpNode}`
        
        #Ecriture du fichier "/etc/hosts" pour le root
        echo -e "${Vl_tmpIP}\t${tmpNode}" >> ${Vl_configHostsServeur}
        
        #Gestion des hosts ssh
        Vl_cmd="docker exec -u hadoop -d ${Vg_nameMasterNode} /home/hadoop/manageDockerSSH.sh get_host \"${tmpNode},${Vl_tmpIP}\""
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 3
    done
    
    #set known_hosts on all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh set_host"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 1
    done
    
    
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u root -d ${tmpNode} cp /config/hosts /etc/hosts"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 2
    done    
        
        
    #Define nodes (slave)
    cat ${Vg_configFileSlaves} > ${Vl_configHadoopWorkers}
    Vl_cmd="docker exec -u hadoop -d ${Vg_nameMasterNode} cp /config/workers /home/hadoop/hadoop/etc/hadoop/workers"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 2
    
    Vl_cmd="docker exec -u hadoop -d ${Vg_nameMasterNode} cp /config/workers /home/hadoop/spark/conf/slaves"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 2
    
    #delete temporary files
    rm -f ${Vl_tmpListContainer}
    rm -f ${Vl_configAuthSSH}
    rm -f ${Vl_configHostsSSH}
    rm -f ${Vl_configHostsServeur}
    rm -f ${Vl_configHadoopWorkers}
    
    logMessage "INF" "End configCluster"
    
    return 0
}





function startCluster {
    #docker exec -u hadoop -d nodemaster hdfs namenode -format
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/hadoop/sbin/start-dfs.sh"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 8
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/hadoop/sbin/start-yarn.sh"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/spark/sbin/start-master.sh"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/spark/sbin/start-slaves.sh"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    return 0
}


function stopCluster {
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/spark/sbin/stop-slaves.sh"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/spark/sbin/stop-master.sh"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/hadoop/sbin/stop-yarn.sh"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/hadoop/sbin/stop-dfs.sh"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    return 0
}


function formatCluster {
    Vl_cmd="docker exec -u hadoop -d nodemaster hadoop/bin/hdfs namenode -format"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    return 0
}



function showInfo {
  masterIp=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${Vg_nameMasterNode}`
  echo ""
  echo "Hadoop info @ nodemaster : http://${masterIp}:8088/cluster"
  echo "DFS Health  @ nodemaster : http://${masterIp}:9870/dfshealth.html"
  echo "Spark info  @ nodemaster : http://${masterIp}:8080"
  echo "Container   @ nodemaster : docker exec -u hadoop -it nodemaster bash"
}

function usage {
    echo "command : ${0} [build|deploy|destroy|config|info|start_hadoop|stop_hadoop|format_hadoop]"
    echo "list of options :"
    echo "     - build : build the docker image"
    echo "     - deploy : deploy the docker container"
    echo "     - config : configure the container (ssh & more)"
    echo "     - info : give information about webbapps (cluster webUI)"
    echo "     - start_hadoop : start dfs & yarn services (hadoop)"
    echo "     - stop_hadoop : stop dfs & yarn services (hadoop)"
    echo "     - format_hadoop : format namenode (hadoop)"
}

Vg_Param=$1
CR=0

Vg_TestArgs=$(echo "|build|deploy|destroy|config|info|start_hadoop|stop_hadoop|format_hadoop|" | grep "|${Vg_Param}|" | wc -l)

if [ ${Vg_TestArgs} -eq 0 ]
then 
    usage
    exit 1
fi

echo 

echo `date '+%Y-%m-%d %H:%M:%S'`" - Start (param=${Vg_Param})"

if [ "${Vg_Param}" = "build" -a ${CR} -eq 0 ]
then 
    buildCluster
    CR=$?
fi


if [ "${Vg_Param}" = "deploy" -a ${CR} -eq 0 ]
then 
    createNetwork
    CR=$?
    if [ ${CR} -eq 0 ]
    then
        deployCluster
        CR=$?
    fi
fi

if [ "${Vg_Param}" = "destroy" -a ${CR} -eq 0 ]
then 
    destroyCluster
    CR=$?
    if [ ${CR} -eq 0 ]
    then
        destroyNetwork
        CR=$?
    fi
fi


if [ "${Vg_Param}" = "config" -a ${CR} -eq 0 ]
then 
    configCluster
    CR=$?
fi

if [ "${Vg_Param}" = "info" -a ${CR} -eq 0 ]
then 
    showInfo
    CR=$?
fi

if [ "${Vg_Param}" = "start_hadoop" -a ${CR} -eq 0 ]
then
    startCluster
    CR=$?
    showInfo
fi

if [ "${Vg_Param}" = "stop_hadoop" -a ${CR} -eq 0 ]
then
    stopCluster
    CR=$?
fi


if [ "${Vg_Param}" = "format_hadoop" -a ${CR} -eq 0 ]
then
    formatCluster
    CR=$?
fi


if [ ${CR} -eq 0 ]
then 
    logMessage "INF" "End [OK]"
else
    logMessage "ERR" "End [KO]"
fi

exit ${CR}

