#!/bin/bash
# stop all pods
echo "stopping all running containers"
sudo podman stop --all
echo "deleting pod"
sudo podman pod rm zabbix-pod
echo "recreating pod"
sudo podman pod create --name zabbix-pod \
      -p 80:8080 \
      -p 10051:10051 \
      -p 162:1162/udp
sudo podman run --name zabbix-mysql-server -t \
      -e MYSQL_DATABASE="zabbix" \
      -e MYSQL_USER="zabbix" \
      -e MYSQL_PASSWORD="zabbix_pwd" \
      -e MYSQL_ROOT_PASSWORD="root_pwd" \
      -v /data/var/mysql/:/var/lib/mysql/:Z \
      --restart=no \
      --pod=zabbix-pod \
      --rm=True \
      -d docker.io/library/mysql:8.0 \
      --character-set-server=utf8 --collation-server=utf8_bin \
      --default-authentication-plugin=mysql_native_password
sudo podman run --name zabbix-snmptraps \
     -v /data/var/zabbix/snmptraps:/var/lib/zabbix/snmptraps:z \
     -v /data/var/zabbix/mibs:/var/lib/zabbix/mibs:z \
     --pod=zabbix-pod \
     --rm=True \
     -d docker.io/zabbix/zabbix-snmptraps:5.4-alpine-latest
sudo podman run --name zabbix-server-mysql -t \
     -e DB_SERVER_HOST="127.0.0.1" \
     -e MYSQL_DATABASE="zabbix" \
     -e MYSQL_USER="zabbix" \
     -e MYSQL_PASSWORD="zabbix_pwd" \
     -e MYSQL_ROOT_PASSWORD="root_pwd" \
     -e ZBX_ENABLE_SNMP_TRAPS=True \
     -v /data/var/zabbix/snmptraps:/var/lib/zabbix/snmptraps:z \
     --pod=zabbix-pod \
     --restart=no \
     --rm=True \
     -d docker.io/zabbix/zabbix-server-mysql:5.4-alpine-latest
echo "starting zabbix web interface..."
sudo podman run --name zabbix-web-nginx-mysql -t \
      -e ZBX_SERVER_HOST="zabbix-server-mysql" \
      -e ZBX_SERVER_NAME="ISVA Zabbix" \
      -e DB_SERVER_HOST="zabbix-mysql-server" \
      -e MYSQL_DATABASE="zabbix" \
      -e MYSQL_USER="zabbix" \
      -e MYSQL_PASSWORD="zabbix_pwd" \
      -e MYSQL_ROOT_PASSWORD="root_pwd" \
      --pod=zabbix-pod \
      --restart=no \
      --rm=True \
      -d docker.io/zabbix/zabbix-web-nginx-mysql:alpine-5.4-latest