# xynamodeller

## Build dockerimage
For building a xynamodeller dockerimage you have to:
* Define the following ENV Variables
  * IMAGE: Name and Tag of the build image. (for example: xynamodeller:1.0)
* Copy file modeller.war to the xynamodeller directory. (modeller.war can be build see: https://github.com/Xyna-Factory/xyna-factory/blob/main/installation/Readme.md)
* Execute the following command:

```
docker build --build-arg -t ${IMAGE} .
```

## Run container
For running a xynamodeller container have to:
* Define the following ENV Variables
  * IMAGE: Name and Tag of the build image. (for example: xynamodeller:1.0)
  * NAME: Name of the running container. (for example:: myxynamodeller)
  * XYNA_HOSTNAME: Hostname of the xyna-factoy (Default: xyna)
  * MODELLER_PORT: http port on which the xynamodeller can be reached (Default: 8000)
* Execute the following command:

```
docker run -dit --name ${NAME} -p ${MODELLER_PORT}:${MODELLER_PORT} -e XYNA_HOSTNAME=${XYNA_HOSTNAME} -e MODELLER_PORT=${MODELLER_PORT} ${IMAGE}
```
