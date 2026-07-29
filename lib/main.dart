// 앱 실행 진입점입니다. 실행 코드 외의 로직은 두지 않습니다.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initSupabase();
  runApp(const AsonVoiceApp());
}

/// Supabase 초기화를 시도한다 (Phase 1: 기반만 준비, 아직 아무 화면도
/// 이 연결을 사용하지 않는다 — MockSyncService/CoreSyncMapper는 그대로다).
///
/// `.env` 파일이 없거나 `SUPABASE_URL`/`SUPABASE_ANON_KEY`가 비어 있으면
/// (아직 Supabase 프로젝트를 연결하지 않은 개발 초기 상태) 앱을 종료시키지
/// 않고 경고만 남긴 뒤 기존 로컬(SharedPreferences) 기능만으로 계속 동작하게
/// 한다 — ASON Core(C:\ASON\ASON_Core_app)의 main.dart와 동일한 패턴이다.
///
/// 실제 `.env`를 만들 때는 `pubspec.yaml`의 `flutter: assets:`에도 `.env`를
/// 등록해야 한다(등록하지 않으면 flutter_dotenv가 에셋을 찾지 못한다) —
/// ASON Core의 SUPABASE_SETUP.md 참고. 이 저장소는 실제 `.env`가 없어
/// 기본값으로는 추가해 두지 않았다.
Future<void> _initSupabase() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint(
      'ASON Connect: .env 파일을 찾을 수 없습니다 — Supabase 연동이 비활성화된 '
      '상태로 실행됩니다. .env.example을 복사해 .env를 만들고 '
      'SUPABASE_URL/SUPABASE_ANON_KEY를 채운 뒤 pubspec.yaml의 assets에도 '
      '.env를 등록해 주세요.',
    );
    return;
  }

  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    debugPrint(
      'ASON Connect: SUPABASE_URL/SUPABASE_ANON_KEY가 비어 있습니다 — Supabase '
      '연동이 비활성화된 상태로 실행됩니다.',
    );
    return;
  }

  try {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  } catch (error) {
    debugPrint('ASON Connect: Supabase 초기화에 실패했습니다: $error');
  }
}
