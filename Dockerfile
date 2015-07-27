FROM centos:6

# Install dependencies
RUN yum -y update
RUN yum -y install bridge-utils wget dnsmasq build-essential tar sudo

# Install appropriate JDK
RUN yum -y install java-1.7.0-openjdk.x86_64


# Zookeeper
RUN wget -q -O - http://www.us.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz | tar -xzf - -C /usr/local \
      && cp /usr/local/zookeeper-3.4.6/conf/zoo_sample.cfg /usr/local/zookeeper-3.4.6/conf/zoo.cfg \
      && ln -s /usr/local/zookeeper-3.4.6 /usr/local/zookeeper


# Kafka
ENV SCALA_VERSION 2.10
ENV KAFKA_VERSION 0.8.2.1

RUN wget -q -O - http://mirror.cc.columbia.edu/pub/software/apache/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz | tar -xzf - -C /usr/local \
      && ln -s /usr/local/kafka_$SCALA_VERSION-$KAFKA_VERSION /usr/local/kafka


# Druid system user
RUN adduser druid \
      && mkdir -p /var/lib/druid \
      && chown druid:druid /var/lib/druid


# Druid (release tarball)
ENV DRUID_VERSION 0.8.0
RUN wget -q -O - http://static.druid.io/artifacts/releases/druid-$DRUID_VERSION-bin.tar.gz | tar -xzf - -C /usr/local
RUN ln -s /usr/local/druid-$DRUID_VERSION /usr/local/druid      


# MySQL
RUN rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
RUN yum -y install mysql-server
RUN service mysqld start && mysql -u root -e "GRANT ALL ON druid.* TO 'druid'@'localhost' IDENTIFIED BY 'diurd'; CREATE database druid CHARACTER SET utf8;" && service mysqld stop

# Initialize metadata
RUN service mysqld start && java -classpath '/usr/local/druid/lib/*' -Ddruid.extensions.localRepository=/usr/local/druid/repository -Ddruid.extensions.coordinates=[\"io.druid.extensions:mysql-metadata-storage\"] -Ddruid.metadata.storage.type=mysql io.druid.cli.Main tools metadata-init --connectURI="jdbc:mysql://localhost:3306/druid" --user=druid --password=diurd && service mysqld stop

# Setup supervisord
RUN yum -y install python-setuptools
RUN easy_install pip
#Workaround for a broken pip supervisor dependency
RUN pip install 'meld3 == 1.0.1'
RUN pip install supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Clean up
RUN yum clean all && rm -rf /tmp/* /var/tmp/*
RUN chown -R druid:druid /usr/local/druid/repository

# Expose ports:
# - 8081: HTTP (coordinator)
# - 8082: HTTP (broker)
# - 8083: HTTP (historical)
# - 3306: MySQL
# - 2181 2888 3888: ZooKeeper
EXPOSE 8081
EXPOSE 8082
EXPOSE 8083
EXPOSE 3306
EXPOSE 2181 2888 3888
WORKDIR /var/lib/druid
ENTRYPOINT export HOSTIP="$(resolveip -s $HOSTNAME)" && exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
