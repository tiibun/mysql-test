#!/bin/bash

VERSIONS="5.6.22 5.6.21 5.6.20 5.6.19"
#VERSIONS="5.6.21"

SQL=$(cat <<-EOSQL
create table tab (
  id int primary key,
  tm timestamp not null default current_timestamp
);
-- insert into tab values (1, null);
-- select * from tab;
insert into tab (id) values (1);
select * from tab;
EOSQL
)

IMAGE_NAME=my-mysql
CONTAINER_PREFIX=mysql

create_image() {
  VER=$1

  sed -e "s/^ENV MYSQL_VERSION\s*$/ENV MYSQL_VERSION ${VER}/" Dockerfile.tmpl > Dockerfile

  docker build -t ${IMAGE_NAME}:${VER} .
}

insert_test() {
  VER=$1

  docker ps -a | grep -q ${CONTAINER_PREFIX}${VER} && docker rm -f ${CONTAINER_PREFIX}${VER} > /dev/null

  docker run --name ${CONTAINER_PREFIX}${VER} -e MYSQL_ROOT_PASSWORD=pass -e MYSQL_DATABASE=test -d ${IMAGE_NAME}:${VER}

  sleep 8

  COMMAND='echo "'$SQL'" | mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot -p"$MYSQL_ENV_MYSQL_ROOT_PASSWORD" $MYSQL_ENV_MYSQL_DATABASE'

  docker run --link ${CONTAINER_PREFIX}${VER}:mysql --rm ${IMAGE_NAME}:${VER} sh -c "$COMMAND"
}

for v in ${VERSIONS}; do
  echo $v
  create_image $v
done
for v in ${VERSIONS}; do
  echo $v
  insert_test $v
done
