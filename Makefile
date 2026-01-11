SHELL := /bin/bash

.PHONY: help ios-build ios-clean

IOS_PROJECT := ios/tagalog-lite.xcodeproj
IOS_SCHEME := tagalog-lite
IOS_CONFIGURATION ?= Debug
IOS_SDK ?= iphoneos
IOS_DESTINATION ?= generic/platform=iOS
IOS_DERIVED_DATA ?= ios/.DerivedData

help:
	@echo "Targets:"
	@echo "  ios-build   Build the iOS app with xcodebuild"
	@echo "              (override with IOS_CONFIGURATION=Release)"
	@echo "  ios-clean   Clean build artifacts (DerivedData under ios/)"

ios-build:
	xcrun xcodebuild \
		-project "$(IOS_PROJECT)" \
		-scheme "$(IOS_SCHEME)" \
		-configuration "$(IOS_CONFIGURATION)" \
		-sdk "$(IOS_SDK)" \
		-destination "$(IOS_DESTINATION)" \
		-derivedDataPath "$(IOS_DERIVED_DATA)" \
		build

ios-clean:
	xcrun xcodebuild \
		-project "$(IOS_PROJECT)" \
		-scheme "$(IOS_SCHEME)" \
		-configuration "$(IOS_CONFIGURATION)" \
		clean
	rm -rf "$(IOS_DERIVED_DATA)"

