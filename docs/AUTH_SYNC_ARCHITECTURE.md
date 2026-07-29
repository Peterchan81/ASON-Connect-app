# ASON Core ↔ ASON Connect 인증 아키텍처 (Phase 1.5)

이 문서는 두 앱이 Supabase Auth를 공통 인증으로 채택하기 위한 설계
원칙을 정리합니다. **Phase 1.5에서는 문서만 작성하며, 로그인 관련
코드는 아직 수정하지 않습니다.** 실제 구현은 Phase 2A입니다.

같은 파일이 `ASON_Connect_app/docs/AUTH_SYNC_ARCHITECTURE.md`에도
동일하게 있습니다. 내용이 바뀌면 두 파일을 함께 수정하세요.
데이터 테이블 설계는 `docs/CORE_CONNECT_SHARED_SCHEMA.md`를 참고하세요.

## 1. Supabase Auth를 공통 인증으로 선택한 이유

- Core는 이미 `supabase_flutter`가 설치되어 있고 OAuth(구글/카카오) 로그인
  코드(`lib/services/supabase_auth_service.dart`)와 `profiles` 테이블 +
  신규 사용자 자동 생성 트리거(`supabase/migrations/0001_profiles.sql`)가
  이미 존재합니다 — 처음부터 새로 만드는 것보다 이 기반을 확장하는 편이
  작업량이 적습니다.
- `schedules`/`daily_goals`/`diary_entries`/`memos` 4개 테이블(Phase 1)의
  RLS가 `auth.uid() = user_id`를 전제로 설계되어 있어, 두 앱이 같은
  Supabase 프로젝트의 Auth를 쓰지 않으면 이 RLS 자체가 무의미해집니다.
- 두 앱이 각자 다른 인증 시스템을 유지하면서 데이터만 공유하려면 별도의
  "사용자 매핑 테이블"이 필요해지는데, 이는 새로운 인프라를 추가하는
  것이라 "불필요한 신규 기능 금지" 원칙에 어긋납니다. Supabase Auth
  하나로 통일하는 쪽이 더 단순합니다.

## 2. Core와 Connect가 동일 user_id를 사용하는 구조

두 앱 간에 세션을 직접 공유(SSO)하지 않습니다 — 별도 앱이라 실기기에서
세션 저장소가 분리되어 있기 때문입니다(Phase 1 조사에서 확인한 사실과
동일한 이유). 대신:

- 두 앱은 **같은 Supabase 프로젝트**(같은 `SUPABASE_URL`/`SUPABASE_ANON_KEY`,
  각자의 `.env`에 동일한 값)를 가리킵니다.
- 사용자가 각 앱에서 **같은 이메일/OAuth 계정**으로 각각 로그인하면,
  Supabase는 같은 `auth.users` 행을 반환하므로 `auth.uid()`가 두 앱에서
  동일해집니다.
- 즉 "동일 user_id"는 세션 공유가 아니라 **같은 백엔드의 같은 계정에
  각자 독립적으로 로그인**해서 얻는 결과입니다. 이 방식은 기존 로그인
  화면 구조(Core/Connect 각자 자기 로그인 화면 보유)를 그대로 유지할 수
  있어 화면 재설계가 필요 없습니다.

## 3. 회원가입 흐름 (Phase 2A 설계안)

1. 사용자가 Core 또는 Connect의 회원가입 화면에서 이메일/비밀번호(또는
   기존처럼 구글/카카오)를 입력.
2. `Supabase.instance.client.auth.signUp(...)` 또는
   `signInWithOAuth(...)` 호출 → `auth.users`에 새 행 생성.
3. Core의 기존 트리거 `handle_new_user()`(0001_profiles.sql)가 그대로
   작동해 `profiles` 행을 자동 생성 — **새 코드 불필요, 기존 메커니즘
   재사용**.
4. 세션은 `supabase_flutter`가 자체적으로 로컬에 영속화(추가 구현 불필요).

## 4. 로그인 흐름 (Phase 2A 설계안)

- 이메일/비밀번호: `signInWithPassword(email, password)`.
- OAuth(구글/카카오): Core는 `SupabaseAuthService.signInWithGoogle/Kakao`
  가 이미 존재 → 그대로 재사용. Connect는 Phase 2A에서 동등한 서비스를
  새로 추가해야 함(현재 없음).
