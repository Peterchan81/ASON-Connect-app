// ASON Connect 회원가입 화면입니다.
// 가입에 성공하면 true를 들고 로그인 화면으로 돌아갑니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? _nicknameError;
  String? _idError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _termsError;
  String? _formError;

  bool _agreeRequired = false;
  bool _agreeNotification = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final nickname = _nicknameController.text.trim();
    final id = _idController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    setState(() {
      _nicknameError = nickname.isEmpty ? '닉네임을 입력해주세요.' : null;
      _idError = id.isEmpty ? '아이디를 입력해주세요.' : null;
      _emailError = email.isEmpty
          ? '이메일을 입력해주세요.'
          : (!_emailPattern.hasMatch(email) ? '올바른 이메일 형식이 아닙니다.' : null);
      _passwordError = password.isEmpty ? '비밀번호를 입력해주세요.' : null;
      _confirmError = confirm.isEmpty
          ? '비밀번호 확인을 입력해주세요.'
          : (confirm != password ? '비밀번호가 일치하지 않습니다.' : null);
      _termsError = _agreeRequired ? null : '필수 약관에 동의해주세요.';
    });

    return _nicknameError == null &&
        _idError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmError == null &&
        _termsError == null;
  }

  Future<void> _handleSignup() async {
    if (_isLoading) return;
    setState(() => _formError = null);
    if (!_validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.instance.register(
      nickname: _nicknameController.text.trim(),
      id: _idController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      setState(() => _formError = result.errorMessage);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return CyberScaffold(
      appBar: CyberTopBar(
        title: '회원가입',
        leading: GlowIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(false),
          filled: false,
          glow: false,
          size: 40,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '나만의 ASON을 만들어보세요.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),
              NeonTextField(
                controller: _nicknameController,
                label: '닉네임',
                hintText: '사용할 닉네임을 입력하세요',
                errorText: _nicknameError,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              NeonTextField(
                controller: _idController,
                label: '아이디',
                hintText: '로그인에 사용할 아이디를 입력하세요',
                errorText: _idError,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              NeonTextField(
                controller: _emailController,
                label: '이메일',
                hintText: 'example@ason.app',
                errorText: _emailError,
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
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              NeonTextField(
                controller: _confirmController,
                label: '비밀번호 확인',
                hintText: '비밀번호를 다시 입력하세요',
                obscureText: true,
                showObscureToggle: true,
                errorText: _confirmError,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              _AgreementRow(
                value: _agreeRequired,
                label: '[필수] 이용약관 및 개인정보 처리방침에 동의합니다.',
                onChanged: (value) => setState(() => _agreeRequired = value),
              ),
              if (_termsError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 30, top: 2),
                  child: Text(
                    _termsError!,
                    style: TextStyle(fontSize: 12, color: AsonColors.error),
                  ),
                ),
              const SizedBox(height: 4),
              _AgreementRow(
                value: _agreeNotification,
                label: '[선택] 알림 수신에 동의합니다.',
                onChanged: (value) => setState(() => _agreeNotification = value),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AsonColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AsonColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _formError!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              GlowButton(
                label: '가입하기',
                onPressed: _handleSignup,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            activeColor: AsonColors.primary,
            side: BorderSide(color: AsonColors.primary.withValues(alpha: 0.6)),
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
