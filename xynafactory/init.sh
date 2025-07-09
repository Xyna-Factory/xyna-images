#!/bin/bash

if [ "$SYNC_CONTAINER_LIFECYCLE_TO_FACTORY" = true ]
then
    /k8s/xyna/factory.sh
else
    sleep infinity
fi
