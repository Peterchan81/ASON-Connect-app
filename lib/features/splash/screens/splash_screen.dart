// ASON Connect의 시작 화면입니다.
// 버튼 없이, 3초 뒤 자동으로 AsonConnectScreen(대화 화면)으로 넘어갑니다.
// 앱에는 이 화면과 AsonConnectScreen, 두 화면만 존재합니다.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../ason_connect/screens/ason_connect_screen.dart';
import '../widgets/countdown_hud.dart';
import '../widgets/energy_ring.dart';

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

  void _goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AsonConnectScreen()),
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
                            const _AsonLogoLockup(),
                            const SizedBox(height: 24),
                            EnergyRing(
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

/// 상단 "ASON / — CONNECT —" 로고 조합입니다.
class _AsonLogoLockup extends StatelessWidget {
  const _AsonLogoLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GlowText(
          'ASON',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
          glowStrength: 1.3,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _accentLine(),
            const SizedBox(width: 10),
            Text(
              'CONNECT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: AsonColors.primary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 10),
            _accentLine(),
          ],
        ),
      ],
    );
  }

  Widget _accentLine() {
    return Container(
      width: 22,
      height: 1,
      color: AsonColors.primary.withValues(alpha: 0.5),
    );
  }
}
