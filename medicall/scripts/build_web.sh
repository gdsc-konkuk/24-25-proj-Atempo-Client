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

# Build Flutter web
flutter build web

# Replace API key placeholder in built index.html
sed -i '' "s/GOOGLE_MAPS_API_KEY_PLACEHOLDER/$GOOGLE_MAPS_API_KEY/g" ../build/web/index.html

echo "Web build complete - API key applied."
