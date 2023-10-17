#!/bin/bash

mkdir ~/.bin
mkdir ~/.log
mkdir ~/Library/LaunchAgents

cp -r ./LaunchAgents/* ~/Library/LaunchAgents/
cp -r ./Scripts/* ~/.bin/

launchctl load ~/Library/LaunchAgents/co.nimblehq.cleanUpXcodeArchives.plist
launchctl load ~/Library/LaunchAgents/co.nimblehq.cleanUpKeychains.plist
launchctl load ~/Library/LaunchAgents/co.nimblehq.cleanUpRunners.plist
launchctl load ~/Library/LaunchAgents/co.nimblehq.cleanUpXcodeDerivedData.plist
