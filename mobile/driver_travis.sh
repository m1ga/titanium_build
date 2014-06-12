#!/bin/sh

# A hudson build driver for Titanium Mobile 

SLAVE_PACKAGE='slave_package.zip'

export PATH=/bin:/usr/bin:$PATH

#############################################################################

# ANDROID_SDK=/usr/local/lib/android-sdk-linux
# export ANDROID_SDK
# 
# ANDROID_NDK=/usr/local/lib/android-ndk-r8
# export ANDROID_NDK
# 
# # JAVA_HOME=/usr/local/bin/jdk1.6.0_32
# JAVA_HOME=/jdk1.6
# export JAVA_HOME
# 
# TITANIUM_BUILD=/var/lib/jenkins/Source/titanium_build
# export TITANIUM_BUILD

echo
echo 'TITANIUM_BUILD: ' $TITANIUM_BUILD
echo

#############################################################################

GIT_BRANCH=$1
echo 'GIT_BRANCH:      ' $GIT_BRANCH

TARGET_BRANCH=titanium_mobile_$GIT_BRANCH
echo 'TARGET_BRANCH:   ' $TARGET_BRANCH

GIT_REVISION=`git log --pretty=oneline -n 1 | sed 's/ .*//' | tr -d '\n' | tr -d '\r'`
echo 'GIT_REVISION:    ' $GIT_REVISION

VERSION=`python $TITANIUM_BUILD/common/get_version.py | tr -d '\r'`
echo 'VERSION:         ' $VERSION

TIMESTAMP=`date +'%Y%m%d%H%M%S'`
echo 'TIMESTAMP:       ' $TIMESTAMP

VTAG=$VERSION.v$TIMESTAMP
echo 'VTAG:            ' $VTAG

BASENAME=dist/mobilesdk-$VTAG
echo 'BASENAME:        ' $BASENAME

echo 'PATH:            ' $PATH

echo 'ANDROID_SDK:     ' $ANDROID_SDK
echo 'ANDROID_NDK:     ' $ANDROID_NDK
echo 'PATH:            ' $PATH
echo 'JAVA_HOME:       ' $JAVA_HOME
echo 'ANDROID_PLATFORM:' $ANDROID_PLATFORM
echo 'GOOGLE_APIS:     ' $GOOGLE_APIS

echo 'NODE_APPC_BRANCH: $GIT_BRANCH'
scons package_all=1 node-appc-branch=$GIT_BRANCH version_tag=$VTAG $TI_MOBILE_SCONS_ARGS


if [ "$PYTHON" = "" ]; then
	PYTHON=python
fi

echo
echo 'TI_MOBILE_SCONS_ARGS: ' $TI_MOBILE_SCONS_ARGS
echo
echo 'BUILD_URL: ' $BUILD_URL

# echo 'Full Basename--->'
# e.g.,  dist/mobilesdk-2.1.0.v20120518163317-osx.zip

echo
SDK_ARCHIVE="$BASENAME-osx.zip"
echo 'SDK_ARCHIVE: ' $SDK_ARCHIVE

echo
echo 'Listing Work-Space---->'
echo
pwd
echo

ls -latr dist | tail -20

