# PLAN

## Goal

`simfit-memo`는 SwiftUI 기반 iOS + watchOS 운동 기록 앱이다. 사용자는 운동 종목 목록에서 루틴을 만들고, 루틴 또는 빈 운동으로 세션을 시작하며, 운동 중 세트별 무게와 횟수를 기록하고 완료 버튼을 눌러 쉬는시간 타이머를 시작할 수 있다. Apple Watch에서는 현재 운동/목표 세트 정보를 보고 세트를 완료할 수 있으며, 쉬는시간 중 남은 시간과 현재 심박수를 확인할 수 있다.

## Current Context

- 저장소 루트는 `/Users/jmsim/Documents/simfit-memo`이다.
- 현재 저장소에는 `.git/`만 있고 앱 코드, Xcode 프로젝트, `README`, `PLAN.md`가 없었다.
- `git status --short` 기준 작업트리는 깨끗했다.
- 로컬 개발 환경에는 `Xcode 26.4.1`이 설치되어 있고 `xcode-select -p`는 `/Applications/Xcode.app/Contents/Developer`를 가리킨다.
- `xcodegen`은 현재 설치되어 있지 않지만 Homebrew는 설치되어 있다. 빈 저장소에서 `.xcodeproj`를 손으로 관리하지 않도록 MVP는 `Brewfile` + `project.yml` + `XcodeGen` 기반 프로젝트 생성을 기본으로 한다.
- 사용자가 2026-05-26에 iPhone 앱 레퍼런스 스크린샷 5장을 제공했다:
  - `/Users/jmsim/Downloads/IMG_9666.PNG`: 홈/오늘 운동 기록 화면.
  - `/Users/jmsim/Downloads/IMG_9667.PNG`: 루틴 목록 화면.
  - `/Users/jmsim/Downloads/IMG_9668.PNG`: 루틴 상세 바텀시트 화면.
  - `/Users/jmsim/Downloads/IMG_9669.PNG`: 새 루틴 이름 입력 화면.
  - `/Users/jmsim/Downloads/IMG_9670.PNG`: 운동 선택/검색 화면.
- 레퍼런스 이미지는 어두운 배경, 밝은 흰색 텍스트, muted blue-gray 보조 텍스트/라인, vivid blue primary action을 중심으로 한 고밀도 운동 앱 UI다. exact clone이 아니라 같은 사용감과 정보 구조를 목표로 삼는다.
- 2026-05-26 기준 운동 seed 데이터 소스로 Free Exercise DB를 확인했다:
  - GitHub: `https://github.com/yuhonas/free-exercise-db`
  - 통합 JSON: `https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json`
  - 라이선스: `Unlicense`
  - 현재 통합 JSON 기준 약 873개 운동이 있으며, 각 운동은 `id`, `name`, `force`, `level`, `mechanic`, `equipment`, `primaryMuscles`, `secondaryMuscles`, `instructions`, `category`, `images` 필드를 제공한다.
  - 이미지 필드는 존재하지만 MVP에서는 운동 자세 아이콘/썸네일을 사용하지 않는다.
- 2026-05-26 기준 Apple 공식 문서 확인 사항:
  - `SwiftData`는 로컬 영속성과 선택적 iCloud 동기화를 지원한다. iCloud 동기화는 별도 iCloud/Background Modes capability와 CloudKit 호환 스키마 제약이 필요하므로 MVP에서는 필수로 두지 않는다.
  - `WatchConnectivity.WCSession`은 현재 상태 전달(`updateApplicationContext`), 즉시 메시지(`sendMessage`), 백그라운드 전송(`transferUserInfo`)을 제공한다. WatchConnectivity는 실제 페어링된 기기 테스트가 중요하다.
  - `HealthKit` 데이터 접근은 세분화된 권한이 필요하며, 심박수는 `HKQuantityTypeIdentifier.heartRate`로 읽는다. 권한 요청 전 `NSHealthShareUsageDescription` 같은 usage description을 반드시 설정해야 한다.
  - 실시간 운동 중 심박수 표시가 필요한 경우 Watch 쪽에서 `HealthKit` 권한과 watchOS 제약을 고려해야 하며, 시뮬레이터만으로는 실제 심박수/연결 동작 검증이 어렵다.

## Decisions

