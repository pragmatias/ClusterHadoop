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
Vg_keepNetwork="YES"
Vg_dirData="${Vg_dirRoot}/data"
Vg_dirConfig="${Vg_dirRoot}/config"
Vg_dirTmp="${Vg_dirRoot}/tmp"
Vg_dirDockerData="/home/hadoop/data"
Vg_dirDockerTmp="/tmp/docker"
Vg_dirDockerConfig="/mnt/docker"

Vg_delayCheckExecCmd=2 #sleep
Vg_limitCheckExecCmd=20 #rep

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
        Vl_cmd="wget http://apache.mirrors.ovh.net/ftp.apache.org/dist/hadoop/common/hadoop-3.2.0/hadoop-3.2.0.tar.gz"
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

    if [ ! -e "${Vg_dirRoot}/package/scala-2.13.0.tgz" ]
    then
        cd ${Vg_dirRoot}/package
        Vl_cmd="wget https://downloads.lightbend.com/scala/2.13.0/scala-2.13.0.tgz"
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

    if [ ! -e "${Vg_dirRoot}/package/spark-2.4.3-bin-without-hadoop.tgz" ]
    then
        cd ${Vg_dirRoot}/package
        Vl_cmd="wget https://archive.apache.org/dist/spark/spark-2.4.3/spark-2.4.3-bin-without-hadoop.tgz"
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
    Vl_tmpListContainer="${Vg_dirTmp}/destroyCluster_list_container.tmp"
    
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
    
    mkdir -p ${Vg_dirTmp}
    Vl_tmpListContainer="${Vg_dirTmp}/createCluster_list_container.tmp"
    
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
        mkdir -p ${Vg_dirTmp}
        Vl_cmd="docker run -Pd -v ${Vg_dirTmp}:${Vg_dirDockerTmp} -v ${Vg_dirConfig}:${Vg_dirDockerConfig} -v ${Vl_dirData}/logs:/home/hadoop/data/logs -v ${Vl_dirData}/nameNode:/home/hadoop/data/nameNode -v ${Vl_dirData}/dataNode:/home/hadoop/data/dataNode -v ${Vl_dirData}/namesecondary:/home/hadoop/data/namesecondary -v ${Vl_dirData}/tmp:/home/hadoop/data/tmp --network ${Vg_nameNetwork} --name ${tmpNode} -it -h ${tmpNode} ${Vg_nameDockerImage}"
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


function checkFinDockerExec {
    Vl_hostname=$1
    Vl_script=$2

    Vl_fin=0
    Vl_status=1
    Vl_ficResultCmd=${Vg_dirTmp}/${Vl_hostname}_${Vl_script}.CR
    Vl_ficResultLog=${Vg_dirTmp}/${Vl_hostname}_${Vl_script}.log
    Vl_passage=0

    while [ ${Vl_fin} -eq 0 ]
    do
        if [ -e ${Vl_ficResultCmd} ]
        then
            Vl_statusTmp=`cat ${Vl_ficResultCmd}`
            if [ ${Vl_statusTmp} -ge 0 ]
            then 
                Vl_status=${Vl_statusTmp}
                Vl_fin=1
            else 
                sleep ${Vg_delayCheckExecCmd}
            fi
        else
            sleep ${Vg_delayCheckExecCmd}
        fi

        Vl_passage=$((Vl_passage + 1))
        if [ ${Vl_passage} -gt ${Vg_limitCheckExecCmd} ]
        then 
            Vl_fin=1
        fi
    done

    if [ ${Vl_status} -gt 0 ]
    then 
        if [ -e ${Vl_ficResultLog} ]
        then
            logMessage "ERR" "Check the log file : ${Vl_ficResultLog}"
        fi
        return ${Vl_status}
    fi

    if [ -e ${Vl_ficResultLog} ]; then rm -f ${Vl_ficResultLog}; fi
    if [ -e ${Vl_ficResultCmd} ]; then rm -f ${Vl_ficResultCmd}; fi

    return 0
}


