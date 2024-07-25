#!/bin/bash

DB_IPADDRESS=mariadb:3306 
SIZE=100 
DB_USER=xyna 
DB_PASSWORD=xyna_db_pwd 
CONNECT_STRING="jdbc:mariadb://${DB_IPADDRESS}/xyna" 
./xynafactory.sh start
if /opt/xyna/xyna_001/server/xynafactory.sh addconnectionpool -connectstring ${CONNECT_STRING} -name Xyna-Infra-Pool -size ${SIZE} -type MySQL -user ${DB_USER} -password ${DB_PASSWORD} ; then 
    /opt/xyna/xyna_001/server/xynafactory.sh instantiatepersistencelayer -persistenceLayerName mysql -department xyna -connectionType DEFAULT -persistenceLayerInstanceName Xyna-Infra-Default-Inst -persistenceLayerSpecifics Xyna-Infra-Pool 4000 
    /opt/xyna/xyna_001/server/xynafactory.sh instantiatepersistencelayer -persistenceLayerName mysql -department xyna -connectionType HISTORY -persistenceLayerInstanceName Xyna-Infra-History-Inst -persistenceLayerSpecifics Xyna-Infra-Pool 4000 
    /opt/xyna/xyna_001/server/xynafactory.sh registertable -c -persistenceLayerInstanceName Xyna-Infra-History-Inst -tableName orderinfo 
    /opt/xyna/xyna_001/server/xynafactory.sh registertable -c -persistenceLayerInstanceName Xyna-Infra-History-Inst -tableName orderarchive 
    /opt/xyna/xyna_001/server/xynafactory.sh set xnwh.persistence.xmom.defaultpersistencelayerid $(/opt/xyna/xyna_001/server/xynafactory.sh listpersistencelayerinstances | grep Xyna-Infra-Default-Inst | awk '{ print $2 }') 
    /opt/xyna/xyna_001/server/xynafactory.sh set xnwh.persistence.xmom.defaulthistorypersistencelayerid $(/opt/xyna/xyna_001/server/xynafactory.sh listpersistencelayerinstances | grep Xyna-Infra-History-Inst | awk '{ print $2 }')
    ./xynafactory.sh stop 
    /k8s/xyna/factory.sh
else
    /k8s/xyna/factory.sh
fi

