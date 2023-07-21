#!/bin/sh

$ANDROID_SDK_ROOT/platform-tools/adb start-server
$ANDROID_HOME/sdk/emulator/emulator -avd Default -no-snapshot

