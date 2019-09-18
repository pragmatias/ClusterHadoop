FROM centos:7

MAINTAINER pragmatias

#Configuration du proxy
ENV http_proxy http://usr:pwd@ip:port
ENV https_proxy http://usr:pwd@ip:port

#Configuration package hadoop
ENV HADOOP_PKG hadoop-3.2.0
ENV SCALA_PKG scala-2.13.0
ENV SPARK_PKG spark-2.4.3-bin-without-hadoop
ENV ZEPLN_PKG zeppelin-0.8.1-bin-netinst
#ENV ZEPLN_PKG zeppelin-0.8.1-bin-all


#Configuration des variables d'environnement
ENV JAVA_HOME /usr/lib/jvm/java/jre

#Root user
USER root
WORKDIR /tmp

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


#Install Scala
COPY --chown=root package/${SCALA_PKG}.tgz /tmp/
RUN cd /tmp \
    && tar -xzf ${SCALA_PKG}.tgz \
    && mv ${SCALA_PKG} /usr/share/scala \
    && ln -s /usr/share/scala/bin/* /usr/bin \
    && rm ${SCALA_PKG}.tgz



#Configuration du user HADOOP
RUN groupadd hadoop \
    && useradd -ms /bin/bash hadoop -g hadoop -G wheel,users


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

#Installation Spark
COPY --chown=hadoop package/${SPARK_PKG}.tgz /home/hadoop/
RUN tar -xzf ${SPARK_PKG}.tgz \
    && mv ${SPARK_PKG} spark \
    && rm ${SPARK_PKG}.tgz

#Installation Zeppelin
COPY --chown=hadoop package/${ZEPLN_PKG}.tgz /home/hadoop/
RUN tar -xzf ${ZEPLN_PKG}.tgz \
    && mv ${ZEPLN_PKG} zeppelin \
    && rm ${ZEPLN_PKG}.tgz

#Creation repertoire necessaire hadoop
RUN mkdir -p /home/hadoop/hadoop/logs \
             /home/hadoop/data/nameNode \
             /home/hadoop/data/dataNode \
             /home/hadoop/data/namesecondary \
             /home/hadoop/data/tmp \
    && touch /home/hadoop/hadoop/logs/fairscheduler-statedump.log

#Creation repertoire necessaire zeppelin
RUN mkdir -p /home/hadoop/data/notebook

#Gestion de l'environnement
RUN echo "export PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:/home/hadoop/spark/bin:/home/hadoop/spark/sbin:\$PATH" >> /home/hadoop/.profile
RUN echo "export PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:/home/hadoop/spark/bin:/home/hadoop/spark/sbin:\$PATH" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_HOME=/home/hadoop/hadoop" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_HOME=/home/hadoop/hadoop" >> /home/hadoop/.profile
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.profile
RUN echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /home/hadoop/.bashrc
RUN echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /home/hadoop/.profile
RUN echo "export SPARK_HOME=/home/hadoop/spark" >> /home/hadoop/.profile
RUN echo "export SPARK_HOME=/home/hadoop/spark" >> /home/hadoop/.bashrc
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /home/hadoop/.profile
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /home/hadoop/.bashrc


RUN echo JAVA_HOME=${JAVA_HOME} >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_NAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_DATANODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_SECONDARYNAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh

#Install Zeppelin interperter (optional)
#RUN /home/hadoop/zeppelin/bin/install-interpreter.sh --name md --proxy-url <url> --proxy-user <usr> --proxy-password <pwd>

#Copie des fichiers de configuration hadoop
COPY --chown=hadoop config/hadoop/core-site.xml config/hadoop/hdfs-site.xml config/hadoop/mapred-site.xml config/hadoop/yarn-site.xml /home/hadoop/hadoop/etc/hadoop/

#Copie des fichiers de configuration pour Spark
COPY --chown=hadoop config/hadoop/spark-defaults.conf /home/hadoop/spark/conf/

#Copie des fichiers de configurations pour Zeppelin
COPY --chown=hadoop config/zeppelin/zeppelin-site.xml config/zeppelin/interpreter.json /home/hadoop/zeppelin/conf/

#Root
USER root

#Exposition de port
#SSH
EXPOSE 22
#Http
EXPOSE 80 8080 
#Zeppelin
EXPOSE 8081 8443
#NameNode UI (& secondary namenode)
EXPOSE 9870 9871 9868 9869
#Resource Manager UI (yarn)
EXPOSE 8088 8042
#Datanode UI
EXPOSE 9864 9865 9866 9867 9000
#Spark
EXPOSE 7077 18080

#Execution du service SSH 
CMD ["/usr/sbin/sshd", "-D"]