- 앱 스택은 SwiftUI 네이티브 iOS + watchOS로 시작한다.
- 기본 운동 seed 목록을 제공하고, 사용자가 커스텀 운동을 추가할 수 있게 한다.
- 루틴의 필수 값은 운동 종목이다. 각 운동에는 선택적으로 세트별 목표 무게와 목표 횟수를 지정할 수 있다.
- MVP의 Apple Health 범위는 Apple Watch에서 현재 심박수를 표시하는 것까지다. 운동 세션을 Apple Health에 기록하거나 저장하는 기능은 MVP 범위 밖이다.
- Apple Watch에서는 현재 운동 제어뿐 아니라 루틴과 운동 기록도 조회할 수 있어야 한다.
- iPhone을 canonical data source로 두고, Watch는 `WatchConnectivity`로 받은 루틴/기록/진행 중 운동의 로컬 캐시를 조회한다. Watch에서 발생한 세트 완료 이벤트는 iPhone으로 전송하고, iPhone이 상태를 갱신한 뒤 Watch에 다시 동기화한다.
- 프로젝트 생성은 `XcodeGen`으로 재현 가능하게 관리한다. 구현자는 `Brewfile`에 `xcodegen`을 명시하고 `project.yml`에서 iOS/watchOS 타깃, shared source, tests, capabilities를 선언한다.
- iOS 앱의 첫 화면은 레퍼런스처럼 “오늘/운동 기록” 중심의 홈 화면으로 둔다. 사용자는 여기서 날짜를 확인하고, `불러오기`, `운동 선택하기`, `루틴 탐색`, `내 루틴`으로 빠르게 이동할 수 있다.
- iOS visual direction은 dark-first native SwiftUI다. 배경은 거의 검정에 가까운 charcoal, surface는 조금 밝은 slate, primary action은 선명한 blue, 보조 텍스트/라인/아이콘은 blue-gray 계열을 쓴다.
- 루틴 목록은 카드형 UI로 만든다. 각 카드는 루틴명, 운동 부위 요약, 최근 수행일 또는 “수행 정보 없음”, 완료 횟수 badge, overflow menu를 표시한다. 레퍼런스의 `PRO` lock/paywall 표시는 MVP에 넣지 않는다.
- 루틴 상세는 전체 화면 push보다 large rounded bottom sheet presentation을 우선한다. 상단 drag handle, 중앙 루틴명, `편집` 액션, 운동별 순번/이름/부위/세트 수/총 볼륨/expand chevron을 포함한다.
- 운동 선택 화면은 검색, 카테고리 chip, 북마크 필터, 정렬, 운동 row checkbox, 운동명/부위/장비, 북마크, 정보 버튼, safe-area 고정 하단 CTA를 포함한다.
- 기본 운동 seed는 Free Exercise DB를 기준으로 생성한다. MVP에서는 운동 자세 아이콘, 썸네일, 이미지 다운로드/번들링을 제외하고 텍스트 중심 목록으로 시작한다.

## Assumptions

- MVP 언어는 한국어 UI를 기본으로 한다.
- 기본 단위는 `kg`이다. `lb` 전환은 설정 기능이 필요하므로 MVP 범위 밖으로 둔다.
- Watch에서 루틴과 운동 기록은 조회 중심이다. 루틴 생성/편집, 커스텀 운동 생성은 iPhone에서 수행한다.
- Watch가 iPhone과 일시적으로 연결되지 않은 경우, 마지막으로 동기화된 루틴/기록 캐시를 보여주고 세트 완료 같은 이벤트는 가능한 범위에서 큐잉한다.
- 쉬는시간은 세트별로 저장 가능한 `restSeconds`를 모델에 두되, 사용자가 명시하지 않은 경우 기본값을 사용한다. 기본값은 구현 시 90초로 시작하고 설정 화면이 생기면 변경 가능하게 확장한다.
- 운동 기록은 앱 내부 SwiftData 저장소에 저장한다. Apple Health에 workout sample을 쓰는 기능은 향후 별도 결정 후 추가한다.
- 라이브 심박수 구현에서 watchOS가 workout session을 요구하는 경우, 앱 내부 운동 기록과 Apple Health 저장은 분리하고 HealthKit 저장/공유 권한을 최소화한다. 실제 저장이 불가피한 API 경로가 확인되면 MVP에서는 “현재/최근 심박수 읽기”로 폴백한다.
- 레퍼런스 이미지에 `식단` 탭과 `PRO` 잠금이 보이지만, simfit-memo MVP는 운동 기록 앱으로 유지한다. 식단 기능과 유료 잠금은 구현하지 않는다.
- 운동 선택의 부위 카테고리는 `전체`, `하체`, `가슴`, `등`, `어깨`, `팔`, `복근`을 기본으로 시작한다. seed 운동 데이터에 bodyPart/category를 포함한다.
- Free Exercise DB는 한국어 이름을 제공하지 않으므로 MVP seed에는 원본 영문명과 앱 표시용 한국어명을 분리한다. 한국어명이 준비되지 않은 운동은 영문명을 fallback으로 표시할 수 있다.
- Free Exercise DB의 `primaryMuscles`/`secondaryMuscles`를 앱의 큰 부위(`하체`, `가슴`, `등`, `어깨`, `팔`, `복근`)로 매핑한다. 매핑이 애매한 운동은 `기타` 또는 원본 category를 보존한다.
- 디자인은 iPhone 1179x2556 레퍼런스 비율을 주 기준으로 삼되, Dynamic Type, 작은 iPhone, safe area, landscape 미지원 또는 제한을 고려한다.

## Reference UI Notes

- 홈/오늘 화면 (`IMG_9666.PNG`):
  - 월/날짜 strip이 상단에 있고, `운동 기록`이 주 tab으로 강조된다.
  - 오늘 날짜 card에서 운동 계획을 바로 시작할 수 있으며, `불러오기`와 `운동 선택하기`가 같은 row에 배치된다.
  - `루틴 탐색`, `내 루틴`은 큰 rectangular action tile로 배치되고, `전체 휴식`은 secondary action처럼 보인다.
