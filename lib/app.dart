// 앱의 MaterialApp 설정(테마, 시작 화면 등)을 담당하는 파일입니다.

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/splash/screens/splash_screen.dart';

class AsonVoiceApp extends StatefulWidget {
  const AsonVoiceApp({super.key});

  @override
  State<AsonVoiceApp> createState() => _AsonVoiceAppState();
}

class _AsonVoiceAppState extends State<AsonVoiceApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'ASON Connect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
