#!/bin/bash

# Read API keys from .env file
if [ -f ../.env ]; then
  export $(grep -v '^#' ../.env | xargs)
else
  echo "Error: .env file not found."
  exit 1
fi

# Create Config.xcconfig file
echo "// Auto-generated file - Do not edit directly" > ../ios/Config.xcconfig
echo "GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}" >> ../ios/Config.xcconfig

# Set API keys in android/app/src/main/res/values/strings.xml file
mkdir -p ../android/app/src/main/res/values
cat > ../android/app/src/main/res/values/strings.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="google_maps_api_key">${GOOGLE_MAPS_API_KEY}</string>
</resources>
EOF

echo "API key setup completed."