- 로그인 성공 후 이후의 모든 Supabase 쿼리는 자동으로 `auth.uid()`를
  포함하므로, RLS가 본인 데이터만 반환/허용.
- **이메일/비밀번호 vs OAuth 선택은 Phase 2A 착수 시 결정** — 문서 작성
  시점에는 두 경로 모두 기술적으로 가능하다는 점만 기록해 둔다.

## 5. 자동 로그인 및 세션 복원

`supabase_flutter`는 앱 시작 시 저장된 refresh token으로 세션을 자동
복원하고, `auth.onAuthStateChange` 스트림으로 상태 변화를 알려줍니다
(Core의 `SupabaseAuthService.authStateChanges`가 이미 이 스트림을 노출).

**전환기 주의사항**: 지금은 두 앱 모두 "기존 로컬 로그인 상태"
(`AuthService.isLoggedIn` 등, SharedPreferences 플래그)와 "Supabase 세션
상태"가 서로 다른 것을 가리킬 수 있습니다(Core는 이미 이 둘을 완전히
분리해서 관리 중 — `supabase_auth_service.dart` 주석 참고). Phase 2A는
두 상태를 어떻게 조합해 "로그인됨"으로 판단할지 규칙을 정해야 합니다
(예: Supabase 세션이 있으면 우선, 없으면 기존 로컬 로그인으로 폴백).
이 규칙 자체는 Phase 2A의 설계 작업이며 이 문서에서는 확정하지 않습니다.

## 6. 로그아웃 흐름

`auth.signOut()`으로 Supabase 세션 종료 + 기존 로컬 `AuthService`의
로그인 플래그도 함께 초기화(두 시스템을 당분간 병행 운영하므로 한쪽만
지우면 상태 불일치 발생). Core의 `SupabaseAuthService.signOutAi()`는
"AI 로그인만 로그아웃"하는 현재 개념과는 다른, 더 넓은 의미의 로그아웃이
될 것이므로 Phase 2A에서 두 메서드의 관계를 재정의해야 합니다.

## 7. 비밀번호 재설정

`auth.resetPasswordForEmail(email)` → 사용자가 이메일 링크 클릭 →
딥링크로 앱 복귀 → `auth.updateUser(password: 새비밀번호)`. Connect의
Phase 1 `pubspec.yaml`에 `supabase_flutter`의 전이 의존성으로
`app_links`가 이미 포함되어 있어(Phase 1 완료 보고 참고), 딥링크 수신
인프라는 추가 패키지 없이 활용 가능합니다.

## 8. 기존 로컬 계정 데이터 처리 방안 (확정 사항 4, 5 반영)

- **삭제하지 않습니다.** Core의 `AuthService`(SharedPreferences:
  `isRegistered`/`isLoggedIn`/`userId`/`userName`/`userEmail`/...)와
  Connect의 `AuthService`(`ason_accounts` JSON, SHA-256 해시)는 Phase 2A
  이후에도 데이터 자체는 그대로 남깁니다.
- 신규 Supabase 로그인이 도입되면, 로컬 계정과 Supabase 계정은 당분간
  **독립적으로 공존**합니다 — 로컬 계정으로도 여전히 로그인할 수 있게
  유지하되(하위 호환), Core/Connect 각 화면에 "Supabase 계정 연결"
  유도 동선을 추가하는 것을 원칙으로 제안합니다(구현은 Phase 2A 범위).
- 이메일이 있는 기존 로컬 계정은 같은 이메일로 Supabase 회원가입 시
  자연스럽게 매칭됩니다. 이메일이 없는(아이디만 있는) 로컬 계정은 강제
  전환하지 않고, 사용자가 원할 때 수동으로 Supabase 계정을 만들어 연결하는
  방식을 기본 원칙으로 제안합니다.

## 9. 로컬 SharedPreferences 데이터의 Supabase 이전 방안

- **인증 데이터**: 8번과 동일 — 자동 일괄 이전 없음, 계정 연결 시점에만
  처리.
