#!/bin/bash

# Mapbox Authentication Test Script
echo "Mapbox Authentication Test"
echo "=========================="

# URL to test
TEST_URL="https://api.mapbox.com/downloads/v2/mobile-navigation-native/releases/ios/packages/206.1.1/MapboxNavigationNative.xcframework.zip"

echo "Starting authentication test..."
echo "URL: $TEST_URL"
echo ""

# Test with curl (only fetch headers)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -I "$TEST_URL" --netrc-optional)

echo "Response code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ Authentication success! Able to access Mapbox API successfully."
    echo "Now, running 'pod install' will allow the build to proceed normally."
elif [ "$HTTP_CODE" = "401" ]; then
    echo "❌ Authentication failed! (401 Unauthorized)"
    echo "1. Check that the .netrc file is set up correctly."
    echo "2. Verify that the Secret Token is valid."
    echo "3. Try running the './setup_mapbox.sh' script again."
    
    # Check .netrc file
    if [ -f ~/.netrc ]; then
        echo ""
        echo ".netrc file info:"
        echo "- Permissions: $(stat -f "%Lp" ~/.netrc)"
        if [ "$(stat -f "%Lp" ~/.netrc)" != "600" ]; then
            echo "  ⚠️ Permissions are not set to 600. Run 'chmod 600 ~/.netrc'."
        fi
        
        # Check Mapbox config
        if grep -q "api.mapbox.com" ~/.netrc; then
            echo "- Mapbox configuration exists."
        else
            echo "- ⚠️ No Mapbox configuration found!"
        fi
    else
        echo ""
        echo "⚠️ .netrc file does not exist!"
    fi
else
    echo "❓ Unexpected response: $HTTP_CODE"
    echo "There may be an issue connecting to the Mapbox API."
fi
