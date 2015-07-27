# Docker druid container thats based on CentOS 6

## Setup Docker
[Install Docker] [https://github.com/druid-io/docker-druid/blob/master/docker-install.md]

## Build Druid Docker Image

```sh
git clone git@github.com:alexrovner/docker-druid.git
docker build -t druid/cluster-centos6 docker-druid
```

## Run a simple Druid cluster
```sh
docker run --rm -i -p 8082:8082 -p 8081:8081 -p 8084:8084 druid/cluster-centos6
```

Wait a minute or so for the Druid to download the sample data an start up.

## Check if things work

### on OS X

Assuming `boot2docker ip` returns `192.168.59.103`, you should be able to
   - access the coordinator console http://192.168.59.103:8001/
   - list data-sources on the broker http://192.168.59.103:8082/druid/v2/datasources

### On Linux

   - access the coordinator console http://localhost:8001/
   - list data-sources on the broker http://localhost:8082/druid/v2/datasources


