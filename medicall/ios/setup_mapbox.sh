#!/bin/bash

# Mapbox 설정 스크립트
echo "Mapbox Navigation SDK 설정 스크립트"
echo "=================================="

# 환경 변수 파일에서 토큰 추출
ENV_FILE="../.env"
SECRET_TOKEN=""

if [ -f "$ENV_FILE" ]; then
    echo "환경 변수 파일 발견: $ENV_FILE"
    # .env 파일에서 MAPBOX_SECRET_TOKEN 값 추출
    SECRET_TOKEN=$(grep "MAPBOX_SECRET_TOKEN" "$ENV_FILE" | cut -d "=" -f2)
    
    # 값이 비어있거나 sk.로 시작하지 않으면 ACCESS_TOKEN 확인
    if [ -z "$SECRET_TOKEN" ] || [[ "$SECRET_TOKEN" != sk.* ]]; then
        echo "Secret token이 유효하지 않습니다. ACCESS_TOKEN 확인 중..."
        SECRET_TOKEN=$(grep "MAPBOX_ACCESS_TOKEN" "$ENV_FILE" | cut -d "=" -f2)
        
        # ACCESS_TOKEN이 sk.로 시작하는지 확인
        if [[ "$SECRET_TOKEN" == sk.* ]]; then
            echo "ACCESS_TOKEN에서 Secret token 발견!"
        else
            echo "유효한 Secret token을 찾을 수 없습니다."
            echo "Secret token 직접 입력:"
            read SECRET_TOKEN
        fi
    fi
else
    echo "환경 변수 파일을 찾을 수 없습니다: $ENV_FILE"
    echo "Secret token 직접 입력:"
    read SECRET_TOKEN
fi

# .netrc 파일 생성 또는 업데이트
NETRC_FILE=~/.netrc

# 파일 존재 여부 확인
if [ -f "$NETRC_FILE" ]; then
    echo "기존 .netrc 파일 발견. 백업 생성 중..."
    cp "$NETRC_FILE" "$NETRC_FILE.backup"
    
    # api.mapbox.com 항목이 이미 있는지 확인
    if grep -q "api.mapbox.com" "$NETRC_FILE"; then
        echo "기존 Mapbox 항목 발견. 업데이트 중..."
        # 임시 파일 생성
        TEMP_FILE=$(mktemp)
        
        # api.mapbox.com 항목 제거 및 새 항목 추가
        sed '/machine api.mapbox.com/,+2d' "$NETRC_FILE" > "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        echo "machine api.mapbox.com" >> "$TEMP_FILE"
        echo "  login mapbox" >> "$TEMP_FILE"
        echo "  password $SECRET_TOKEN" >> "$TEMP_FILE"
        
        # 원본 파일 교체
        mv "$TEMP_FILE" "$NETRC_FILE"
    else
        echo "Mapbox 항목 추가 중..."
        echo "" >> "$NETRC_FILE"
        echo "machine api.mapbox.com" >> "$NETRC_FILE"
        echo "  login mapbox" >> "$NETRC_FILE"
        echo "  password $SECRET_TOKEN" >> "$NETRC_FILE"
    fi
else
    echo "새 .netrc 파일 생성 중..."
    echo "machine api.mapbox.com" > "$NETRC_FILE"
    echo "  login mapbox" >> "$NETRC_FILE"
    echo "  password $SECRET_TOKEN" >> "$NETRC_FILE"
fi

# 파일 권한 설정
chmod 600 "$NETRC_FILE"
echo ".netrc 파일 권한 설정: chmod 600"

echo ""
echo "설정 완료. 이제 다음 명령어로 iOS 빌드를 진행하세요:"
echo "cd ios && pod install && cd .. && flutter run"
echo ""
echo "설정 파일 정보:"
echo "- .netrc 파일 위치: $NETRC_FILE"
echo "- 권한: $(stat -f "%Lp" "$NETRC_FILE")"
