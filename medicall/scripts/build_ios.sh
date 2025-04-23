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

# xcconfig 파일에 API 키 설정
echo "// 자동 생성된 파일입니다. 직접 수정하지 마세요." > ../ios/Config.xcconfig
echo "GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY" >> ../ios/Config.xcconfig

# Xcode 설정에 xcconfig 파일 적용
# Flutter는 Runner.xcodeproj/project.pbxproj에 설정을 저장합니다
echo "Xcode 프로젝트에 Config.xcconfig를 적용하세요:"
echo "1. Xcode에서 Runner 프로젝트 열기"
echo "2. Runner 프로젝트 선택 -> Info 탭"
echo "3. Configuration -> 'Config' 선택 (없다면 'Config' 생성 후 Config.xcconfig 파일 지정)"
echo "4. 빌드 진행"

# Flutter 빌드 (옵션)
# flutter build ios

echo "iOS 빌드 준비 완료 - API 키가 설정되었습니다."
