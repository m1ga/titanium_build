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
echo -----  titanium_build  ------------------------------------------------
echo $TITANIUM_BUILD
echo

#############################################################################

GIT_BRANCH=$1
echo 'GIT_BRANCH:    ' $GIT_BRANCH

TARGET_BRANCH=titanium_mobile_$GIT_BRANCH
echo 'TARGET_BRANCH: ' $TARGET_BRANCH

GIT_REVISION=`git log --pretty=oneline -n 1 | sed 's/ .*//' | tr -d '\n' | tr -d '\r'`
echo 'GIT_REVISION: ' $GIT_REVISION

VERSION=`python $TITANIUM_BUILD/common/get_version.py | tr -d '\r'`
echo 'VERSION: ' $VERSION

TIMESTAMP=`date +'%Y%m%d%H%M%S'`
echo 'TIMESTAMP: ' $TIMESTAMP

VTAG=$VERSION.v$TIMESTAMP
echo 'VTAG: ' $VTAG

BASENAME=dist/mobilesdk-$VTAG
echo 'BASENAME: '$BASENAME

echo
echo -----  p-a-t-h  -------------------------------------------------------
echo
echo $PATH
echo