function configCluster {
    logMessage "INF" "Start configCluster"
    Vl_tmpListContainer="${Vg_dirTmp}/configClusterSSH_list_container.tmp"
    Vl_configAuthSSH=${Vg_dirTmp}/authorized_keys
    Vl_configHostsSSH=${Vg_dirTmp}/known_hosts
    Vl_configHostsServeur=${Vg_dirTmp}/hosts
    Vl_configHadoopWorkers=${Vg_dirTmp}/workers
    
    # Get the potentiel list of image to stop
    mkdir -p ${Vg_dirTmp}
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

    #get config scripts
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} cp ${Vg_dirDockerConfig}/scripts/manageDockerSSH.sh /home/hadoop/manageDockerSSH.sh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} cp ${Vg_dirDockerConfig}/scripts/manageDockerCluster.sh /home/hadoop/manageDockerCluster.sh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
    done

    sleep 2
    
    #config scripts chmod +x
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} chmod +x /home/hadoop/manageDockerSSH.sh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} chmod +x /home/hadoop/manageDockerCluster.sh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
    done
    
    sleep 2

    #get public ssh key from all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh get_ssh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 1
        checkFinDockerExec "${tmpNode}" "manageDockerSSH.sh"
        CR=$?
        if [ ${CR} -ne 0 ]
        then 
            logMessage "ERR" "${tmpNode} : /home/hadoop/manageDockerSSH.sh get_ssh [KO]"
            return 1
        fi
    done
    
    #set authorized_keys on all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh set_ssh"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 1
        checkFinDockerExec "${tmpNode}" "manageDockerSSH.sh"
        CR=$?
        if [ ${CR} -ne 0 ]
        then 
            logMessage "ERR" "${tmpNode} : /home/hadoop/manageDockerSSH.sh set_ssh [KO]"
            return 1
        fi
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
        eval ${Vl_cmd}
        sleep 1
        checkFinDockerExec "${Vg_nameMasterNode}" "manageDockerSSH.sh"
        CR=$?
        if [ ${CR} -ne 0 ]
        then 
            logMessage "ERR" "${Vg_nameMasterNode} : /home/hadoop/manageDockerSSH.sh get_host \"${tmpNode},${Vl_tmpIP}\" [KO]"
            return 1
        fi
    done
    
    #set known_hosts on all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh set_host"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 1
        checkFinDockerExec "${tmpNode}" "manageDockerSSH.sh"
        CR=$?
        if [ ${CR} -ne 0 ]
        then 
            logMessage "ERR" "${tmpNode} : /home/hadoop/manageDockerSSH.sh set_host [KO]"
            return 1
        fi
    done
    
    
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_cmd="docker exec -u root -d ${tmpNode} /home/hadoop/manageDockerSSH.sh cp_root_host"
        logMessage "INF" "${Vl_cmd}"
        ${Vl_cmd}
        sleep 1
        checkFinDockerExec "${tmpNode}" "manageDockerSSH.sh"
        CR=$?
        if [ ${CR} -ne 0 ]
        then 
            logMessage "ERR" "${tmpNode} : /home/hadoop/manageDockerSSH.sh cp_root_host [KO]"
            return 1
        fi
    done    
        
        
    #Define nodes (slave)
    cat ${Vg_configFileSlaves} > ${Vl_configHadoopWorkers}
    Vl_cmd="docker exec -u hadoop -d ${Vg_nameMasterNode} cp -f ${Vg_dirDockerTmp}/workers /home/hadoop/hadoop/etc/hadoop/workers"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    
    Vl_cmd="docker exec -u hadoop -d ${Vg_nameMasterNode} cp -f ${Vg_dirDockerTmp}/workers /home/hadoop/spark/conf/slaves"
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


