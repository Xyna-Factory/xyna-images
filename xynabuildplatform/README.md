# xynabuildplatform

## Build dockerimage
For building a xynabuildplatform dockerimage you have to:
* Define the following ENV Variables
  * JAVA_VERSION: The used java version (For example 11)
  * OS_IMAGE: the os image to be used (Default: ubuntu:24.04)
  * XYNA_BUILDPLATFORM_IMAGE: the created xynabuildplatform image (For example: xynabuildplatform:myversion)

* Execute the following command:

```
./build.sh -j ${JAVA_VERSION} -o ${OS_IMAGE} -x ${XYNA_BUILDPLATFORM_IMAGE}
```
