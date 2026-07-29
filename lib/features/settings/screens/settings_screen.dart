// ASON Connect 설정 화면입니다.
// 계정 정보(닉네임만 수정 가능)·테마·버전 정보를 보여주고, 화면 하단에서
// 로그아웃할 수 있습니다. ASON Connect의 다크 + 오렌지 네온 디자인을 그대로
// 따릅니다. 테마를 선택하면 ThemeController를 통해 앱 전체에 즉시 반영되고
// SharedPreferences에 저장되어 다음 실행에도 유지됩니다.

import 'package:flutter/material.dart';

import '../../../core/app_info.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/models/ason_account.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  AsonAccount? _account;
  bool _isLoadingAccount = true;
  bool _isSavingNickname = false;
  String? _nicknameError;
  String? _nicknameInfo;

  AppThemeMode _themeMode = AppThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadAccount();
    _loadPreferences();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    final account = await AuthService.instance.currentAccount();
    if (!mounted) return;
    setState(() {
      _account = account;
      _nicknameController.text = account?.nickname ?? '';
      _isLoadingAccount = false;
    });
  }

  Future<void> _loadPreferences() async {
    final themeMode = await SettingsService.instance.loadThemeMode();
    if (!mounted) return;
    setState(() => _themeMode = themeMode);
  }

  Future<void> _handleSaveNickname() async {
    if (_isSavingNickname) return;

    setState(() {
      _nicknameError = null;
      _nicknameInfo = null;
      _isSavingNickname = true;
    });

    final result = await AuthService.instance.updateNickname(
      _nicknameController.text,
    );

    if (!mounted) return;
    setState(() => _isSavingNickname = false);

    if (!result.isSuccess) {
      setState(() => _nicknameError = result.errorMessage);
      return;
    }

    final account = await AuthService.instance.currentAccount();
    if (!mounted) return;
    setState(() {
      _account = account;
      _nicknameInfo = '닉네임이 변경되었습니다.';
    });
  }

  Future<void> _handleThemeChanged(AppThemeMode? mode) async {
    if (mode == null) return;
    setState(() => _themeMode = mode);
    // ThemeController가 저장(SettingsService)과 화면 즉시 반영을 함께 처리합니다.
    await ThemeController.instance.setMode(mode);
  }

  Future<void> _handleDisableAutoLogin() async {
    await AuthService.instance.disableAutoLogin();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('자동 로그인이 해제되었습니다.')));
  }

  Future<void> _handleLogoutPressed() async {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isLight
            ? AsonColors.lightSurface
            : AsonColors.surfaceNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '로그아웃',
          style: TextStyle(color: AsonColors.onBackground(context)),
        ),
        content: Text(
          '로그아웃 하시겠습니까?',
          style: TextStyle(color: AsonColors.onBackgroundMuted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AsonColors.error),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    await AuthService.instance.logout();
    if (!mounted) return;

    // 설정 화면은 대화 화면 위에 쌓여 있으므로, 뒤로 가기로 어느 화면에도
    // 돌아갈 수 없도록 스택 전체를 로그인 화면으로 교체합니다.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CyberScaffold(
      appBar: CyberTopBar(
        title: '설정',
        leading: GlowIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).maybePop(),
          filled: false,
          glow: false,
          size: 40,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsSection(
                title: '계정 정보',
                child: _isLoadingAccount
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        ),
                      )
                    : _AccountInfoBody(
                        nicknameController: _nicknameController,
                        nicknameError: _nicknameError,
                        nicknameInfo: _nicknameInfo,
                        isSaving: _isSavingNickname,
                        onSave: _handleSaveNickname,
                        id: _account?.id ?? '-',
                        email: _account?.email ?? '-',
                        showDisableAutoLogin:
                            AuthService.instance.autoLoginEnabled,
                        onDisableAutoLogin: _handleDisableAutoLogin,
                      ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: '화면 변경',
                child: Column(
                  children: [
                    for (final mode in AppThemeMode.values)
                      _SelectableTile(
                        label: mode.label,
                        selected: mode == _themeMode,
                        onTap: () => _handleThemeChanged(mode),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: '버전 정보',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Version $kAppVersion',
                    style: TextStyle(
                      fontSize: 13,
                      color: AsonColors.onBackgroundMuted(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              GlowButton(label: '로그아웃', onPressed: _handleLogoutPressed),
            ],
          ),
        ),
      ),
    );
  }
}

/// 설정 화면의 각 항목을 감싸는 공통 카드입니다. (계정 정보/테마/버전 정보)
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AsonColors.primary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// 테마/언어처럼 여러 항목 중 하나만 고르는 단일 선택 행입니다.
/// Radio/RadioListTile 대신 사용해, 그룹 상태 관리 없이 직접 선택 값을 다룹니다.
class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected
                    ? AsonColors.primary
                    : AsonColors.onBackgroundMuted(context),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: AsonColors.onBackground(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountInfoBody extends StatelessWidget {
  const _AccountInfoBody({
    required this.nicknameController,
    required this.nicknameError,
    required this.nicknameInfo,
    required this.isSaving,
    required this.onSave,
    required this.id,
    required this.email,
    required this.showDisableAutoLogin,
    required this.onDisableAutoLogin,
  });

  final TextEditingController nicknameController;
  final String? nicknameError;
  final String? nicknameInfo;
  final bool isSaving;
  final VoidCallback onSave;
  final String id;
  final String email;
  final bool showDisableAutoLogin;
  final VoidCallback onDisableAutoLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NeonTextField(
                controller: nicknameController,
                label: '닉네임',
                hintText: '사용할 닉네임을 입력하세요',
                errorText: nicknameError,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                height: 48,
                child: GlowButton(
                  label: '저장',
                  expand: false,
                  isLoading: isSaving,
                  onPressed: onSave,
                ),
              ),
            ),
          ],
        ),
        if (nicknameInfo != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              nicknameInfo!,
              style: TextStyle(fontSize: 12, color: AsonColors.success),
            ),
          ),
        const SizedBox(height: 14),
        _ReadOnlyField(label: '아이디', value: id),
        const SizedBox(height: 12),
        _ReadOnlyField(label: '이메일', value: email),
        if (showDisableAutoLogin) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onDisableAutoLogin,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AsonColors.onBackgroundMuted(context),
              ),
              child: const Text('자동 로그인 해제', style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ],
    );
  }
}

/// 아이디/이메일처럼 수정할 수 없는 계정 항목을 보여줍니다.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AsonColors.onBackgroundMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isLight
                ? AsonColors.lightBackground
                : AsonColors.surfaceNavy.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: AsonColors.onBackgroundMuted(context),
            ),
          ),
        ),
      ],
    );
  }
}
