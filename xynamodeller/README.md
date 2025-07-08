# xynamodeller

## Build dockerimage
For building a xynamodeller dockerimage you have to:
* Copy file modeller.war to the xynamodeller directory.
* Execute the following command:

```
docker build --build-arg -t xynamodeller:MYVERSION .
```

## Run container
For running a xynamodeller container have to:
* Define the following ENV Variables
  * XYNA_HOSTNAME: Hostname of the xyna-factoy (Default: xyna)
  * MODELLER_PORT: http port on which the xynamodeller can be reached (Default: 8000)
  * APACHE_LOG_DIR: Directory where apache write log files (Default: var/log/apache2)
  * APACHE_SERVER_NAME: ServerName of the Apache(Default: xyna)
* Execute the following command:

```
docker run -dit --name MYNAME -p ${MODELLER_PORT}:${MODELLER_PORT} -e XYNA_HOSTNAME=${XYNA_HOSTNAME} -e MODELLER_PORT=${MODELLER_PORT} -e APACHE_LOG_DIR=${APACHE_LOG_DIR} -e APACHE_SERVER_NAME=${APACHE_SERVER_NAME} --entrypoint "/usr/sbin/apachectl" xynamodeller:MYVERSION -D FOREGROUND
```
