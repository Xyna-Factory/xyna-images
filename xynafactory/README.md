# xynafactory

## Build dockerimage xynafactory
For building a xynafactory dockerimage you have to:
* Define the following ENV Variables
  * XYNADEV_IMAGE: the xynadev image to be used (Default: xynafactory/xynadev:latest)

* Execute the following command:

```
docker build --build-arg XYNADEV_IMAGE=${XYNADEV_IMAGE} -t factory:MYVERSION .
```
