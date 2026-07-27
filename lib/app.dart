// 앱의 MaterialApp 설정(테마, 시작 화면 등)을 담당하는 파일입니다.

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/screens/splash_screen.dart';

class AsonVoiceApp extends StatelessWidget {
  const AsonVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASON Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
