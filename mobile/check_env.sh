#!/bin/sh

# A hudson build driver for Titanium Mobile 

export PATH=/bin:/usr/bin:$PATH

GIT_BRANCH=$1
GIT_REVISION=`git log --pretty=oneline -n 1 | sed 's/ .*//' | tr -d '\n' | tr -d '\r'`
echo 'GIT_REVISION: ' $GIT_REVISION
echo

echo 'TITANIUM_BUILD: ' $TITANIUM_BUILD
echo

########    VERSION=`python $TITANIUM_BUILD/common/get_version.py | tr -d '\r'`
VERSION=`python ../common/get_version.py | tr -d '\r'`
echo

echo 'VERSION: ' $VERSION
TIMESTAMP=`date +'%Y%m%d%H%M%S'`
echo 'TIMESTAMP: ' $TIMESTAMP

VTAG=$VERSION.v$TIMESTAMP
BASENAME=dist/mobilesdk-$VTAG
echo 'BASENAME: '$BASENAME

##########    scons package_all=1 version_tag=$VTAG $TI_MOBILE_SCONS_ARGS
echo
echo 'TI_MOBILE_SCONS_ARGS: ' $TI_MOBILE_SCONS_ARGS
echo
echo 'BUILD_URL: ' $BUILD_URL

echo
echo 'Full Basename--->'
# e.g.,  dist/mobilesdk-2.1.0.v20120518163317-osx.zip

SDK_ARCHIVE="$BASENAME-osx.zip"
echo $SDK_ARCHIVE
echo

cd /var/lib/jenkins/jobs/titanium_mobile_master/workspace
pwd
ls -la $SDK_ARCHIVE

if [ -e "$SDK_ARCHIVE" ]
then
	echo "$SDK_ARCHIVE - does Exist."
else
	echo "Missing SDK zip file"
	exit 1
fi

if [ -e "tmp_unbundle" ]
then
	echo "DIR tmp_unbundle exists."
fi

