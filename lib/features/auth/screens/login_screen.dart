// ASON Connect 로그인 화면입니다.
// 자동 로그인 정보가 없거나(최초 실행) 만료된 경우 시작 화면 다음으로 이 화면이
// 표시됩니다. 로그인에 성공하면 메인 음성 대화 화면(AsonConnectScreen)으로
// 넘어갑니다.
//
// V1.0에서는 ASON 자체 계정 로그인만 지원합니다. (카카오/구글 등 OAuth 로그인은
// 사용하지 않으며, 관련 UI도 두지 않습니다)

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../ason_connect/screens/ason_connect_screen.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialMessage});

  /// 세션이 만료되었을 때처럼, 화면 진입 직후 바로 보여줄 안내 메시지입니다.
  final String? initialMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _idError;
  String? _passwordError;
  String? _formError;
  String? _infoMessage;
  bool _autoLogin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _infoMessage = widget.initialMessage;
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return; // 중복 클릭 방지

    final id = _idController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _idError = id.isEmpty ? '아이디를 입력해주세요.' : null;
      _passwordError = password.isEmpty ? '비밀번호를 입력해주세요.' : null;
      _formError = null;
      _infoMessage = null;
    });

    if (_idError != null || _passwordError != null) return;

    setState(() => _isLoading = true);
    final result = await AuthService.instance.login(
      id: id,
      password: password,
      keepSignedIn: _autoLogin,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      setState(() => _formError = result.errorMessage);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AsonConnectScreen()),
    );
  }

  void _showComingSoon(String feature) {
    setState(() => _infoMessage = '$feature은(는) 준비 중인 기능입니다.');
  }

  void _openSignup() async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
    if (registered == true && mounted) {
      setState(() => _infoMessage = '회원가입이 완료되었습니다. 로그인해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberScaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AsonLogoHeader(asonFontSize: 34)),
                      const SizedBox(height: 20),
                      Center(
                        child: CharacterGlow(
                          size: 150,
                          child: Image.asset(
                            'assets/images/ason_character.png',
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ASON과 연결을 시작합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '로그인하고 나만의 ASON을 만나보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_infoMessage != null) ...[
                        _InlineBanner(text: _infoMessage!, isError: false),
                        const SizedBox(height: 12),
                      ],
                      NeonTextField(
                        controller: _idController,
                        label: '아이디 또는 이메일',
                        hintText: '아이디 또는 이메일을 입력하세요',
                        errorText: _idError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      NeonTextField(
                        controller: _passwordController,
                        label: '비밀번호',
                        hintText: '비밀번호를 입력하세요',
                        obscureText: true,
                        showObscureToggle: true,
                        errorText: _passwordError,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _autoLogin,
                              activeColor: AsonColors.primary,
                              side: BorderSide(
                                color: AsonColors.primary.withValues(alpha: 0.6),
                              ),
                              onChanged: (value) =>
                                  setState(() => _autoLogin = value ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _autoLogin = !_autoLogin),
                            child: Text(
                              '자동 로그인',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_formError != null) ...[
                        const SizedBox(height: 8),
                        _InlineBanner(text: _formError!, isError: true),
                      ],
                      const SizedBox(height: 18),
                      GlowButton(
                        label: 'ASON 시작하기',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _BottomMenuButton(
                            label: '회원가입',
                            onPressed: _openSignup,
                          ),
                          const _BottomMenuDivider(),
                          _BottomMenuButton(
                            label: '아이디 찾기',
                            onPressed: () => _showComingSoon('아이디 찾기'),
                          ),
                          const _BottomMenuDivider(),
                          _BottomMenuButton(
                            label: '비밀번호 찾기',
                            onPressed: () => _showComingSoon('비밀번호 찾기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 회원가입/아이디 찾기/비밀번호 찾기 메뉴의 좁은 버튼입니다. 기본 TextButton보다
/// 여백을 줄여, 좁은 화면에서도 세 항목이 한 줄에 들어가도록 합니다.
class _BottomMenuButton extends StatelessWidget {
  const _BottomMenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _BottomMenuDivider extends StatelessWidget {
  const _BottomMenuDivider();

  @override
  Widget build(BuildContext context) {
    return Text('|', style: TextStyle(color: Colors.white.withValues(alpha: 0.2)));
  }
}

/// 화면 안에서 바로 보이는 안내/오류 메시지입니다. (SnackBar만 쓰지 않기 위함)
class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AsonColors.error : AsonColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }
}
