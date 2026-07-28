// ASON Connect의 시작 화면입니다.
// 버튼 없이, 3초 뒤 자동으로 AsonConnectScreen(대화 화면)으로 넘어갑니다.
// 앱에는 이 화면과 AsonConnectScreen, 두 화면만 존재합니다.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../ason_connect/screens/ason_connect_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/countdown_hud.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const int _totalSeconds = 3;
  int _secondsLeft = _totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!mounted) return;

    if (_secondsLeft <= 1) {
      timer.cancel();
      _goNext();
      return;
    }

    setState(() => _secondsLeft -= 1);
  }

  /// 저장된 로그인 상태를 확인한 뒤, 자동 로그인에 성공하면 메인 음성 화면으로,
  /// 그렇지 않으면 로그인 화면으로 넘어갑니다. (뒤로 가기로 이 화면에 돌아오지
  /// 못하도록 pushReplacement를 사용합니다)
  Future<void> _goNext() async {
    final result = await AuthService.instance.tryAutoLogin();
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AsonConnectScreen()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          initialMessage: result.isExpired
              ? '로그인 정보가 만료되었습니다. 다시 로그인해주세요.'
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CyberScaffold(
      animateBackground: true,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 작은 화면(작은 스마트폰, 세로로 좁은 Chrome 창)에서도 내용이
                // 잘리지 않도록, 화면보다 내용이 커지면 스크롤로 전환합니다.
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AsonLogoHeader(),
                            const SizedBox(height: 24),
                            CharacterGlow(
                              child: Image.asset(
                                'assets/images/ason_character.png',
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                                children: [
                                  const TextSpan(text: '말하거나 입력하면\n'),
                                  TextSpan(
                                    text: 'ASON',
                                    style: TextStyle(
                                      color: AsonColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: '이 내용을 정리하여\n통합 시스템에 '),
                                  TextSpan(
                                    text: '공유',
                                    style: TextStyle(
                                      color: AsonColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: '합니다.'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                            CountdownHud(
                              secondsLeft: _secondsLeft,
                              totalSeconds: _totalSeconds,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '잠시 후 시작됩니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 화면 하단의 오렌지 네온 라인 장식입니다.
          Positioned(
            left: 48,
            right: 48,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AsonColors.primary.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: AsonGlow.of(AsonColors.primary, blur: 14, opacity: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
