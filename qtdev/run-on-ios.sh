#!/bin/bash

PROJECT_FILE=$(find . -name '*.xcodeproj')
if [ -z "$PROJECT_FILE" ]
then
    >&2 echo "No Xcode project file found - generate first:"
    >&2 echo "    ~/host/qt/bin/qt-cmake-standalone-test ~/project/sources -GXcode"
    exit 3
fi

if ! xcrun simctl list devices booted | grep Booted > /dev/null
then
    # iPhone 11 Pro Max running iOS 14.3
    xcrun simctl boot 6F05552B-90B0-4ED1-AF6C-5164A9728C4C
    if [ $? -gt 0 ]
    then
        >&2 echo "iPhone 11 Pro Max with iOS 14.3 is not available"
        exit 1
    fi
fi

open -a Simulator.app 2> /dev/null

if [ $? -gt 0 ]
then
    >&2 echo "iOS Simulator not installed, GUI not available"
fi

xcodebuild -arch x86_64 -configuration "Debug" -sdk "iphonesimulator" -destination "generic/platform=iOS Simulator" build \
           CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED=NO

if [ $? -gt 0 ]
then
    >&2 echo "Build error, cannot continue."
    exit 4
fi

first=1
while ! xcrun simctl list devices booted | grep Booted > /dev/null
do
    [ $first -eq 1 ] && printf "Waiting for device to finish booting..."
    first=0
    printf "."
    sleep 1
done
[ $first -eq 0 ] && printf "\n"

APP_BUNDLE=$(find . -name '*.app')
APP_NAME=$(basename "$APP_BUNDLE")
APP_NAME="${APP_NAME%.*}"
APP_ID="f.${APP_NAME//_/-}"
# APP_ID="my.example.com"

function terminate()
{
    xcrun simctl terminate booted "$APP_ID"
}

xcrun simctl install booted "$APP_BUNDLE"

trap terminate SIGINT
xcrun simctl launch --console-pty booted "$APP_ID"

xcrun simctl uninstall booted "$APP_ID"
