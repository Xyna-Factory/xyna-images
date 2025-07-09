# xynabase

## Build dockerimage
For building a xynabase dockerimage you have to:
* Copy file XynaBundle*.zip to the xynamodeller directory. (XynaBundle*.zip can be build see: https://github.com/Xyna-Factory/xyna-factory/blob/main/installation/Readme.md)
* Define the following ENV Variables
  * JAVA_VERSION: The used java version (For example 11)
  * OS_IMAGE: the os image to be used (Default: ubuntu:24.04)
  * XYNA_IMAGE: the created xynabase image (For example: xynabase:myversion)

* Execute the following command:

```
./build.sh -j ${JAVA_VERSION} -o ${OS_IMAGE} -x ${XYNA_IMAGE}
```
