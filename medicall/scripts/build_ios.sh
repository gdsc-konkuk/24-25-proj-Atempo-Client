#!/bin/bash

# Retrieve API key from environment variable or .env file
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
  if [ -f ../.env ]; then
    export $(grep -v '^#' ../.env | xargs)
  else
    echo "API key not found. Please set the GOOGLE_MAPS_API_KEY environment variable or create an .env file."
    exit 1
  fi
fi

# Set API key in xcconfig file
echo "// Auto-generated file. Do not modify directly." > ../ios/Config.xcconfig
echo "GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY" >> ../ios/Config.xcconfig

echo "Apply Config.xcconfig in Xcode project settings:"
echo "1. Open the Runner project in Xcode"
echo "2. Select the Runner project -> Info tab"
echo "3. Under Configuration, choose or create a 'Config' and specify the Config.xcconfig file"
echo "4. Proceed with the build"

echo "iOS build preparation complete - API key set."
