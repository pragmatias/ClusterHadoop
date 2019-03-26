FROM centos:7

MAINTAINER pragmatias

#Configuration du proxy
#ENV http_proxy http://usr:pwd@192.168.77.12:8080
#ENV https_proxy http:/usr:pwd@192.168.77.12:8080

#Configuration package hadoop
ENV HADOOP_PKG hadoop-3.2.0

#Configuration des variables d'environnement
ENV JAVA_HOME /usr/lib/jvm/java/jre

#Root user
USER root

#Install (update)
RUN yum -y update \
    && yum clean all

#Install (packages)
RUN yum -y install \
        java-1.8.0-openjdk-devel \
        openssh-server \
        openssh-clients \
        && yum clean all

#Generation de la cle SSH (root/RSA)
RUN echo 'Y' | ssh-keygen -b 4096 -t rsa -N '' -f /root/.ssh/id_rsa

#Configuration du serveur SSH
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config \
    && echo "Host *" >> /etc/ssh/ssh_config \
    && sed -i 's@HostKey /etc/ssh/ssh_host_dsa_key@#HostKey /etc/ssh/ssh_host_dsa_key@' /etc/ssh/sshd_config \
    && sed -i 's@HostKey /etc/ssh/ssh_host_ecdsa_key@#HostKey /etc/ssh/ssh_host_ecdsa_key@' /etc/ssh/sshd_config \
    && sed -i 's@HostKey /etc/ssh/ssh_host_ed25519_key@#HostKey /etc/ssh/ssh_host_ed25519_key@' /etc/ssh/sshd_config \
    && sed -i 's@PasswordAuthentication yes@PasswordAuthentication no@' /etc/ssh/sshd_config
#Mise en place des cle RSA
RUN cp /root/.ssh/id_rsa.pub /etc/ssh/ssh_host_rsa_key.pub \
    && cp /root/.ssh/id_rsa /etc/ssh/ssh_host_rsa_key



#Configuration du user HADOOP
RUN groupadd hadoop \
    && useradd -ms /bin/bash hadoop -g hadoop -G wheel,users 
#    && echo 'hadoop:hadoop' | chpasswd 


USER hadoop
WORKDIR /home/hadoop


#Configuration ssh pour hadoop
RUN mkdir /home/hadoop/.ssh \
    && echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config \
    && echo PasswordAuthentication no >> /home/hadoop/.ssh/config


#Installation de hadoop
COPY --chown=hadoop package/${HADOOP_PKG}.tar.gz /home/hadoop/
RUN tar -xzf ${HADOOP_PKG}.tar.gz \
    && mv ${HADOOP_PKG} hadoop \
    && rm ${HADOOP_PKG}.tar.gz

#Creation repertoire necessaire hadoop
RUN mkdir -p /home/hadoop/hadoop/logs \
             /home/hadoop/data/nameNode \
             /home/hadoop/data/dataNode \
             /home/hadoop/data/namesecondary \
             /home/hadoop/data/tmp \
    && touch /home/hadoop/hadoop/logs/fairscheduler-statedump.log


#Gestion de l'environnement
RUN echo "export PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:\$PATH" >> /home/hadoop/.profile
RUN echo "PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:\$PATH" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_HOME=/home/hadoop/hadoop" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.profile

RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /home/hadoop/.profile
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /home/hadoop/.bashrc


RUN echo JAVA_HOME=${JAVA_HOME} >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_NAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_DATANODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_SECONDARYNAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh


#Copie des fichiers de configuration
COPY --chown=hadoop config/hadoop/core-site.xml config/hadoop/hdfs-site.xml config/hadoop/mapred-site.xml config/hadoop/yarn-site.xml /home/hadoop/hadoop/etc/hadoop/


#Root
USER root

#Exposition de port
#SSH
EXPOSE 22
#HTTP
EXPOSE 80
#NameNode UI (& secondary namenode)
EXPOSE 9870 9871 9868 9869
#Resource Manager UI (yarn)
EXPOSE 8088 8042
#Datanode UI
EXPOSE 9864 9865 9866 9867 9000


#Execution du service SSH 
CMD ["/usr/sbin/sshd", "-D"]



