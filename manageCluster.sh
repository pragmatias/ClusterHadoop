#!/bin/bash
#set -x


# Manage cluster hadoop !


#Global parameter Cluster config
Vg_configFileCluster="configCluster.cfg"
Vg_configFileSlaves="configSlaves.cfg"

# Global parameter docker image
Vg_dirDockerImage="centos"
Vg_nameDockerImage="centos_hadoop"
Vg_nameDockerFile="Dockerfile"


# Global parameter Cluster
Vg_nameMasterNode="nodemaster"
Vg_nameNetwork="tarace"

function buildCluster {

    echo `date '+%Y-%m-%d %H:%M:%S'`" - docker build ${Vg_dirDockerImage}/. -t ${Vg_nameDockerImage} -f ${Vg_dirDockerImage}/${Vg_nameDockerFile}"
    docker build ${Vg_dirDockerImage}/. -t ${Vg_nameDockerImage} -f ${Vg_dirDockerImage}/${Vg_nameDockerFile}
    if [ ${?} -ne 0 ]
    then 
        echo `date '+%Y-%m-%d %H:%M:%S'`" - docker build ${Vg_nameDockerImage} [KO]"
        return 1
    else
        echo `date '+%Y-%m-%d %H:%M:%S'`" - docker build ${Vg_nameDockerImage} [OK]"
    fi

    return 0
    
}


function deployCluster {

    destroyCluster
    
    createCluster
        
    return 0
}



function destroyCluster {

    echo `date '+%Y-%m-%d %H:%M:%S'`" - Start destroyCluster"
    Vl_tmpListContainer="destroyCluster_list_container.tmp"
    
    # Get the potentiel list of image to stop
    rm -f ${Vl_tmpListContainer}
    
    echo ${Vg_nameMasterNode} > ${Vl_tmpListContainer}

    if [ -e ${Vg_configFileSlaves} ]
    then 
        cat ${Vg_configFileSlaves} >> ${Vl_tmpListContainer}
    fi

    echo `date '+%Y-%m-%d %H:%M:%S'`" - List of the node : `cat ${Vl_tmpListContainer}`"
    
    #execution on the list of node
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        Vl_idContainer=`docker ps -a --filter name=${tmpNode}$ -q`
        if [ "x${Vl_idContainer}" != "x" ]
        then
            echo `date '+%Y-%m-%d %H:%M:%S'`" - Name ${tmpNode} exist [id=${Vl_idContainer}]"
            
            echo `date '+%Y-%m-%d %H:%M:%S'`" - docker kill ${Vl_idContainer}"
            docker kill ${Vl_idContainer}
            sleep 5
            
            echo `date '+%Y-%m-%d %H:%M:%S'`" - docker rm ${Vl_idContainer}"
            docker rm ${Vl_idContainer}
            sleep 2
        fi
    done
    
    #delete temporary files
    rm -f ${Vl_tmpListContainer}
    
   
    #remove docker network (if exist)
    Vl_idNetwork=`docker network list --filter name=${Vg_nameNetwork}$ -q`
    if [ "x${Vl_idNetwork}" != "x" ]
    then
        echo `date '+%Y-%m-%d %H:%M:%S'`" - Network ${Vg_nameNetwork} exist [id=${Vl_idNetwork}]"
        
        echo `date '+%Y-%m-%d %H:%M:%S'`" - docker network rm ${Vl_idNetwork}"
        docker network rm ${Vl_idNetwork}
        sleep 2
    fi
    
    
    echo `date '+%Y-%m-%d %H:%M:%S'`" - End destroyCluster"
    return 0
}




function createCluster {

    echo `date '+%Y-%m-%d %H:%M:%S'`" - Start createCluster"
    Vl_tmpListContainer="createCluster_list_container.tmp"
    
    # Get the potentiel list of image to stop
    rm -f ${Vl_tmpListContainer}
    
    echo ${Vg_nameMasterNode} > ${Vl_tmpListContainer}

    if [ -e ${Vg_configFileSlaves} ]
    then 
        cat ${Vg_configFileSlaves} >> ${Vl_tmpListContainer}
    fi
    
    echo `date '+%Y-%m-%d %H:%M:%S'`" - List of the node : `cat ${Vl_tmpListContainer}`"
    
    
    #create docker network
    echo `date '+%Y-%m-%d %H:%M:%S'`" - docker network create --driver bridge ${Vg_nameNetwork}"
    docker network create --driver bridge ${Vg_nameNetwork}
    sleep 2

    #execution on the list of node
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        
        echo `date '+%Y-%m-%d %H:%M:%S'`" - docker run -Pd -v ${PWD}/${Vg_dirDockerImage}/config:/config --network ${Vg_nameNetwork} --name ${tmpNode} -it -h ${tmpNode} ${Vg_nameDockerImage}"
        docker run -Pd -v ${PWD}/${Vg_dirDockerImage}/config:/config --network ${Vg_nameNetwork} --name ${tmpNode} -it -h ${tmpNode} ${Vg_nameDockerImage}
        sleep 5
    done
    
    #delete temporary files
    rm -f ${Vl_tmpListContainer}
    
    
    echo `date '+%Y-%m-%d %H:%M:%S'`" - End destroyCluster"
    return 0
}




