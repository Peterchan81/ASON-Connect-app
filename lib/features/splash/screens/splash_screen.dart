// ASON Connect의 시작 화면입니다.
// 버튼 없이, 3초 뒤 자동으로 AsonConnectScreen(대화 화면)으로 넘어갑니다.
// 앱에는 이 화면과 AsonConnectScreen, 두 화면만 존재합니다.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../ason_connect/screens/ason_connect_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/countdown_hud.dart';
import '../widgets/splash_neon_backdrop.dart';

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
      forceDark: true,
      body: Stack(
        children: [
          // 시작 화면 전용 네온 밀도 강화 배경입니다. (CyberBackground 위에 겹칩니다)
          const Positioned.fill(
            child: IgnorePointer(child: SplashNeonBackdrop()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final width = constraints.maxWidth;
                // 844(일반적인 세로 스마트폰 높이) 기준 비율로 간격을 늘리고
                // 줄입니다. 화면이 아주 작거나 커도 요소가 과하게 작아지거나
                // 커지지 않도록 범위를 제한합니다.
                final scale = (height / 844).clamp(0.72, 1.08);
                // 로고/캐릭터/카운트다운은 목표 이미지처럼 "화면 너비 대비
                // 비율"이 기준이므로, 실제로 보이는 콘텐츠 폭(최대 420)을
                // 기준으로 크기를 계산합니다.
                final contentWidth = math.min(width, 420.0);
                final asonFontSize = (contentWidth * 0.19).clamp(52.0, 90.0);
                final characterRingSize = (contentWidth * 0.80).clamp(
                  260.0,
                  380.0,
                );
                final characterImageSize = characterRingSize * 0.6;
                final countdownSize = (contentWidth * 0.42).clamp(140.0, 220.0);

                // 작은 화면(작은 스마트폰, 세로로 좁은 Chrome 창)에서도 내용이
                // 잘리지 않도록, 화면보다 내용이 커지면 스크롤로 전환합니다.
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height),
                    child: IntrinsicHeight(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width <= 360 ? 16.0 : 22.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 6 * scale),
                                AsonLogoHeader(asonFontSize: asonFontSize),
                                SizedBox(height: 26 * scale),
                                CharacterGlow(
                                  size: characterRingSize,
                                  child: Image.asset(
                                    'assets/images/ason_character.png',
                                    height: characterImageSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 22 * scale),
                                _SplashDescription(scale: scale),
                                SizedBox(height: 24 * scale),
                                CountdownHud(
                                  secondsLeft: _secondsLeft,
                                  totalSeconds: _totalSeconds,
                                  size: countdownSize,
                                ),
                                SizedBox(height: 14 * scale),
                                Text(
                                  '잠시 후 시작됩니다.',
                                  style: TextStyle(
                                    fontSize: (15 * scale).clamp(14.0, 17.0),
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                SizedBox(height: 18 * scale),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 화면 하단의 오렌지 네온 광원 + 곡선 장식입니다.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: IgnorePointer(child: SplashBottomGlow()),
          ),
        ],
      ),
    );
  }
}

/// 캐릭터 바로 아래에 표시하는 세 줄 안내 문구입니다.
class _SplashDescription extends StatelessWidget {
  const _SplashDescription({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final fontSize = (24 * scale).clamp(21.0, 27.0);
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.92),
        ),
        children: [
          const TextSpan(text: '말하거나 입력하면\n'),
          TextSpan(
            text: 'ASON',
            style: TextStyle(
              color: AsonColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(text: '이 내용을 정리하여\n통합 시스템에 '),
          TextSpan(
            text: '공유',
            style: TextStyle(
              color: AsonColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(text: '합니다.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