- 루틴 목록 (`IMG_9667.PNG`):
  - top bar는 back, centered title, plus action으로 구성된다.
  - 상단 blue banner가 빠른 시작/탐색 CTA 역할을 한다.
  - routine card는 어두운 surface 위에 루틴명, 부위 summary, 최근 수행일/수행 정보 없음, 완료 횟수 badge, overflow menu를 담는다.
- 루틴 상세 (`IMG_9668.PNG`):
  - 루틴 목록 위로 large rounded bottom sheet가 올라오며, 배경은 dim 처리된다.
  - sheet에는 drag handle, 루틴명, 편집 action, 운동 목록, 하단 `운동 시작하기` primary CTA가 있다.
  - 운동 row는 MVP에서 썸네일 없이 blue index, 운동명, 부위/세트/총량 summary, expand chevron으로 구성된다.
- 새 루틴 생성 (`IMG_9669.PNG`):
  - centered title과 back button이 있는 단순한 입력 화면이다.
  - prompt, outlined text field, 하단 `이전 기록 보기` outline button + `운동 선택하기` primary button 흐름을 따른다.
- 운동 선택 (`IMG_9670.PNG`):
  - 검색창, category chip row, `북마크만 보기`, sort dropdown, checkbox list, 운동명/부위/장비, bookmark/info action이 핵심이다.
  - 하단에는 safe-area 고정 action bar가 있고, 왼쪽 `+`는 커스텀 운동 추가, 오른쪽 CTA는 선택 상태에 따라 disabled/primary로 바뀐다.

## Scope

### In Scope

- iOS 앱 프로젝트와 watchOS 앱 타깃 생성.
- SwiftUI 기반 iPhone UI:
  - 레퍼런스 이미지와 같은 dark-first design system.
  - 오늘/운동 기록 홈 화면.
  - 루틴 목록/생성/편집.
  - Free Exercise DB 기반 운동 종목 목록, seed 데이터, 커스텀 운동 추가, 북마크, 운동 정보.
  - 운동 선택 검색/필터/정렬/고정 하단 CTA.
  - 루틴에서 운동 선택 및 세트별 목표 무게/횟수 입력.
  - 루틴 상세 바텀시트.
  - 루틴 또는 빈 운동으로 운동 시작.
  - 운동 중 운동 종목/세트 추가, 무게/횟수 입력, 세트 완료, 쉬는시간 타이머.
  - 완료된 운동 기록 저장과 기록 상세 조회.
- Watch 앱:
  - 현재 진행 중인 운동 조회.
  - 현재 운동 종목, 목표 무게/횟수, 세트 순서 표시.
  - 세트 완료 버튼.
  - 쉬는시간 타이머와 하단 현재 심박수 표시.
  - 동기화된 루틴 목록과 운동 기록 조회.
- iPhone-Watch 동기화:
  - 진행 중 운동 상태는 가능한 경우 즉시 메시지로 전달.
  - 루틴/기록 목록은 compact snapshot DTO로 백그라운드 전송 및 Watch 로컬 캐시에 저장.
  - Watch에서 완료한 세트 이벤트를 iPhone에 전달하고 충돌/중복 완료를 방지.
- HealthKit:
  - Watch 앱에서 심박수 읽기 권한 요청.
  - 권한 거부/데이터 없음 상태의 UI 처리.

### Out of Scope

- Apple Health에 workout 기록 저장.
- iCloud/CloudKit 기반 다기기 동기화.
- 식단 기록/영양 관리.
- 유료 구독, `PRO` 잠금, paywall.
- 소셜 기능, 코칭, 운동 추천, 자동 중량 증가 알고리즘.
- 운동 영상 콘텐츠.
- Watch에서 루틴 생성/편집.
- 계정, 서버 백엔드.
- 고급 통계, PR 분석, 그래프 대시보드.
- App Store 배포 메타데이터, 아이콘, 스크린샷 제작.
- 운동 자세 아이콘/썸네일/이미지 asset 제작, 다운로드, 번들링.

## Implementation Plan

1. 프로젝트 스캐폴딩을 만든다.
   - `Brewfile`에 `brew "xcodegen"`을 추가하고 `brew bundle`로 도구 설치를 재현 가능하게 만든다.
   - `project.yml`을 작성해 `SimfitMemo` iOS 앱 타깃과 `SimfitMemo Watch App` watchOS 타깃을 선언한다.
   - 공통 모델/DTO/서비스는 `Shared/` 또는 별도 Swift package로 분리하고 두 타깃에서 공유한다.
   - `xcodegen generate`로 `SimfitMemo.xcodeproj`를 생성한다.