function configCluster {
    echo `date '+%Y-%m-%d %H:%M:%S'`" - Start configCluster"
    Vl_tmpListContainer="configClusterSSH_list_container.tmp"
    Vl_configAuthSSH=${Vg_dirDockerImage}/config/authorized_keys
    Vl_configHostsSSH=${Vg_dirDockerImage}/config/known_hosts
    Vl_configHostsServeur=${Vg_dirDockerImage}/config/hosts
    Vl_configHadoopWorkers=${Vg_dirDockerImage}/config/workers
    
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
    
    echo `date '+%Y-%m-%d %H:%M:%S'`" - List of the node : `cat ${Vl_tmpListContainer}`"
    
    #get public ssh key from all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        echo `date '+%Y-%m-%d %H:%M:%S'`" - docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh \"get_ssh\""
        docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh "get_ssh"
        sleep 5
    done
    
    #set authorized_keys on all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        echo `date '+%Y-%m-%d %H:%M:%S'`" - docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh \"set_ssh\""
        docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh "set_ssh"
        sleep 1
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
        echo `date '+%Y-%m-%d %H:%M:%S'`" - docker exec -u hadoop -d ${Vg_nameMasterNode} /home/hadoop/manageDockerSSH.sh \"get_host\" \"${tmpNode},${Vl_tmpIP}\""
        
        #Ecriture du fichier "/etc/hosts" pour le root
        echo -e "${Vl_tmpIP}\t${tmpNode}" >> ${Vl_configHostsServeur}
        
        #Gestion des hosts ssh
        docker exec -u hadoop -d ${Vg_nameMasterNode} /home/hadoop/manageDockerSSH.sh "get_host" "${tmpNode},${Vl_tmpIP}"
        sleep 5
    done
    
    #set known_hosts on all nodes
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        echo `date '+%Y-%m-%d %H:%M:%S'`" - docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh \"set_host\""
        docker exec -u hadoop -d ${tmpNode} /home/hadoop/manageDockerSSH.sh "set_host"
        sleep 1
    done
    
    
    for tmpNode in `cat ${Vl_tmpListContainer}`
    do
        echo `date '+%Y-%m-%d %H:%M:%S'`" - docker exec -u root -d ${tmpNode} cp /config/hosts /etc/hosts"
        docker exec -u root -d ${tmpNode} cp /config/hosts /etc/hosts
        sleep 3
    done    
        
        
    #Define nodes (slave)
    cat ${Vg_configFileSlaves} > ${Vl_configHadoopWorkers}
    echo `date '+%Y-%m-%d %H:%M:%S'`" - docker exec -u hadoop -d ${Vg_nameMasterNode} cp /config/slaves /home/hadoop/hadoop/etc/hadoop/slaves"
    docker exec -u hadoop -d ${Vg_nameMasterNode} cp /config/workers /home/hadoop/hadoop/etc/hadoop/workers
    sleep 3
    
    
    
    #delete temporary files
    rm -f ${Vl_tmpListContainer}
    rm -f ${Vl_configAuthSSH}
    rm -f ${Vl_configHostsSSH}
    rm -f ${Vl_configHostsServeur}
    rm -f ${Vl_configHadoopWorkers}
    
    echo `date '+%Y-%m-%d %H:%M:%S'`" - End configCluster"
    
    return 0
}





function startCluster {
    #docker exec -u hadoop -d nodemaster hdfs namenode -format
    #docker exec -u hadoop -d nodemaster start-dfs.sh
    #sleep 5
    return 0
}


function stopCluster {

    return 0
}


function show_info {
  masterIp=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${Vg_nameMasterNode}`
  echo "Hadoop info @ nodemaster: http://$masterIp:8088/cluster"
  echo "DFS Health @ nodemaster : http://$masterIp:9870/dfshealth.html"
}


Vg_Param=$1
CR=0

echo 

echo `date '+%Y-%m-%d %H:%M:%S'`" - Start (param=${Vg_Param})"

if [ "${Vg_Param}" = "build" -a ${CR} -eq 0 ]
then 
    buildCluster
    CR=$?
fi


if [ "${Vg_Param}" = "deploy" -a ${CR} -eq 0 ]
then 
    deployCluster
    CR=$?
fi

if [ "${Vg_Param}" = "destroy" -a ${CR} -eq 0 ]
then 
    destroyCluster
    CR=$?
fi


if [ "${Vg_Param}" = "config" -a ${CR} -eq 0 ]
then 
    configCluster
    CR=$?
fi

if [ "${Vg_Param}" = "info" -a ${CR} -eq 0 ]
then 
    show_info
    CR=$?
fi


if [ ${CR} -eq 0 ]
then 
    echo `date '+%Y-%m-%d %H:%M:%S'`" - End [OK]"
else
    echo `date '+%Y-%m-%d %H:%M:%S'`" - End [KO]"
fi

exit ${CR}

