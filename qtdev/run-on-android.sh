#! /bin/bash

export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
export PATH=$PATH:$ANDROID_SDK_ROOT/build-tools/31.0.0

echo "Installing $1"
adb install $1

echo "Launching $1"
pkg=$(aapt dump badging $1|awk -F" " '/package/ {print $2}'|awk -F"'" '/name=/ {print $2}')
act=$(aapt dump badging $1|awk -F" " '/launchable-activity/ {print $2}'|awk -F"'" '/name=/ {print $2}')
adb shell am start -n $pkg/$act
