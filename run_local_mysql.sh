#!/bin/sh

PWD=`pwd`

. ./db.conf

# test if mysql is already running
if test ! -S $MYSQL_SOCKET ; then

   if test ! -d $PWD/mysql.db ; then
      mysql_install_db --user=`whoami` --ldata=$PWD/mysql.db --force
   fi

   /usr/sbin/mysqld --datadir $PWD/mysql.db --socket $PWD/mysqld.sock --pid-file $PWD/mysqld.pid --skip-networking >mysqld.log 2>&1 &

   echo "started mysqld, pid $!"

   if test ! -d $PWD/lol ; then
      sleep 3
      echo "creating tables"
      mysql -uroot -S$MYSQL_SOCKET < ./list_of_lights.sql
   fi

else
   mysqlpid=`cat $PWD/mysqld.pid`
   echo "myql is already running, pid $mysqlpid"
fi

