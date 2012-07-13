#!/bin/sh

# A hudson build driver for Titanium Mobile Modules
source $HOME/.profile

export BASE_DIR=$HOME

export TITANIUM_BUILD=$BASE_DIR/build/titanium_build
export TITANIUM_SDK="$HOME/Library/Application Support/Titanium"

# useful for sedding
TMP=`echo $TITANIUM_SDK|sed "s/\//\\\\\\\\\//g"`
ESCAPED_TITANIUM_SDK=`echo $TMP|sed "s/\ /\\\\\\\\\\\\\\\\\ /g"`

#for debug only
#export WORKSPACE=$BASE_DIR/build/workspace/titanium_mobile_modules

cd $WORKSPACE

GIT_BRANCH=$1
GIT_REVISION=`git log --pretty=oneline -n 1 | sed 's/ .*//' | tr -d '\n' | tr -d '\r'`
PLATFORM=`python -c "import platform; print ({'Darwin':'osx','Windows':'win32','Linux':'linux'})[platform.system()]" | tr -d '\r' | tr -d '\n'`
TIMESTAMP=`date +'%Y%m%d%H%M%S'`

if [ "$PYTHON" = "" ]; then
	PYTHON=python
fi

# iOS modules

BUILD_IOS=true

if [ "$BUILD_IOS" = "true" ]; then
for MODULE in `ls $WORKSPACE/iphone`; do
	cd $WORKSPACE/iphone/$MODULE
	echo "building $MODULE (iOS)..."

        BUILD_CONFIG=$WORKSPACE/iphone/$MODULE/titanium.xcconfig
	MSDK_VERSION=`grep -m1 TITANIUM_SDK_VERSION\ *= $BUILD_CONFIG | cut -d= -f2| tr -d ' '`

	if [ ! -d "$TITANIUM_SDK/mobilesdk/osx/$MSDK_VERSION" ]; then
		echo "ERROR: Required Titanium Mobile SDK $MSDK_VERSION not found."
		continue;
	fi

	sed -i \
		-e "s/TITANIUM_SDK\ *=\ *.*/TITANIUM_SDK\ =\ $ESCAPED_TITANIUM_SDK\/mobilesdk\/osx\/\$\(TITANIUM_SDK_VERSION\)/" \
	$BUILD_CONFIG

	./build.py  >& build.log
	grep 'BUILD SUCCEEDED'  build.log | uniq
	grep -q 'BUILD SUCCEEDED' build.log || cat build.log
	# check if zip was updated
	ZIP=`ls *\.zip`
	if [ -z "$ZIP" ]; then continue; fi
	STAMPED_ZIP=`echo $ZIP| sed "s/\(.*\).zip/\1-$TIMESTAMP.zip/"`
	mv $ZIP $STAMPED_ZIP
	$PYTHON $TITANIUM_BUILD/common/s3_uploader.py modules $STAMPED_ZIP $GIT_BRANCH $GIT_REVISION $BUILD_URL
	rm $STAMPED_ZIP
	echo
done
fi


# Android modules

export ANDROID_SDK=$BASE_DIR/android-sdk
export ANDROID_NDK=$BASE_DIR/android-ndk-r8

BUILD_ANDROID=true

if [ "$BUILD_ANDROID" = "true" ]; then
for MODULE in `ls $WORKSPACE/android`; do
#	skip build.xml
	if [ "$MODULE" = "build.xml" ]; then continue; fi
#	for debugging of particular module
#	if [ "$MODULE" != "urbanAirship" ]; then continue; fi

	MSDK_VERSION=`grep titanium.version= $WORKSPACE/android/$MODULE/build.properties.example|cut -d= -f2`
	MODULE_DIR=$WORKSPACE/android/$MODULE

	for BRANCH in `s3cmd ls s3://builds.appcelerator.com/mobile/| grep DIR| awk '{print $2}'`; do
		SDK_BUCKET=`s3cmd ls $BRANCH | grep "\-$MSDK_VERSION" | grep $PLATFORM | tail -n1 | awk '{print $4}'`;
		if [ -n "$SDK_BUCKET" ]; then break; fi
	done
	if echo $SDK_BUCKET| grep -q master; then
		SDK=`echo $SDK_BUCKET| cut -d/ -f6`
		MSDK_VERSION_STAMP=`echo $SDK_BUCKET| cut -d- -f2`

		if [ ! -d  $TITANIUM_SDK/mobilesdk/osx/$MSDK_VERSION_STAMP ]; then
			rm -rf $TITANIUM_SDK/mobilesdk/osx/$MSDK_VERSION*
			s3cmd get --force $SDK_BUCKET && tar xzf $SDK -C ~/Titanium/
			rm $SDK
		fi	
		MSDK_VERSION=$MSDK_VERSION_STAMP
	fi

	if [ ! -d "$TITANIUM_SDK/mobilesdk/osx/$MSDK_VERSION" ]; then
		echo "ERROR: Required Titanium Mobile SDK $MSDK_VERSION not found."
		continue;
	fi

	sed s/TITANIUM_VERSION/$MSDK_VERSION/ $TITANIUM_BUILD/modules/build.properties.template > $MODULE_DIR/build.properties

	TMP=`echo $TITANIUM_SDK|sed "s/\//\\\\\\\\\//g"`
	ESCAPED_TITANIUM_SDK=`echo $TMP|sed "s/\ /\\\\\\\\\\\\\\\\\ /g"`
	sed -i -e "s/TITANIUM_SDK/$ESCAPED_TITANIUM_SDK/" $MODULE_DIR/build.properties

	if [ -f $MODULE_DIR/build.properties.example ]; then
		grep -s android.platform $MODULE_DIR/build.properties.example >> $MODULE_DIR/build.properties
		grep -s google.apis $MODULE_DIR/build.properties.example >> $MODULE_DIR/build.properties
	else
		grep default $TITANIUM_BUILD/modules/build.properties.template| sed s/default\.// >> $MODULE_DIR/build.properties
	fi

	cd $WORKSPACE/android/$MODULE
        if [ ! -d lib ]; then mkdir lib; fi
	echo "building $MODULE (Android)..."

	ant -v clean dist >& ant.log
	grep 'BUILD SUCCESSFUL' ant.log || cat ant.log

	ZIP=`ls dist/*\.zip`
	if [ -z "$ZIP" ]; then continue; fi
	STAMPED_ZIP=`echo $ZIP| sed "s/\/\(.*\).zip/\/\1-$TIMESTAMP.zip/"`
	mv $ZIP $STAMPED_ZIP
	$PYTHON $TITANIUM_BUILD/common/s3_uploader.py modules $STAMPED_ZIP $GIT_BRANCH $GIT_REVISION $BUILD_URL
	rm $STAMPED_ZIP
	echo
done
fi

$PYTHON $TITANIUM_BUILD/common/s3_cleaner.py modules $GIT_BRANCH