2. iOS design system과 공통 컴포넌트를 먼저 만든다.
   - `DesignSystem/Theme.swift`에 color token, typography token, spacing token을 정의한다.
   - 기본 색상 방향:
     - app background: near-black charcoal.
     - surface/card/search field: dark slate.
     - border/divider/icon muted: blue-gray.
     - primary action/accent: vivid blue.
     - primary text: near-white.
     - secondary text: muted blue-gray.
   - 공통 컴포넌트:
     - `AppTopBar`: back, centered title, trailing action.
     - `PrimaryButton`, `OutlineButton`, disabled button state.
     - `SearchField`.
     - horizontal `CategoryChip`.
     - `ExerciseRow`.
     - `Checkbox`.
     - `RoutineCard`.
     - `StickyBottomActionBar`.
     - `BottomSheetHeader`.
   - 모든 주요 버튼은 44pt 이상 터치 영역과 safe-area padding을 확보한다.
   - 레퍼런스처럼 화면은 고밀도 정보 표시를 유지하되, 텍스트가 잘리거나 겹치지 않도록 Dynamic Type에서 최소한 `.large`까지 확인한다.

3. 도메인 모델을 설계한다.
   - `Exercise`: seed/custom 운동 종목.
   - `Exercise`는 `sourceID`, `name`, `localizedName`, `bodyPart`, `primaryMuscles`, `secondaryMuscles`, `equipment`, `category`, `instructions`, `isBookmarked`, `isCustom`, `createdAt`, `updatedAt`을 가진다.
   - MVP에서는 `thumbnailAssetName`이나 원격 이미지 URL을 필수 모델 필드로 두지 않는다. 향후 이미지 지원을 추가할 때 optional media 모델을 별도로 붙인다.
   - `Routine`: 루틴 이름, 정렬, 생성/수정 시각.
   - `RoutineExercise`: 루틴 내 운동 순서와 운동 참조.
   - `RoutineSetTarget`: 선택적 목표 무게, 목표 횟수, 쉬는시간.
   - `WorkoutSessionRecord`: 실제 운동 세션, 시작/종료 시각, source routine snapshot.
   - `WorkoutExerciseRecord`: 운동 세션 내 종목 snapshot.
   - `WorkoutSetRecord`: 목표값, 실제 입력값, 완료 시각, 쉬는시간.
   - `ActiveWorkoutState`: 현재 운동 진행 위치, 쉬는시간 종료 시각, 동기화 버전.
   - SwiftData 모델과 WatchConnectivity DTO를 분리한다. DTO는 `Codable`이며 Watch 전송에 적합한 compact 형태여야 한다.

4. seed 운동 목록과 커스텀 운동 기능을 구현한다.
   - `Shared/Seed/ExerciseSeed.json` 또는 Swift enum으로 기본 종목을 제공한다.
   - seed 원천은 Free Exercise DB 통합 JSON이며, importer가 원본 데이터를 앱 스키마로 변환한다.
   - 원본 URL은 `https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json`로 기록한다.
   - seed에는 원본 id, 영문 운동명, 한국어 표시명 또는 fallback 영문명, 부위, primary/secondary muscles, 장비, category, 난이도, 검색 키워드, instruction summary를 포함한다.
   - MVP seed는 `category == strength`를 우선 포함하고, 헬스장 웨이트 기록에 덜 맞는 stretching/cardio/plyometrics/strongman 항목은 기본 목록에서 제외하거나 낮은 우선순위로 둔다.
   - Free Exercise DB의 이미지 경로는 원본 추적용으로만 둘 수 있지만, MVP 앱 UI와 번들 asset에는 사용하지 않는다.
   - Free Exercise DB 라이선스가 `Unlicense`임을 `README.md`와 seed metadata에 기록한다.
   - 첫 실행 또는 seed 버전 변경 시 중복 없이 기본 종목을 삽입한다.
   - iOS에서 커스텀 운동 추가/이름 수정/비활성화/북마크 토글 기능을 제공한다.
   - 운동 상세 정보 화면은 초기에는 이름, 부위, 장비, 메모, 사용된 기록 요약 정도로 시작한다.

5. iOS 홈/오늘 운동 기록 화면을 구현한다.
   - 상단은 월 표시, 날짜 strip, 달력/메뉴 아이콘으로 구성한다.
   - 주 화면은 `운동 기록`을 기본 tab으로 둔다. `식단`은 MVP에서 숨기거나 비활성 표시 없이 제외한다.
   - 오늘 날짜 card에는 “운동을 직접 계획해보세요!” 문구와 `불러오기`, `운동 선택하기` 버튼을 둔다.
   - 하단 quick actions로 `루틴 탐색`, `내 루틴`, `전체 휴식`을 배치한다.
   - 이전 운동 기록이 있는 날에는 운동 summary card를 보여줄 수 있게 모델과 UI를 열어둔다.

6. iOS 루틴 생성 플로우를 구현한다.
   - 루틴 목록 화면을 만든다.
   - 루틴 목록 화면은 top bar(`루틴`, back, plus), blue banner CTA, 전체 개수, sort dropdown, routine card list로 구성한다.
   - 새 루틴 화면은 centered title(`새로운 루틴 만들기`), prompt, outlined routine name text field, bottom two-button layout(`이전 기록 보기`, `운동 선택하기`)을 따른다.
   - 루틴 생성/편집 화면에서 운동 목록 검색/필터/선택을 제공한다.
   - 선택된 운동별로 세트 목표를 추가할 수 있게 한다.
   - 종목만 입력해도 저장 가능해야 하며, 목표 무게/횟수는 비워둘 수 있어야 한다.

