# meww

![Swift](https://img.shields.io/badge/Swift-5.0-F05138?style=flat&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0058CC?style=flat&logo=swift&logoColor=white)
![SwiftData](https://img.shields.io/badge/SwiftData-4A90D9?style=flat&logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-26.2-147EFB?style=flat&logo=xcode&logoColor=white)
![MusicKit](https://img.shields.io/badge/MusicKit-Apple-000000?style=flat&logo=apple&logoColor=white)

음악과 독서 기록을 남기고, AI가 취향에 맞는 다음 작품을 추천해주는 iOS 앱입니다.

## 소개

meww는 들었던 음악과 읽었던 책을 한 곳에 기록하는 앱입니다. 별점, 감상, 다시 듣고/읽고 싶은지 여부를 남기면 앱이 이 기록들을 분석해서 좋아하는 아티스트/저자를 찾아냅니다. 이렇게 만들어진 취향 프로필을 바탕으로 Google Gemini가 새로운 음악과 책을 추천해줍니다. 기록이 쌓일수록 추천도 더 정교해집니다.

## 기술 스택

- **SwiftUI** — 앱 UI 구성
- **SwiftData** — 기록·폴더 로컬 저장
- **MusicKit** — Apple Music 카탈로그에서 음악 검색
- **Google Books API** — 책 검색
- **Gemini API** — 취향 분석 기반 음악·책 추천 생성
