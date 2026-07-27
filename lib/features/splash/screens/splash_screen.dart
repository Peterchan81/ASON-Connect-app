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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const GlowText(
                    'ASON',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    glowStrength: 1.2,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CONNECT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: AsonColors.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              EnergyRing(
                child: Image.asset(
                  'assets/images/ason_character.png',
                  height: 230,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