function startContainer {

    logMessage "INF" "Start startContainer"

    Vl_tmpListContainer="${Vg_dirTmp}/startContainer_list_container.tmp"
    
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
        Vl_isPaused=`docker ps -a --filter "name=${tmpNode}" --filter "status=paused" -q | wc -l`
        if [ ${Vl_isPaused} -eq 1 ]
        then
            #start container
            Vl_cmd="docker start ${tmpNode}"
            logMessage "INF" "${Vl_cmd}"
            ${Vl_cmd}
            CR=$?
            if [ ${CR} -ne 0 ]
            then 
                logMessage "ERR" "Container ${tmpNode} not started"
                return 1
            fi
        fi
    done
    
    #delete temporary files
    rm -f ${Vl_tmpListContainer}
    
    
    logMessage "INF" "End startContainer"
    return 0
}


function stopContainer {

    logMessage "INF" "Start stopContainer"

    Vl_tmpListContainer="${Vg_dirTmp}/stopContainer_list_container.tmp"
    
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
        
        Vl_isRunning=`docker ps -a --filter "name=${tmpNode}" --filter "status=running" -q | wc -l`
        if [ ${Vl_isRunning} -eq 1 ]
        then
            #stop container
            Vl_cmd="docker stop ${tmpNode}"
            logMessage "INF" "${Vl_cmd}"
            ${Vl_cmd}
            CR=$?
            if [ ${CR} -ne 0 ]
            then 
                logMessage "ERR" "Container ${tmpNode} not stopped"
                return 1
            fi
        fi
    done
    
    #delete temporary files
    rm -f ${Vl_tmpListContainer}
    
    
    logMessage "INF" "End stopContainer"
    return 0
}