7. iOS 운동 선택 화면을 구현한다.
   - 상단 back button 아래 검색창을 둔다.
   - category chip row는 bookmark shortcut, `전체`, 부위별 chip을 horizontal scroll로 제공한다.
   - `북마크만 보기` checkbox와 sort dropdown(`기본순`, `이름순`, `최근 사용순`)을 제공한다.
   - 운동 row는 checkbox, name, bodyPart/equipment summary, bookmark button, info button을 포함한다.
   - 선택 개수 0개일 때 bottom CTA는 disabled 상태로 “운동을 선택해주세요”를 표시한다.
   - 선택 개수 1개 이상일 때 bottom CTA는 primary 상태로 바뀌고 선택한 운동 수를 표시한다.
   - 왼쪽 bottom `+` 버튼은 커스텀 운동 추가로 연결한다.

8. iOS 루틴 상세 바텀시트를 구현한다.
   - 루틴 card tap 시 rounded large bottom sheet를 연다.
   - sheet 상단은 drag handle, 루틴명, `편집` action으로 구성한다.
   - 운동 목록은 blue index, 운동명, 부위/세트수/총 볼륨 또는 총 횟수, expand chevron을 표시한다.
   - 하단에는 safe-area 고정 `운동 시작하기` primary button을 둔다.

9. iOS 운동 시작 및 운동 메모 플로우를 구현한다.
   - 시작 화면에서 루틴 선택 또는 빈 운동 시작을 제공한다.
   - 루틴 기반 시작 시 루틴의 운동/세트 목표를 active workout에 prefill한다.
   - 빈 운동 시작 시 운동 중 종목과 세트를 자유롭게 추가할 수 있게 한다.
   - 세트 row는 운동 종목, 목표 무게/횟수, 실제 무게/횟수, 완료 버튼을 가진다.
   - 완료 버튼을 누르면 완료 시각을 저장하고 해당 세트의 쉬는시간 타이머를 시작한다.
   - 운동 종료 시 `WorkoutSessionRecord`로 저장하고 history에 표시한다.

10. 쉬는시간 타이머와 상태 관리를 구현한다.
   - 타이머는 `restEndAt` 기반으로 계산해 앱이 background/foreground를 오가도 남은 시간이 자연스럽게 복구되게 한다.
   - iOS와 Watch 모두 같은 active state snapshot을 사용한다.
   - 완료 이벤트는 idempotent하게 처리한다. 같은 set id 완료 이벤트가 중복 도착해도 기록이 두 번 바뀌지 않아야 한다.

11. WatchConnectivity 동기화 레이어를 구현한다.
   - `WatchSyncService`를 iOS와 watchOS 양쪽에 둔다.
   - active workout state는 `sendMessage`를 우선 사용하고 실패 시 `updateApplicationContext` 또는 `transferUserInfo`로 폴백한다.
   - 루틴/운동 기록은 `RoutineSnapshot`, `WorkoutHistorySnapshot` 형태로 compact 전송한다.
   - Watch 쪽에는 snapshot cache 저장소를 둔다.
   - schema/version 필드를 DTO에 넣어 향후 마이그레이션을 대비한다.

12. Watch 앱 UI를 구현한다.
   - `NavigationStack` 기반으로 `현재 운동`, `루틴`, `기록` 진입점을 제공한다.
   - 현재 운동 화면은 운동 종목명, 현재 세트 번호, 목표 무게/횟수, 완료 버튼을 크게 표시한다.
   - 쉬는시간 중에는 남은 시간을 크게 표시하고 하단에 심박수 값을 표시한다.
   - 연결 끊김, 동기화 대기, 권한 없음, 심박수 없음 상태를 명확하게 표시한다.

13. Watch HealthKit 심박수 서비스를 구현한다.
   - Watch 타깃에 HealthKit capability와 `NSHealthShareUsageDescription`을 추가한다.
   - `HKHealthStore`로 `heartRate` 읽기 권한을 요청한다.
   - 권한이 있으면 운동 중 또는 쉬는시간 중 현재/최근 심박수를 표시한다.
   - 권한 거부, 센서 데이터 없음, 시뮬레이터 환경에서는 placeholder 상태를 표시한다.
   - 구현 중 live cadence가 부족하면 `HKWorkoutSession`/`HKLiveWorkoutBuilder` 사용 가능성을 검토하되, Apple Health workout 저장은 MVP 요구사항이 아니므로 저장하지 않는 경로를 우선한다.

