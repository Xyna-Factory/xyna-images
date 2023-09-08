# xyna-images

### xynabase
For building a Xyna dockerimage you have to:
* Copy Xyna delivery item next to Dockerfile and build.sh lying in /xynabase.
* Running build.sh with first argument beeing the Xyna version.

### xynaprod
* After building a base image, one can build production image.
* Therefor run docker build in xynaprod folder with argument --build-arg XYNABASE_IMAGE=xynabase:\<Tag\>.
