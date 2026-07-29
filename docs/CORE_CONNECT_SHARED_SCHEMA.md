# ASON Core ↔ ASON Connect 공유 데이터 스키마 (Phase 1)

이 문서는 `feature/supabase-core-connect-sync` 브랜치에서 두 앱이 공유할
Supabase 테이블 구조를 정의합니다. **Phase 1에서는 테이블만 만들고, 실제
화면/저장 로직은 아직 이 테이블을 사용하지 않습니다.**

같은 파일이 `ASON_Connect_app/docs/CORE_CONNECT_SHARED_SCHEMA.md`에도
동일하게 있습니다(두 저장소를 각각 클론해도 바로 보이도록 복사본 유지).
스키마가 바뀌면 두 파일을 함께 수정하세요.

## 비교 기준

- **Core 쪽 실제 모델**: `lib/services/schedule_service.dart`(`HomeScheduleEntry`),
  `lib/services/goal_service.dart`(`HomeGoalEntry`),
  `lib/services/diary_note_service.dart`(날짜별 한 줄 노트),
  `lib/models/memo_model.dart`(`MemoModel`).
- **Connect 쪽 실제 모델**: `lib/features/core_sync/models/*` — 위 Core 모델을
  필드 단위로 그대로 복사해둔 것(주석에 "필드를 새로 만들지 않고 ASON-Core의
  정의를 그대로 따릅니다"라고 명시됨). 두 코드베이스의 모델은 이미 필드
  수준에서 일치합니다.
- **주의**: Core에는 `journal_screen.dart`(007 "나의 일기")가 쓰는 더 풍부한
  `DiaryEntry`(감정/기분/사진 등) 모델도 별도로 존재하지만, Connect의
  `DiaryCoreRepository`는 이 모델이 아니라 **날짜당 한 줄 노트**
  (`DiaryNoteService`)만 채웁니다. 아래 `diary_entries` 테이블은 Connect가
  실제로 만드는 것 기준이며, `journal_screen`의 감정/기분/사진 필드는
  이번 Phase에 포함하지 않습니다(불필요한 필드 추가 금지 원칙).

## 공통 메타 필드 (4개 테이블 공통)

| 필드 | 타입 | 설명 |
|---|---|---|
| `id` | `uuid` (PK) | 클라이언트가 로컬 `id`(String)를 그대로 넘겨 upsert 가능 |
| `user_id` | `uuid` (`auth.users` 참조) | 소유자. RLS 기준 |
| `source_app` | `text` | `'core'` \| `'connect'` — 어느 앱이 마지막으로 썼는지 |
| `is_deleted` | `boolean` | soft delete |
| `sync_version` | `integer` | 낙관적 동시수정 감지용 카운터 |
| `created_at` | `timestamptz` | |
| `updated_at` | `timestamptz` | |

## 1. schedules ← `HomeScheduleEntry`

| Dart 필드 | 컬럼 | 타입 | 비고 |
|---|---|---|---|
| `date`(맵 키) | `schedule_date` | `date` not null | |
| `time` | `time_text` | `text` | Core가 `"09:00"` 같은 문자열로 저장, 파싱 규칙 그대로 유지 |
| `title` | `title` | `text` not null | |
| `isDone` | `is_done` | `boolean` not null default false | |
| `memo` | `memo` | `text` (nullable) | |
| `alarmEnabled` | `alarm_enabled` | `boolean` not null default false | |

## 2. daily_goals ← `HomeGoalEntry`

| Dart 필드 | 컬럼 | 타입 | 비고 |
|---|---|---|---|
| `title` | `title` | `text` not null | |
| `isDone` | `is_done` | `boolean` not null default false | |
| *(모델엔 없음)* | `goal_date` | `date` not null default `current_date` | **추가된 필드.** `HomeGoalEntry` 자체엔 날짜가 없지만, `GoalService` 주석상 `todayGoals`는 "항상 오늘 하나만" 존재하는 날짜 스코프 개념입니다. 로컬의 단일 플랫 키를 여러 사용자의 여러 날짜가 섞이는 공유 테이블로 옮기려면 날짜 구분이 없으면 안 되므로, 기존 의미(오늘 목표 스냅샷)를 보존하기 위해 최소한으로 추가했습니다. **Phase 2 승인 전 확인 필요** — 자세한 내용은 저장소 루트 보고서의 "발견한 위험 요소" 참고. |

## 3. diary_entries ← `DiaryNoteService`(한 줄 노트)

| Dart 필드 | 컬럼 | 타입 | 비고 |
|---|---|---|---|
| 날짜(맵 키) | `entry_date` | `date` not null | |
| 노트 문자열 | `content` | `text` not null | |

날짜당 노트 1개(맵 구조)이므로 `unique (user_id, entry_date)`로 upsert
충돌 키를 잡습니다. **`journal_screen`의 감정/기분/사진 필드는 포함하지
않음** (위 "비교 기준" 참고).

## 4. memos ← `MemoModel`

| Dart 필드 | 컬럼 | 타입 | 비고 |
|---|---|---|---|
| `title` | `title` | `text` not null | |
| `content` | `content` | `text` not null | |
| `category` | `category` | `text` not null default `'기타'` | 기본값은 Connect가 실제로 채우는 값(`기타`/`아이디어`) 기준 |
| `tags` | `tags` | `text[]` not null default `'{}'` | |
| `isImportant` | `is_important` | `boolean` not null default false | |
| `alarmEnabled` | `alarm_enabled` | `boolean` not null default false | |
| `alarmDateTime` | `alarm_at` | `timestamptz` (nullable) | |
| `startDate` | `start_date` | `date` (nullable) | |
| `endDate` | `end_date` | `date` (nullable) | |
| `createdAt`/`updatedAt` | 공통 필드 사용 | | Dart의 `createdAt`/`updatedAt`을 공통 메타 필드로 그대로 매핑 |

## RLS 정책 요약

4개 테이블 모두 동일한 패턴(기존 `profiles` 마이그레이션과 동일):

```sql
using (auth.uid() = user_id)      -- select/update/delete
with check (auth.uid() = user_id) -- insert/update
```

`is_deleted = true`인 행도 select 정책에서 걸러내지 않습니다(소프트
삭제 동기화를 위해 클라이언트가 삭제된 행도 볼 수 있어야 다른 기기에
삭제를 반영할 수 있습니다) — 필터링은 앱 쪽 쿼리에서 합니다.

## ⚠️ Phase 2 이전에 확인이 필요한 전제

이 RLS 설계는 `auth.uid()`(Supabase Auth 세션)가 존재한다고 가정합니다.
하지만:

- **Core**는 로컬 SharedPreferences 기반 자체 로그인(`AuthService`)이 주
  로그인 경로이고, Supabase OAuth(구글/카카오)는 AI 기능 전용 **별도
  선택 로그인**입니다. `supabase/migrations/0002_feedback.sql`의 주석도
  "ASON 기본 로그인만 한 사용자는 (Supabase) user_id가 null일 수 있다"고
  명시합니다.
- **Connect**는 Supabase 자체가 없고, `crypto`(SHA-256) 기반 완전 로컬
  인증만 있습니다.

즉 두 앱의 "로그인된 사용자" 대부분이 현재는 Supabase Auth 세션을 갖지
않습니다. 이 테이블들이 실제로 쓰이려면(Phase 2+) 두 앱의 로그인 흐름이
Supabase Auth 세션을 만들도록 확장되어야 하며, 이는 이번 Phase 범위를
넘는 결정이 필요한 사항입니다.