14. 테스트와 QA를 추가한다.
    - 모델/DTO encoding-decoding 테스트.
    - 루틴 prefill 테스트.
    - 세트 완료 idempotency 테스트.
    - rest timer 계산 테스트.
    - Watch event queue/retry 테스트.
    - iOS 주요 화면 UI smoke test.
    - iOS 주요 화면 screenshot/snapshot 또는 수동 visual QA.
    - 실제 페어링된 iPhone + Apple Watch에서 WatchConnectivity와 심박수 수동 QA.

## Files and Areas to Inspect or Change

현재는 생성된 앱 코드가 없으므로 구현 시 아래 구조를 만들거나, Xcode 템플릿 생성 결과에 맞춰 같은 책임 경계를 유지한다.

- `Brewfile`
- `project.yml`
- `SimfitMemo.xcodeproj/`
- `SimfitMemo/`
  - `SimfitMemoApp.swift`
  - `DesignSystem/Theme.swift`
  - `DesignSystem/Components/`
  - `Views/Home/`
  - `Views/Routines/`
  - `Views/ExerciseSelection/`
  - `Views/Workout/`
  - `Views/History/`
  - `Views/Settings/`
  - `Stores/`
  - `Services/WatchSyncService.swift`
- `SimfitMemoWatch Watch App/`
  - `SimfitMemoWatchApp.swift`
  - `Views/CurrentWorkoutView.swift`
  - `Views/RestTimerView.swift`
  - `Views/RoutineListView.swift`
  - `Views/HistoryListView.swift`
  - `Services/WatchSyncService.swift`
  - `Services/HealthKitHeartRateService.swift`
- `Shared/`
  - `Models/Exercise.swift`
  - `Models/Routine.swift`
  - `Models/WorkoutSessionRecord.swift`
  - `Models/ActiveWorkoutState.swift`
  - `Models/BodyPart.swift`
  - `DTO/WatchSyncDTOs.swift`
  - `Seed/ExerciseSeed.json`
  - `Seed/ExerciseSeedSourceMetadata.json`
  - `Seed/FreeExerciseDBImporter.swift` 또는 repo 외부 generation script
  - `Stores/ExerciseSeedService.swift`
  - `Utilities/RestTimerCalculator.swift`
- `SimfitMemoTests/`
  - model, prefill, timer, sync DTO tests.
- `SimfitMemoUITests/`
  - iOS smoke tests for routine creation and active workout.
- `README.md`
  - build commands, HealthKit/WatchConnectivity test notes, simulator limitations.

## Acceptance Criteria

- iOS 앱은 레퍼런스 이미지와 같은 dark-first visual language를 따른다: charcoal background, slate cards, vivid blue primary actions, blue-gray secondary text/icons/dividers.
- 홈 화면에서 오늘 날짜와 운동 기록 중심 CTA가 보이며, 사용자는 `불러오기`, `운동 선택하기`, `루틴 탐색`, `내 루틴` 흐름으로 이동할 수 있다.
- iOS 앱 첫 실행 시 Free Exercise DB 기반 기본 운동 목록이 보이고, 사용자는 커스텀 운동을 추가할 수 있다.
- 기본 운동 seed metadata에 Free Exercise DB 원본 URL, 가져온 날짜, 라이선스(`Unlicense`)가 기록되어 있다.
- 운동 선택 화면은 검색, 부위별 chip filter, 북마크 필터, 정렬, row checkbox, 운동명/부위/장비 summary, bookmark/info button, 고정 하단 CTA를 제공한다.
- 사용자는 운동 종목을 선택해 루틴을 만들 수 있으며, 각 종목에 선택적으로 세트별 목표 무게와 목표 횟수를 입력할 수 있다.
- 목표 무게/횟수가 비어 있어도 루틴 저장과 운동 시작이 가능하다.
- 루틴 목록은 카드 UI로 루틴명, 부위 요약, 최근 수행 정보 또는 수행 정보 없음, 완료 횟수 badge, overflow menu를 표시한다.
- 루틴 상세는 rounded large bottom sheet로 표시되며 운동별 순번, 운동명, 부위, 세트 수, 총 볼륨/횟수 summary를 보여준다.
- 사용자는 루틴 또는 빈 운동으로 새 운동을 시작할 수 있다.
- 루틴으로 시작한 운동은 루틴의 종목과 세트 목표가 자동으로 채워진다.
- 운동 중 사용자는 종목, 세트, 무게, 횟수를 기록할 수 있다.
- 세트 완료 버튼을 누르면 해당 세트가 완료 처리되고 쉬는시간 타이머가 시작된다.
- 운동 종료 후 기록 목록과 상세 화면에서 완료된 운동을 볼 수 있다.
- Watch 앱은 동기화된 루틴과 운동 기록을 조회할 수 있다.
- Watch 앱은 진행 중인 운동의 현재 종목, 현재 세트, 목표 무게/횟수, 완료 버튼을 표시한다.
- Watch에서 완료 버튼을 누르면 iPhone의 active workout state가 갱신되고, 중복 탭으로 같은 세트가 중복 완료되지 않는다.
- 쉬는시간 중 Watch 앱은 남은 시간과 현재 또는 최근 심박수를 표시한다.
- HealthKit 심박수 권한이 없거나 데이터가 없을 때 앱이 크래시하지 않고 대체 상태를 표시한다.
- iPhone-Watch 연결이 일시적으로 끊겨도 Watch는 마지막 동기화 캐시를 조회할 수 있고, 재연결 시 상태가 회복된다.
- 레퍼런스에 보이는 `식단`, `PRO`, paywall 요소는 MVP UI에 노출되지 않는다.

