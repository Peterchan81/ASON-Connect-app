// ASON Connect 회원가입 화면입니다.
// ASON Core(ASON_Core_app/lib/screens/signup/signup_screen.dart)와 동일한
// 회원가입 순서·약관 동의 구조·팝업을 사용합니다. (새 UX를 만들지 않습니다)
// 디자인은 ASON Connect의 다크 네온 테마를 유지하되, 체크박스 크기·글자
// 크기·간격·버튼·팝업·약관 화면의 비율은 Core와 동일하게 맞춥니다.
//
// 가입에 성공하면 true를 들고 로그인 화면으로 돌아갑니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../data/terms/marketing_terms.dart';
import '../data/terms/privacy_terms.dart';
import '../data/terms/service_terms.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? _nicknameError;
  String? _idError;
  String? _passwordError;
  String? _confirmError;
  String? _emailError;
  String? _termsError;
  String? _formError;

  // ASON Core와 동일하게 [필수] 이용약관 / [필수] 개인정보 처리방침 / [선택] 알림 수신,
  // 세 항목으로 나누어 동의를 받습니다.
  bool _termsService = false;
  bool _termsPrivacy = false;
  bool _marketingConsent = false;

  bool _isLoading = false;

  bool get _allAgreed => _termsService && _termsPrivacy && _marketingConsent;

  @override
  void dispose() {
    _nicknameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleAllAgree(bool? value) {
    final next = value ?? !_allAgreed;
    setState(() {
      _termsService = next;
      _termsPrivacy = next;
      _marketingConsent = next;
    });
  }

  // ASON Core와 동일하게, 약관 항목을 누르면 전체 약관 전문을 팝업으로 보여줍니다.
  void _showTermsDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AsonColors.surfaceNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      body,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: GlowButton(
                    label: '확인',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _validate() {
    final nickname = _nicknameController.text.trim();
    final id = _idController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final email = _emailController.text.trim();

    setState(() {
      _nicknameError = nickname.isEmpty ? '닉네임을 입력해주세요.' : null;
      _idError = id.isEmpty ? '아이디를 입력해주세요.' : null;
      _passwordError = password.isEmpty ? '비밀번호를 입력해주세요.' : null;
      _confirmError = confirm.isEmpty
          ? '비밀번호 확인을 입력해주세요.'
          : (confirm != password ? '비밀번호가 일치하지 않습니다.' : null);
      _emailError = email.isEmpty
          ? '이메일을 입력해주세요.'
          : (!_emailPattern.hasMatch(email) ? '올바른 이메일 형식이 아닙니다.' : null);
      // 알림 수신은 선택 항목이라 필수 약관(이용약관/개인정보 처리방침)만 확인합니다.
      _termsError = (_termsService && _termsPrivacy) ? null : '필수 약관에 동의해주세요.';
    });

    return _nicknameError == null &&
        _idError == null &&
        _passwordError == null &&
        _confirmError == null &&
        _emailError == null &&
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

    // 회원가입 완료 후에는 로그인 화면으로 돌아갑니다. (자동 로그인 여부는 로그인
    // 화면에서 사용자가 다시 선택하는 기존 로그인 구조를 그대로 유지합니다)
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
              // 1. 닉네임
              NeonTextField(
                controller: _nicknameController,
                label: '닉네임',
                hintText: '사용할 닉네임을 입력하세요',
                errorText: _nicknameError,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              // 2. 아이디
              NeonTextField(
                controller: _idController,
                label: '아이디',
                hintText: '로그인에 사용할 아이디를 입력하세요',
                errorText: _idError,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              // 3. 비밀번호
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
              // 4. 비밀번호 확인
              NeonTextField(
                controller: _confirmController,
                label: '비밀번호 확인',
                hintText: '비밀번호를 다시 입력하세요',
                obscureText: true,
                showObscureToggle: true,
                errorText: _confirmError,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              // 5. 이메일
              NeonTextField(
                controller: _emailController,
                label: '이메일',
                hintText: 'example@ason.app',
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 22),
              // 6. 이용약관 동의
              _TermsSection(
                allAgreed: _allAgreed,
                onAllAgreeChanged: _toggleAllAgree,
                termsService: _termsService,
                onTermsServiceChanged: (value) =>
                    setState(() => _termsService = value ?? false),
                onViewTermsService: () =>
                    _showTermsDialog(ServiceTerms.title, ServiceTerms.body),
                termsPrivacy: _termsPrivacy,
                onTermsPrivacyChanged: (value) =>
                    setState(() => _termsPrivacy = value ?? false),
                onViewTermsPrivacy: () =>
                    _showTermsDialog(PrivacyTerms.title, PrivacyTerms.body),
                marketingConsent: _marketingConsent,
                onMarketingConsentChanged: (value) =>
                    setState(() => _marketingConsent = value ?? false),
                onViewMarketing: () =>
                    _showTermsDialog(MarketingTerms.title, MarketingTerms.body),
              ),
              if (_termsError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Text(
                    _termsError!,
                    style: TextStyle(fontSize: 12, color: AsonColors.error),
                  ),
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
              // 7. 회원가입 완료
              GlowButton(
                label: '회원가입 완료',
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

/// ASON Core와 동일한 구조의 약관 동의 영역입니다.
/// 전체 동의 + [필수] 이용약관 + [필수] 개인정보 처리방침 + [선택] 알림 수신,
/// 네 개의 체크 항목으로 구성됩니다.
class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.allAgreed,
    required this.onAllAgreeChanged,
    required this.termsService,
    required this.onTermsServiceChanged,
    required this.onViewTermsService,
    required this.termsPrivacy,
    required this.onTermsPrivacyChanged,
    required this.onViewTermsPrivacy,
    required this.marketingConsent,
    required this.onMarketingConsentChanged,
    required this.onViewMarketing,
  });

  final bool allAgreed;
  final ValueChanged<bool?> onAllAgreeChanged;
  final bool termsService;
  final ValueChanged<bool?> onTermsServiceChanged;
  final VoidCallback onViewTermsService;
  final bool termsPrivacy;
  final ValueChanged<bool?> onTermsPrivacyChanged;
  final VoidCallback onViewTermsPrivacy;
  final bool marketingConsent;
  final ValueChanged<bool?> onMarketingConsentChanged;
  final VoidCallback onViewMarketing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AsonColors.surfaceNavy.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AsonColors.primary,
              value: allAgreed,
              onChanged: onAllAgreeChanged,
              title: const Text(
                '전체 동의',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            _TermRow(
              label: '[필수] ASON 서비스 이용약관 동의',
              value: termsService,
              onChanged: onTermsServiceChanged,
              onView: onViewTermsService,
            ),
            _TermRow(
              label: '[필수] 개인정보 수집 및 이용 동의',
              value: termsPrivacy,
              onChanged: onTermsPrivacyChanged,
              onView: onViewTermsPrivacy,
            ),
            _TermRow(
              label: '[선택] ASON 소식 및 업데이트 알림 수신',
              value: marketingConsent,
              onChanged: onMarketingConsentChanged,
              onView: onViewMarketing,
            ),
          ],
        ),
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onView,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Checkbox(
              activeColor: AsonColors.primary,
              value: value,
              onChanged: onChanged,
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: Colors.white.withValues(alpha: 0.55),
              ),
              child: const Text('보기', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