- **실 데이터**(schedules/daily_goals/diary_entries/memos): 사용자가
  Supabase 계정에 처음 연결되는 시점에, 그 시점까지 로컬에 쌓인 데이터를
  1회성으로 Supabase에 업로드하는 "초기 동기화"가 필요합니다. 이 로직은
  Phase 2B/2C 범위이며, 이 문서에서는 다음 원칙만 못박습니다:
  - 로컬 데이터는 초기 동기화 이후에도 **즉시 삭제하지 않는다**
    (Supabase 쓰기 실패 시 데이터 유실 방지).
  - 이미 Phase 1에서 설계된 `source_app`/`sync_version` 컬럼을 사용해
    "이 행이 로컬에서 올라온 초기 이전 데이터"임을 구분 가능하게 한다.

## 10. 오프라인일 때의 동작

- Core/Connect 모두 지금처럼 SharedPreferences를 1차 저장소로 계속
  사용합니다(오프라인 우선 원칙 유지, 화면 동작 변경 없음).
- Supabase 호출이 실패(네트워크 없음/세션 없음)하면 조용히 로컬 폴백—
  이미 Core의 `_initSupabase()`/`SupabaseAuthService.isAvailable`이
  이 철학으로 구현되어 있고, Connect의 Phase 1 초기화도 동일하게
  맞춰뒀습니다.
- 재연결 시 로컬과 서버 데이터를 어떻게 합칠지(마지막 수정 시각 비교 등,
  `updated_at`/`sync_version` 활용)는 Phase 2D의 설계 범위입니다.

## 11. RLS와 user_id의 관계

`schedules`/`daily_goals`/`diary_entries`/`memos` 4개 테이블은 모두
`using (auth.uid() = user_id)` / `with check (auth.uid() = user_id)`
정책을 가지고 있습니다(`supabase/migrations/0003~0006`). 이는:

- 로그인하지 않은 요청(세션 없음, `auth.uid()`가 null)은 어떤 행도
  조회/추가/수정/삭제할 수 없다는 뜻입니다.
- 로그인한 사용자는 오직 `user_id` 컬럼이 자신의 `auth.uid()`와 일치하는
  행만 볼 수 있습니다 — 서버(Postgres) 단에서 매 쿼리마다 강제되므로,
  클라이언트 코드에 버그가 있어도 다른 사용자 데이터가 새어나가지
  않습니다.
- 따라서 RLS가 실제로 의미를 가지려면 앱이 반드시 유효한 Supabase 세션을
  가지고 있어야 합니다 — 이것이 이 문서 2번 항목("동일 user_id")과 직접
  연결되는 이유입니다.

## 12. anon key와 service_role key의 차이

| | anon key | service_role key |
|---|---|---|
| 용도 | 클라이언트(Flutter 앱)에 배포 | 서버/Edge Function 전용 |
| RLS | **적용됨** — 정책을 통과해야 접근 가능 | **완전히 우회** — 모든 행에 무제한 접근 |
| 노출 | `.env`/앱 번들에 포함되어도 안전(공개 키 취급, 단 RLS가 항상 켜져 있어야 함) | 노출 시 전체 데이터베이스가 무방비 상태가 됨 |
| 현재 사용처 | Core/Connect 각각의 `.env`(`SUPABASE_ANON_KEY`) | Core의 `supabase/functions/ai-chat` 같은 Edge Function 전용(서버 비밀 환경변수로만 관리) |

## 13. service_role key를 앱에 절대 포함하지 않는 원칙 (확정 사항 6)

- `.env`/`.env.example`/`pubspec.yaml`/Flutter 앱 코드 어디에도
  `SUPABASE_SERVICE_ROLE_KEY`(또는 동급의 관리자 키)를 넣지 않습니다.
  Core의 `.env.example` 주석에 이미 이 원칙이 명시되어 있고, Connect의
  `.env.example`(Phase 1에서 생성)도 동일한 두 항목(`SUPABASE_URL`,
  `SUPABASE_ANON_KEY`)만 가집니다.
- RLS를 끄거나(`disable row level security`) 우회하는 쿼리, 또는
  service_role 클라이언트를 Flutter 코드에서 생성하는 방식은 금지합니다
  (확정 사항 6). 관리자 권한이 필요한 작업(예: 향후 Developer App의
  feedback 상태 변경)은 Supabase Edge Function처럼 **서버 쪽에서만**
  service_role을 사용합니다 — `supabase/migrations/0002_feedback.sql`의
  주석에 이미 이 원칙이 반영되어 있습니다.
- 로그/보고서/커밋 메시지에 실제 anon key나 URL 등 값을 그대로 출력하지
  않습니다(Phase 1과 동일한 원칙 유지).