## Validation Plan

- 프로젝트/스킴 확인:
  - `brew bundle`
  - `xcodegen generate`
  - `xcodebuild -list -project SimfitMemo.xcodeproj`
- iOS 빌드:
  - `xcodebuild -project SimfitMemo.xcodeproj -scheme SimfitMemo -destination 'generic/platform=iOS Simulator' build`
- watchOS 빌드:
  - `xcodebuild -project SimfitMemo.xcodeproj -scheme 'SimfitMemo Watch App' -destination 'generic/platform=watchOS Simulator' build`
- 테스트:
  - 사용 가능한 destination 확인: `xcodebuild -showdestinations -project SimfitMemo.xcodeproj -scheme SimfitMemo`
  - 확인된 iOS Simulator destination으로 `xcodebuild -project SimfitMemo.xcodeproj -scheme SimfitMemo -destination '<available iOS simulator destination>' test`
- 수동 iOS QA:
  - 홈 화면이 `/Users/jmsim/Downloads/IMG_9666.PNG`의 정보 구조와 dark-first 톤을 따른다.
  - 루틴 목록이 `/Users/jmsim/Downloads/IMG_9667.PNG`처럼 카드 중심으로 보이며 `PRO` lock은 없다.
  - 루틴 상세가 `/Users/jmsim/Downloads/IMG_9668.PNG`처럼 large rounded bottom sheet로 열린다.
  - 새 루틴 화면이 `/Users/jmsim/Downloads/IMG_9669.PNG`처럼 이름 입력과 하단 two-button action을 제공한다.
  - 운동 선택 화면이 `/Users/jmsim/Downloads/IMG_9670.PNG`처럼 검색, chip, checkbox row, 고정 하단 CTA를 제공한다.
  - 작은 iPhone과 큰 iPhone simulator에서 텍스트 겹침, CTA safe-area 침범, chip row clipping이 없는지 확인.
  - 기본 운동 seed 확인.
  - 커스텀 운동 추가.
  - 루틴 생성, 목표 세트 입력/미입력 케이스 저장.
  - 루틴 기반 운동 시작과 빈 운동 시작.
  - 세트 추가, 세트 완료, 쉬는시간 타이머, 운동 종료, 기록 조회.
- 수동 Watch QA:
  - 실제 페어링된 iPhone + Apple Watch에서 active workout 동기화.
  - Watch 완료 버튼이 iPhone 기록에 반영되는지 확인.
  - 연결 끊김/재연결 시 상태 복구 확인.
  - HealthKit 심박수 권한 허용/거부 각각 확인.
  - 쉬는시간 중 심박수 표시 확인.

## Risks and Mitigations

- 레퍼런스 앱을 지나치게 그대로 복제하면 차별성과 저작권/브랜드 리스크가 생긴다.
  - Mitigation: 정보 구조와 사용감만 참고하고, simfit-memo의 색상 token, spacing, copy, icon treatment, asset을 자체 정의한다.
- 운동 자세 이미지/아이콘은 저작권, 일관성, 앱 용량 리스크가 있다.
  - Mitigation: MVP에서는 운동 자세 아이콘/썸네일을 제외하고 텍스트 중심 UI로 구현한다. 향후 이미지 지원을 추가할 때 라이선스가 명확한 asset만 별도 source metadata와 함께 도입한다.
- Free Exercise DB 원본 데이터는 영문 중심이고 일부 필드가 null일 수 있다.
  - Mitigation: importer에서 null-safe 변환, 한국어 표시명 fallback, muscle-to-bodyPart 매핑 테이블, 제외 category 규칙을 테스트한다.
- 어두운 고밀도 UI는 작은 화면과 Dynamic Type에서 가독성이 무너질 수 있다.
  - Mitigation: 주요 row/card/button에 stable height와 responsive layout을 두고 작은 iPhone simulator와 Dynamic Type `.large` 이상에서 수동 QA한다.
- 고정 하단 CTA는 safe area, 키보드, 스크롤 콘텐츠와 충돌하기 쉽다.
  - Mitigation: SwiftUI `safeAreaInset(edge: .bottom)` 패턴을 기본으로 쓰고, 키보드가 뜨는 루틴 이름 입력 화면에서는 CTA가 입력 필드를 가리지 않게 한다.
- `WatchConnectivity`는 즉시성과 백그라운드 전달 보장이 상황에 따라 다르다.
  - Mitigation: 현재 운동 제어는 `sendMessage`를 우선 사용하고, 실패 시 application context/background transfer와 로컬 이벤트 큐로 보완한다.
- Watch에서 “전체 기록 조회”는 데이터가 커지면 전송량과 UI 성능 문제가 생길 수 있다.
  - Mitigation: history snapshot은 목록용 summary와 detail을 분리하고, 초기는 전체를 보내되 DTO versioning과 pagination 여지를 둔다.
