#!/bin/bash
echo "1. Flutter 캐시 정리 중..."
flutter clean

echo "2. 패키지 캐시 및 임시 파일 삭제 중..."
rm -rf ~/.pub-cache/hosted
rm -rf .dart_tool/
rm -rf build/

echo "3. 패키지 다시 가져오는 중..."
flutter pub get

echo "4. Flutter 진단 실행 중..."
flutter doctor -v

echo "5. 앱 다시 빌드 중..."
flutter build ios --debug --no-codesign
# 또는 안드로이드인 경우: flutter build apk

echo "완료! 이제 앱을 실행해보세요."
