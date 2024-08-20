# xyna-images

### xynabase
For building a Xyna dockerimage you have to:
* Copy Xyna delivery item next to Dockerfile and build.sh lying in /xynabase.
* Running build.sh with first argument beeing the Xyna version.

### xynaprod
* After building a base image, one can build production image.
* Therefor run docker build in xynaprod folder with argument --build-arg XYNABASE_IMAGE=xynabase:\<Tag\>.

### xynadev
* In xyna-factory/installation/ call "./build.sh build"
* Build GitIntegation-application by running ant build in xyna-factory/xyna-factory/modules/xmcp/gitintegration and copy result into /xynadev
* Run docker build in xynadev folder with argument --build-arg XYNABASE_IMAGE=xynabase:\<Tag\>.
