FROM alpine:3.9

MAINTAINER pragmatias

#Configuration du proxy
#ENV http_proxy http://usr:pwd@192.168.77.12:8080
#ENV https_proxy http://usr:pwd@192.168.77.12:8080


#Variable environnement
ENV hadoop_pkg hadoop-3.2.0
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH ${JAVA_HOME}/bin:${PATH}

#Root configuration
USER root

#Installation des packages
RUN apk --update add --no-cache openjdk8-jre \
                                openssh \
                                nss \
                                curl wget openssl \
                                bash \
    && rm -rf /var/cache/apk/*


#Configuration du serveur SSH
RUN sed -i 's@#Port 22@Port 22@g' /etc/ssh/sshd_config \
    && sed -i 's@#HostKey /etc/ssh/ssh_host_key@HostKey /etc/ssh/ssh_host_key@g' /etc/ssh/sshd_config \
    && sed -i 's@#HostKey /etc/ssh/ssh_host_rsa_key@HostKey /etc/ssh/ssh_host_rsa_key@g' /etc/ssh/sshd_config \
    && sed -i 's@#HostKey /etc/ssh/ssh_host_dsa_key@HostKey /etc/ssh/ssh_host_dsa_key@g' /etc/ssh/sshd_config \
    && sed -i 's@#HostKey /etc/ssh/ssh_host_ecdsa_key@HostKey /etc/ssh/ssh_host_ecdsa_key@g' /etc/ssh/sshd_config \
    && sed -i 's@#HostKey /etc/ssh/ssh_host_ed25519_key@HostKey /etc/ssh/ssh_host_ed25519_key@g' /etc/ssh/sshd_config \
    && sed -i 's@#PasswordAuthentication yes@PasswordAuthentication no@g' /etc/ssh/sshd_config

#Configuration de la partie SSH
RUN /usr/bin/ssh-keygen -A
RUN ssh-keygen -b 4096 -t rsa -f /etc/ssh/ssh_host_key


#Configuration du user HADOOP
RUN addgroup hadoop \
    && adduser -D -s /bin/bash hadoop -G hadoop \
    && adduser hadoop wheel \
    && adduser hadoop users

USER hadoop
WORKDIR /home/hadoop

#configuration ssh pour hadoop
RUN mkdir /home/hadoop/.ssh
# \
#    && echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config \
#    && echo PasswordAuthentication no >> /home/hadoop/.ssh/config

#Installation de hadoop
COPY --chown=hadoop package/${hadoop_pkg}.tar.gz /home/hadoop/
RUN tar -xzf ${hadoop_pkg}.tar.gz \
    && mv ${hadoop_pkg} hadoop \
    && rm ${hadoop_pkg}.tar.gz

#Creation repertoire necessaire hadoop
RUN mkdir -p /home/hadoop/hadoop/logs /home/hadoop/data/nameNode /home/hadoop/data/dataNode /home/hadoop/data/namesecondary /home/hadoop/data/tmp \
    && touch /home/hadoop/hadoop/logs/fairscheduler-statedump.log


#Gestion de l'environnement
RUN echo "export PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:${JAVA_HOME}/bin:\$PATH" >> /home/hadoop/.profile \
    && echo "PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:${JAVA_HOME}/bin:\$PATH" >> /home/hadoop/.bashrc \
    && echo "export HADOOP_HOME=/home/hadoop/hadoop" >> /home/hadoop/.bashrc \
    && echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.bashrc \
    && echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.profile \
    && echo "export JAVA_HOME=${JAVA_HOME}/jre" >> /home/hadoop/.profile \
    && echo "export JAVA_HOME=${JAVA_HOME}/jre" >> /home/hadoop/.bashrc \
    && echo JAVA_HOME=${JAVA_HOME}/jre >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh \
    && echo HDFS_NAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh \
    && echo HDFS_DATANODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh \
    && echo HDFS_SECONDARYNAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh


#Copie des fichiers de configuration
COPY --chown=hadoop config/hadoop/core-site.xml config/hadoop/hdfs-site.xml config/hadoop/mapred-site.xml config/hadoop/yarn-site.xml /home/hadoop/hadoop/etc/hadoop/


#COPY --chown=hadoop config/manageDockerSSH.sh /home/hadoop/manageDockerSSH.sh
#RUN chmod +x /home/hadoop/manageDockerSSH.sh

#User par defaut
USER root

#Manage the ssh connection with locked user (alpine)
RUN sed -i 's@hadoop:!@hadoop:*@g' /etc/shadow


#Exposition des ports
EXPOSE 22
EXPOSE 80
EXPOSE 7077
EXPOSE 8042
EXPOSE 8081
EXPOSE 8080
EXPOSE 8088
EXPOSE 9000
EXPOSE 9001
EXPOSE 9864
EXPOSE 9866
EXPOSE 9870

#Execution du service SSH¤
CMD ["/usr/sbin/sshd", "-D", "-e"]



