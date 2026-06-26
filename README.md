# 정보처리기사 실기 튜터 (iOS)

문제를 **텍스트로 입력하거나 캡처를 올리면**, Claude가 정보처리기사 실기 기준으로
단계별 풀이 · 쉽게 푸는 법 · 코드 추적표 · 시험 포인트 · 정답을 만들어주는 SwiftUI 앱.

- C / Java / Python / SQL / 단답형 지원
- 캡처 이미지 인식(OCR 없이 바로 코드 읽고 풀이)
- 답이 실시간으로 한 줄씩 스트리밍됨
- API 키는 **이 기기 키체인에만** 저장 (외부 서버 없음)

---

## 0. 준비물

- **Mac + Xcode 16 이상** (App Store에서 무료 설치 — 첫 설치는 시간이 좀 걸립니다)
- **Anthropic API 키** — https://console.anthropic.com 에서 발급
  (사용한 만큼 과금되는 유료 키입니다. 학습용이면 비용은 보통 소액입니다.)

> Xcode가 설치되어 있어야 빌드·실행이 됩니다. 현재 이 Mac에는 Command Line Tools만
> 깔려 있어 빌드가 안 됩니다. Xcode부터 설치하세요.

---

## 1. Xcode 프로젝트 만들기

1. Xcode 실행 → **Create New Project…**
2. **iOS → App** 선택 → Next
3. 입력값:
   - Product Name: **InfoExamTutor**  ← (이 이름으로 만들면 파일을 그대로 쓸 수 있어요)
   - Interface: **SwiftUI**
   - Language: **Swift**
4. 저장 위치를 고르고 Create.

그러면 `InfoExamTutor/InfoExamTutor/` 폴더 안에 `InfoExamTutorApp.swift`,
`ContentView.swift` 두 파일이 기본으로 생깁니다.

## 2. 소스 코드 넣기

이 폴더(`info-exam-tutor/InfoExamTutor/`)에 있는 **모든 `.swift` 파일**을
방금 Xcode가 만든 `InfoExamTutor/InfoExamTutor/` 폴더로 **복사해서 덮어쓰기** 하세요.
(기본 생성된 `InfoExamTutorApp.swift`, `ContentView.swift`는 덮어쓰면 됩니다.)

Xcode 16의 새 프로젝트는 폴더와 자동 동기화되므로, 파일을 폴더에 넣기만 하면
프로젝트에 자동으로 포함됩니다. (Finder에서 파일을 폴더로 드래그하면 끝)

> 만약 자동으로 안 잡히면: Xcode 좌측 파일 목록에서 프로젝트를 우클릭 →
> **Add Files to "InfoExamTutor"…** 로 `.swift` 파일들을 추가하세요.

## 3. 배포 타깃 확인

- 프로젝트 설정 → **Minimum Deployments → iOS 17.0** 이상으로 설정.
  (PhotosPicker, NavigationStack, #Preview 등 최신 API를 사용합니다.)

## 4. 실행

1. 상단에서 시뮬레이터(예: iPhone 15)를 고르고 **▶︎ (Run)** 클릭.
2. 앱이 뜨면 **설정 탭 → API 키 입력 → 저장**.
3. **문제 풀이 탭**에서 문제를 입력하거나 캡처를 올리고 **풀이 보기**.

---

## 파일 구성

| 파일 | 역할 |
|---|---|
| `InfoExamTutorApp.swift` | 앱 진입점 |
| `ContentView.swift` | 탭(문제 풀이 / 설정) |
| `HomeView.swift` | 입력 화면(텍스트·사진·유형) + 답안 표시 |
| `SettingsView.swift` | API 키 입력, 모델 선택 |
| `SolveViewModel.swift` | 상태 관리 + 풀이 요청 |
| `ClaudeClient.swift` | Anthropic Messages API 스트리밍 호출(이미지 포함) |
| `Prompts.swift` | 정보처리기사 실기 기준 시스템 프롬프트 |
| `MarkdownView.swift` | 답안 마크다운 렌더러(헤더/코드/표/불릿) |
| `ImageHelper.swift` | 캡처 다운스케일·JPEG 변환 |
| `Keychain.swift` / `AppSettings.swift` | 키 저장 / 전역 설정 |
| `Models.swift` | 문제 유형·모델 enum |

---

## 비용·모델

설정에서 모델을 바꿀 수 있습니다.

- **Opus 4.8** (기본) — 가장 정확. 코드 추적·까다로운 문제에 추천.
- **Sonnet 4.6** — 빠르고 저렴. 대부분의 문제에 충분.
- **Haiku 4.5** — 가장 빠르고 가장 저렴.

문제 하나당 토큰 사용량은 작아서, 학습용으로는 보통 소액입니다.
비용이 신경 쓰이면 평소엔 Sonnet/Haiku, 어려운 문제만 Opus로 쓰는 식이 좋습니다.

## 다음 단계(원하면 확장 가능)

- 푼 문제 **히스토리 저장**(SwiftData)
- **카메라로 바로 촬영**해서 풀기
- **오답 노트 / 즐겨찾기**
- 비슷한 **연습문제 생성**
- 실기 단답형 **암기 카드(플래시카드)**
