#!/bin/bash
BUILD_DIR="Build"
rm -rf ./${BUILD_DIR}

WORKSPACE="Example/Fastboard.xcworkspace"
function createXC {
    SCHEME=$1

    xcodebuild archive -workspace $WORKSPACE \
    -scheme $SCHEME \
    -sdk iphoneos \
    -archivePath $BUILD_DIR/$SCHEME-iphoneos.xcarchive \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

    xcodebuild archive -workspace $WORKSPACE \
    -scheme $SCHEME \
    -sdk iphonesimulator \
    -archivePath $BUILD_DIR/$SCHEME-iphonesimulator.xcarchive \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

    xcodebuild -create-xcframework \
    -framework $BUILD_DIR/$SCHEME-iphoneos.xcarchive/Products/Library/Frameworks/$SCHEME.framework \
    -framework $BUILD_DIR/$SCHEME-iphonesimulator.xcarchive/Products/Library/Frameworks/$SCHEME.framework \
    -output $BUILD_DIR/$SCHEME.xcframework

    rm -rf $BUILD_DIR/$SCHEME-iphoneos.xcarchive
    rm -rf $BUILD_DIR/$SCHEME-iphonesimulator.xcarchive
}

createXC 'NTLBridge'
createXC 'White_YYModel'
createXC 'Whiteboard'
createXC 'Fastboard'