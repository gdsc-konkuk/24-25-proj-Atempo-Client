#!/bin/bash

# 환경 변수에서 API 키 가져오기 또는 .env 파일에서 읽기
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
  if [ -f ../.env ]; then
    export $(grep -v '^#' ../.env | xargs)
  else
    echo "API 키를 찾을 수 없습니다. 환경 변수 GOOGLE_MAPS_API_KEY를 설정하거나 .env 파일을 생성하세요."
    exit 1
  fi
fi

# Flutter 웹 빌드
flutter build web

# 빌드된 index.html에서 API 키 플레이스홀더 대체
sed -i '' "s/GOOGLE_MAPS_API_KEY_PLACEHOLDER/$GOOGLE_MAPS_API_KEY/g" ../build/web/index.html

echo "웹 빌드 완료 - API 키가 적용되었습니다."
