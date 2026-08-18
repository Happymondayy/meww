# meww

음악과 독서 기록을 남기고, 쌓인 기록을 바탕으로 AI가 취향에 맞는 다음 작품을 추천해주는 iOS 앱입니다.

## 프로젝트 소개

meww는 들었던 음악과 읽었던 책을 한 곳에 기록하는 앱입니다. 별점, 감상, 다시 듣고/읽고 싶은지 여부를 남기면 앱이 이 기록들을 분석해서 좋아하는 아티스트/저자를 찾아내고, Google Gemini를 통해 취향에 맞는 새로운 음악과 책을 추천해줍니다.

## 주요 기능

- **기록 추가**: Apple Music(MusicKit)과 Google Books에서 실제 음악/책을 검색해서 앨범 아트·표지와 함께 기록을 남길 수 있어요. 별점, 감상, "다시 듣고/읽고 싶어요" 여부를 함께 남깁니다. 독서 기록에는 한 줄 요약과 추천 대상도 추가로 입력할 수 있어요.
- **홈 – 월별 기록 타임라인**: 남긴 기록을 월별로 그룹핑해서 보여주고, 이번 달에 음악/독서를 몇 개 기록했는지 요약해서 보여줘요.
- **문장 스크랩**: 감상 중 마음에 들어 북마크로 표시한 문장만 따로 모아볼 수 있어요.
- **다시 보고 싶은 기록**: "다시 듣고/읽고 싶어요"로 표시한 기록만 모아보고, 직접 만든 폴더로 분류해서 정리할 수 있어요.
- **AI 취향 추천**: 별점 4점 이상을 준 아티스트/저자, 다시 듣고/읽고 싶어요로 표시한 기록을 바탕으로 취향 프로필을 만들고, Gemini API로 취향에 맞는 새로운 음악·책을 추천받아요. 추천된 항목의 앨범 아트/표지도 함께 찾아서 보여줍니다.

## 기술 스택

- **SwiftUI** — UI
- **SwiftData** — 기록(`Record`), 폴더(`Folder`) 로컬 저장
- **MusicKit** — Apple Music 카탈로그 검색
- **Google Books API** — 책 검색
- **Gemini API** — 취향 분석 기반 추천 문구/항목 생성

## 시작하기

### 요구 사항

- Xcode
- Apple Music 검색을 위한 Apple 계정 (MusicKit 인증)
- Google Books API 키
- Google Gemini API 키

### API 키 설정

이 프로젝트는 API 키를 코드에 직접 두지 않고 `Secrets.swift`에서 읽습니다. `Secrets.swift`는 `.gitignore`에 등록되어 있어 저장소에는 올라가지 않으므로, 프로젝트를 처음 받았다면 직접 만들어야 합니다.

1. 루트에 있는 `Secrets.example.swift`를 복사해서 `meww/Secrets.swift`로 저장합니다.

   ```bash
   cp Secrets.example.swift meww/Secrets.swift
   ```

2. `meww/Secrets.swift`를 열어 발급받은 API 키를 채워 넣습니다.

   ```swift
   enum Secrets {
       static let googleBooksAPIKey = "YOUR_GOOGLE_BOOKS_API_KEY"
       static let googleGeminiAPIKey = "YOUR_GEMINI_API_KEY"
   }
   ```

3. Xcode에서 `meww.xcodeproj`를 열고 앱을 빌드/실행합니다.

> ⚠️ `meww/Secrets.swift`는 절대 커밋하지 마세요. 이미 `.gitignore`에 등록되어 있지만, 커밋 전에는 항상 `git status`로 한 번 더 확인하는 것을 권장합니다.