function formatClusterHadoop {
    #delete data for all nodes (without deleting folder)
    Vl_tmpListContainer="${Vg_dirTmp}/createCluster_list_container.tmp"
    
    # Get the potentiel list of image to stop
    rm -f ${Vl_tmpListContainer}
    
    echo ${Vg_nameMasterNode} > ${Vl_tmpListContainer}

    if [ -e ${Vg_configFileSlaves} ]
    then 
        cat ${Vg_configFileSlaves} >> ${Vl_tmpListContainer}
    fi
    
    #execution on the list of node
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        #create data folder
        logMessage "INF" "delete files from ${Vg_dirData}/${tmpNode}"
        rm -rf ${Vg_dirData}/${tmpNode}/logs/*
        rm -rf ${Vg_dirData}/${tmpNode}/nameNode/*
        rm -rf ${Vg_dirData}/${tmpNode}/dataNode/*
        rm -rf ${Vg_dirData}/${tmpNode}/namesecondary/*
        rm -rf ${Vg_dirData}/${tmpNode}/tmp/*
    done    

    rm -f ${Vl_tmpListContainer}


    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/manageDockerCluster.sh format_hadoop"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    checkFinDockerExec "nodemaster" "manageDockerCluster.sh"
    CR=$?
    if [ ${CR} -ne 0 ]
    then 
        logMessage "ERR" "nodemaster : /home/hadoop/manageDockerCluster.sh format_hadoop [KO]"
        return 1
    fi
}


function startClusterHadoop {
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/manageDockerCluster.sh start_hadoop"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    checkFinDockerExec "nodemaster" "manageDockerCluster.sh"
    CR=$?
    if [ ${CR} -ne 0 ]
    then 
        logMessage "ERR" "nodemaster : /home/hadoop/manageDockerCluster.sh start_hadoop [KO]"
        return 1
    fi
    return 0
}


function stopClusterHadoop {
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/manageDockerCluster.sh stop_hadoop "
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 5
    checkFinDockerExec "nodemaster" "manageDockerCluster.sh"
    CR=$?
    if [ ${CR} -ne 0 ]
    then 
        logMessage "ERR" "nodemaster : /home/hadoop/manageDockerCluster.sh stop_hadoop [KO]"
        return 1
    fi
    return 0
}


function startClusterSpark {
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/manageDockerCluster.sh start_spark"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 10
    checkFinDockerExec "nodemaster" "manageDockerCluster.sh"
    CR=$?
    if [ ${CR} -ne 0 ]
    then 
        logMessage "ERR" "nodemaster : /home/hadoop/manageDockerCluster.sh start_spark [KO]"
        return 1
    fi
    return 0
}


function stopClusterSpark {
    Vl_cmd="docker exec -u hadoop -d nodemaster /home/hadoop/manageDockerCluster.sh stop_spark"
    logMessage "INF" "${Vl_cmd}"
    ${Vl_cmd}
    sleep 10
    checkFinDockerExec "nodemaster" "manageDockerCluster.sh"
    CR=$?
    if [ ${CR} -ne 0 ]
    then 
        logMessage "ERR" "nodemaster : /home/hadoop/manageDockerCluster.sh stop_spark [KO]"
        return 1
    fi
    return 0
}



function showInfo {
  masterIp=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${Vg_nameMasterNode}`
  echo "Hadoop cluster info  @ nodemaster : http://${masterIp}:8088/cluster"
  echo "DFS Health           @ nodemaster : http://${masterIp}:9870/dfshealth.html"
  echo "Spark info           @ nodemaster : http://${masterIp}:8080"
  echo "History (Spark) info @ nodemaster : http://${masterIp}:18080"
  echo "Container access     @ nodemaster : docker exec -u hadoop -it nodemaster bash"
}

function usage {
    echo "command : ${0} [build|deploy|destroy|config|info|start_hadoop|stop_hadoop|format_hadoop|start_spark|stop_spark]"
    echo "list of options :"
    echo "     - build : build the docker image"
    echo "     - deploy : deploy the docker container"
    echo "     - config : configure the container (ssh & more)"
    echo "     - info : give information about webbapps (cluster webUI)"
    echo "     - format_hadoop : format namenode (hadoop)"
    echo "     - start_hadoop : start dfs & yarn services (hadoop)"
    echo "     - stop_hadoop : stop dfs & yarn services (hadoop)"
    echo "     - start_spark : start spark & history server services (spark)"
    echo "     - stop_spark : stop spark & history server services (spark)"
    echo "     - start_container : start all docker container (cluster)"
    echo "     - stop_container : stop all docker container (cluster)"
}

Vg_Param=$1
CR=0

Vg_TestArgs=$(echo "|build|deploy|destroy|config|info|start_hadoop|stop_hadoop|format_hadoop|start_spark|stop_spark|start_container|stop_container|" | grep "|${Vg_Param}|" | wc -l)

if [ ${Vg_TestArgs} -eq 0 ]
then 
    usage
    exit 1
fi

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



if [ "${Vg_Param}" = "start_container" -a ${CR} -eq 0 ]
then
    startContainer
    CR=$?
fi

if [ "${Vg_Param}" = "stop_container" -a ${CR} -eq 0 ]
then
    stopContainer
    CR=$?
fi




if [ "${Vg_Param}" = "format_hadoop" -a ${CR} -eq 0 ]
then
    formatClusterHadoop
    CR=$?
fi

if [ "${Vg_Param}" = "start_hadoop" -a ${CR} -eq 0 ]
then
    startClusterHadoop
    CR=$?
    showInfo
fi

if [ "${Vg_Param}" = "stop_hadoop" -a ${CR} -eq 0 ]
then
    stopClusterHadoop
    CR=$?
fi

if [ "${Vg_Param}" = "start_spark" -a ${CR} -eq 0 ]
then
    startClusterSpark
    CR=$?
    showInfo
fi

if [ "${Vg_Param}" = "stop_spark" -a ${CR} -eq 0 ]
then
    stopClusterSpark
    CR=$?
fi



if [ ${CR} -eq 0 ]
then 
    logMessage "INF" "End [OK]"
else
    logMessage "ERR" "End [KO]"
fi

exit ${CR}

