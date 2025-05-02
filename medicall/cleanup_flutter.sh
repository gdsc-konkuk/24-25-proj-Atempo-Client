#!/bin/bash
echo "Flutter 캐시 정리 중..."
cd /Users/clice/Documents/Projects/24-25-proj-Avenir-Client/medicall
flutter clean
echo "iOS 빌드 파일 삭제 중..."
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
echo "패키지 재설치 중..."
flutter pub get
cd ios
pod deintegrate
pod setup
pod install --repo-update
