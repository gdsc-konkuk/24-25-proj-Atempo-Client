#!/bin/bash

# .env 파일에서 API 키 읽기
if [ -f ../.env ]; then
  export $(grep -v '^#' ../.env | xargs)
else
  echo "오류: .env 파일을 찾을 수 없습니다."
  exit 1
fi

# Config.xcconfig 파일 생성
echo "// 자동 생성된 파일 - 직접 수정하지 마세요" > ../ios/Config.xcconfig
echo "GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}" >> ../ios/Config.xcconfig

# android/app/src/main/res/values/strings.xml 파일에 API 키 설정
mkdir -p ../android/app/src/main/res/values
cat > ../android/app/src/main/res/values/strings.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="google_maps_api_key">${GOOGLE_MAPS_API_KEY}</string>
</resources>
EOF

echo "API 키 설정이 완료되었습니다."
