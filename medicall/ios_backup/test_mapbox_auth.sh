#!/bin/bash

# Mapbox 인증 테스트 스크립트
echo "Mapbox 인증 테스트"
echo "=================="

# 테스트할 URL
TEST_URL="https://api.mapbox.com/downloads/v2/mobile-navigation-native/releases/ios/packages/206.1.1/MapboxNavigationNative.xcframework.zip"

echo "인증 테스트를 시작합니다..."
echo "URL: $TEST_URL"
echo ""

# curl로 테스트 (헤더만 받아옴)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -I "$TEST_URL" --netrc-optional)

echo "응답 코드: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ 인증 성공! Mapbox API에 정상적으로 접근할 수 있습니다."
    echo "이제 'pod install'을 실행하면 빌드가 정상적으로 진행될 것입니다."
elif [ "$HTTP_CODE" = "401" ]; then
    echo "❌ 인증 실패! (401 Unauthorized)"
    echo "1. .netrc 파일이 제대로 설정되어 있는지 확인하세요."
    echo "2. Secret Token이 유효한지 확인하세요."
    echo "3. './setup_mapbox.sh' 스크립트를 다시 실행해보세요."
    
    # .netrc 파일 점검
    if [ -f ~/.netrc ]; then
        echo ""
        echo ".netrc 파일 정보:"
        echo "- 권한: $(stat -f "%Lp" ~/.netrc)"
        if [ "$(stat -f "%Lp" ~/.netrc)" != "600" ]; then
            echo "  ⚠️ 권한이 600이 아닙니다. 'chmod 600 ~/.netrc'를 실행하세요."
        fi
        
        # Mapbox 설정 확인
        if grep -q "api.mapbox.com" ~/.netrc; then
            echo "- Mapbox 설정이 존재합니다."
        else
            echo "- ⚠️ Mapbox 설정이 없습니다!"
        fi
    else
        echo ""
        echo "⚠️ .netrc 파일이 존재하지 않습니다!"
    fi
else
    echo "❓ 예상치 못한 응답: $HTTP_CODE"
    echo "Mapbox API 연결에 문제가 있을 수 있습니다."
fi
