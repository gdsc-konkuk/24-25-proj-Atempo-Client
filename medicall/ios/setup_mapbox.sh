#!/bin/bash

# Mapbox Navigation SDK Setup Script
echo "Mapbox Navigation SDK Setup Script"
echo "=================================="

# Extract token from environment variable file
ENV_FILE="../.env"
SECRET_TOKEN=""

if [ -f "$ENV_FILE" ]; then
    echo "Environment file found: $ENV_FILE"
    # Extract MAPBOX_ACCESS_TOKEN value from .env file
    SECRET_TOKEN=$(grep "MAPBOX_ACCESS_TOKEN" "$ENV_FILE" | cut -d "=" -f2)
    
    # If the value is empty or does not start with sk., verify ACCESS_TOKEN
    if [ -z "$SECRET_TOKEN" ] || [[ "$SECRET_TOKEN" != sk.* ]]; then
        echo "Secret token is not valid. Verifying ACCESS_TOKEN..."
        SECRET_TOKEN=$(grep "MAPBOX_ACCESS_TOKEN" "$ENV_FILE" | cut -d "=" -f2)
        
        # Check if ACCESS_TOKEN starts with sk.
        if [[ "$SECRET_TOKEN" == sk.* ]]; then
            echo "Secret token found from ACCESS_TOKEN!"
        else
            echo "Could not find a valid Secret token."
            echo "Please enter Secret token manually:"
            read SECRET_TOKEN
        fi
    fi
else
    echo "Environment file not found: $ENV_FILE"
    echo "Please enter Secret token manually:"
    read SECRET_TOKEN
fi

# Create or update .netrc file
NETRC_FILE=~/.netrc

if [ -f "$NETRC_FILE" ]; then
    echo "Existing .netrc file found. Creating backup..."
    cp "$NETRC_FILE" "$NETRC_FILE.backup"
    
    if grep -q "api.mapbox.com" "$NETRC_FILE"; then
        echo "Existing Mapbox entry found. Updating..."
        TEMP_FILE=$(mktemp)
        sed '/machine api.mapbox.com/,+2d' "$NETRC_FILE" > "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        echo "machine api.mapbox.com" >> "$TEMP_FILE"
        echo "  login mapbox" >> "$TEMP_FILE"
        echo "  password $SECRET_TOKEN" >> "$TEMP_FILE"
        mv "$TEMP_FILE" "$NETRC_FILE"
    else
        echo "Adding Mapbox entry..."
        echo "" >> "$NETRC_FILE"
        echo "machine api.mapbox.com" >> "$NETRC_FILE"
        echo "  login mapbox" >> "$NETRC_FILE"
        echo "  password $SECRET_TOKEN" >> "$NETRC_FILE"
    fi
else
    echo "Creating new .netrc file..."
    echo "machine api.mapbox.com" > "$NETRC_FILE"
    echo "  login mapbox" >> "$NETRC_FILE"
    echo "  password $SECRET_TOKEN" >> "$NETRC_FILE"
fi

chmod 600 "$NETRC_FILE"
echo ".netrc file permissions set to 600"

echo ""
echo "Setup complete. Now run the following commands to build for iOS:"
echo "cd ios && pod install && cd .. && flutter run"
echo ""
echo "Setup file information:"
echo "- .netrc file location: $NETRC_FILE"
echo "- Permissions: $(stat -f "%Lp" "$NETRC_FILE")"