- 심박수는 시뮬레이터에서 실제 검증이 어렵고, 권한/센서/착용 상태에 따라 값이 없을 수 있다.
  - Mitigation: 실제 Apple Watch QA를 acceptance에 포함하고, 권한 없음/데이터 없음 UI를 필수로 구현한다.
- `HKWorkoutSession`을 사용해야 live heart rate cadence가 충분할 수 있다.
  - Mitigation: HealthKit workout 저장은 MVP 밖이므로, 읽기 권한 기반 최신 심박수 표시를 먼저 구현하고 필요할 때 저장 없는 session 경로를 검토한다.
- SwiftData 모델 변경은 앱 출시 후 migration 이슈가 생길 수 있다.
  - Mitigation: 초기 모델에 stable UUID, snapshot 필드, DTO version을 포함하고, 출시 전 schema를 한 번 정리한다.
- `XcodeGen` 도입으로 로컬 도구 설치가 필요하다.
  - Mitigation: `Brewfile`에 도구를 고정하고 `README.md`에 `brew bundle`, `xcodegen generate`, `xcodebuild` 순서를 남긴다.

## Open Questions

구현을 시작하는 데 필요한 제품 결정은 현재 없다. 다만 아래는 구현 중 낮은 위험의 세부 결정으로 처리해도 된다.

- 기본 운동 seed 목록의 정확한 종목 수, 제외 category, 한국어 운동명 매핑 범위.
- 기본 쉬는시간 값. 현재 계획은 90초를 가정한다.
- 앱 아이콘.
- 운동 자세 아이콘/썸네일은 MVP 이후에 다시 결정한다.
- Watch에서 기록 상세를 어디까지 압축해서 보여줄지.

## Dispatch Progress - 2026-05-27

- `main`에 XcodeGen 기반 iOS/watchOS 프로젝트 스캐폴딩, shared Codable 모델/DTO, Free Exercise DB seed importer, active workout domain, dark-first iOS UI shell, WatchConnectivity/HealthKit watch shell을 통합했다.
- 서브 작업은 foundation, iOS UI, seed importer, workout core, watch sync로 나눠 진행했다. workout core와 watch sync worker는 중간에 agent limit로 종료됐지만, 남아 있던 커밋/변경을 main에 통합했다.
- 현재 구현은 제품 골격과 compile 가능한 MVP shell 단계다. SwiftData 영속화, 실제 루틴 생성/편집 저장 흐름, 홈/루틴/운동 메모 간 상태 연결, 실제 페어링 기기 Watch QA는 아직 남아 있다.
- 검증 결과:
  - `xcodegen generate` 통과.
  - `xcodebuild -project SimfitMemo.xcodeproj -scheme SimfitMemoUnitTests -destination 'platform=iOS Simulator,name=iPhone 17' test` 통과, 22 tests.
  - `xcodebuild -project SimfitMemo.xcodeproj -target SimfitMemo -sdk iphonesimulator build` 통과.
  - `xcodebuild -project SimfitMemo.xcodeproj -target 'SimfitMemo Watch App' -destination 'generic/platform=watchOS Simulator' build` 통과.

## Implementation Progress - 2026-05-27

- iOS 앱에 `SwiftData` 기반 snapshot 저장소를 추가했다. 운동 목록, 루틴, 완료 기록, 진행 중 운동 상태를 Codable snapshot으로 저장하고 앱 시작 시 복구한다.
- 홈/루틴 목록/루틴 상세/운동 선택/운동 메모 화면을 `AppDataStore`로 연결했다. 운동 선택에서 바로 운동을 시작할 수 있고, 루틴 생성 플로우에서 선택한 운동으로 루틴을 저장할 수 있으며, 루틴 상세에서 운동 메모로 진입한다.
- 운동 메모 화면은 샘플 전용 상태 대신 앱 전체 active workout state를 편집한다. 세트 실제 무게/횟수 입력, 세트 완료, 쉬는시간 타이머, 운동 종료 후 기록 저장이 같은 store에 반영된다.
- 루틴에 세트 목표가 없어도 운동 시작 시 빈 세트 1개를 자동 생성하도록 도메인 규칙을 보강했다.
- 검증 결과:
  - `xcodegen generate` 통과.
  - `xcodebuild -project SimfitMemo.xcodeproj -scheme SimfitMemoUnitTests -destination 'platform=iOS Simulator,name=iPhone 17' test` 통과, 23 tests.
  - `xcodebuild -project SimfitMemo.xcodeproj -target SimfitMemo -sdk iphonesimulator build` 통과.
  - `xcodebuild -project SimfitMemo.xcodeproj -target 'SimfitMemo Watch App' -destination 'generic/platform=watchOS Simulator' build` 통과.
- 아직 남은 구현은 루틴별 세트 목표 편집 UI, 기록 상세 화면, WatchConnectivity와 iOS store의 실시간 연결, 실제 페어링된 Apple Watch QA다.
