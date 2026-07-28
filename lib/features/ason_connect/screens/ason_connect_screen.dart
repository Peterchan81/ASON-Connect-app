// ASON Connect의 대화창 화면입니다.
// 입력 방식 선택, 문자·음성 입력, 대화, 부족한 정보 질문, 최종 확인, 수정, 동기화까지
// 이 화면 하나에서 모두 처리합니다. (앱에는 이 화면과 SplashScreen, 두 화면만 존재합니다)

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/draft_command.dart';
import '../models/voice_mic_phase.dart';
import '../services/conversation_manager.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/chat_area.dart';
import '../widgets/input_area.dart';

class AsonConnectScreen extends StatefulWidget {
  const AsonConnectScreen({super.key});

  @override
  State<AsonConnectScreen> createState() => _AsonConnectScreenState();
}

class _AsonConnectScreenState extends State<AsonConnectScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ConversationManager _conversationManager = ConversationManager();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();

  VoiceMicPhase _voicePhase = VoiceMicPhase.ready;

  // 입력 방식은 이번 세션에서만 유지합니다. (기기에 저장하지 않고, 앱을 다시 실행하면 다시 고릅니다)
  AsonInputMode? _inputMode;

  // 마이크 버튼이 연속으로 눌려도 중복 처리되지 않게 막는 잠금 장치입니다.
  bool _isHandlingVoiceTap = false;

  Timer? _successResetTimer;

  @override
  void dispose() {
    // 화면이 사라질 때는 진행 중인 음성 인식을 반드시 정리합니다.
    _speechService.dispose();
    _successResetTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// 입력 방식을 처음 고를 때 호출됩니다. 이후에는 ModeSwitchButton으로만 바뀝니다.
  void _selectInputMode(AsonInputMode mode) {
    setState(() => _inputMode = mode);
  }

  void _toggleInputMode() {
    setState(() {
      _inputMode = _inputMode == AsonInputMode.voice
          ? AsonInputMode.keyboard
          : AsonInputMode.voice;
    });
  }

  /// 문자 입력창의 문장을 전송합니다.
  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _conversationManager.handleUserText(text);
      _textController.clear();
    });

    FocusScope.of(context).unfocus();
    _scrollToBottom();
  }

  /// 수정 버튼: 내용을 지우지 않고, ASON이 무엇을 바꿀지 되묻습니다.
  void _handleEdit() {
    setState(() {
      _conversationManager.beginEdit();
    });
    _scrollToBottom();
  }

  /// ASON에 동기화 버튼: 처리 중 표시를 먼저 보여준 뒤, 가상 동기화를 수행합니다.
  Future<void> _handleSync() async {
    setState(() {
      _conversationManager.beginSync();
    });
    _scrollToBottom();

    await _conversationManager.finishSync();

    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  /// 새 내용 입력 버튼: 대화와 작성 중이던 내용을 모두 초기화합니다.
  /// 대화는 어디에도 저장하지 않으므로, 초기화하면 그대로 사라집니다.
  void _handleNewInput() {
    setState(() {
      _conversationManager.reset();
      _textController.clear();
    });
  }

  /// 마이크 버튼을 눌렀을 때 실행됩니다.
  Future<void> _onMicPressed() async {
    if (_isHandlingVoiceTap) return;
    _isHandlingVoiceTap = true;

    try {
      if (_voicePhase == VoiceMicPhase.listening) {
        setState(() => _voicePhase = VoiceMicPhase.processing);
        await _speechService.stopListening();
        return;
      }

      if (_voicePhase == VoiceMicPhase.processing) return;

      final available = await _speechService.initialize(
        onStatusChange: _handleSpeechStatusChange,
        onError: _handleSpeechError,
      );
      if (!mounted) return;

      if (!available) {
        setState(() => _voicePhase = VoiceMicPhase.error);
        return;
      }

      setState(() => _voicePhase = VoiceMicPhase.listening);

      final started = await _speechService.startListening(
        onResult: _handleSpeechResult,
      );
      if (!mounted) return;

      if (!started) {
        setState(() => _voicePhase = VoiceMicPhase.error);
      }
    } finally {
      _isHandlingVoiceTap = false;
    }
  }

  /// 음성 인식 도중/완료 시 인식된 문장을 전달받습니다.
  void _handleSpeechResult(String recognizedText, bool isFinal) {
    if (!mounted) return;

    setState(() {
      _textController.text = recognizedText;
      _textController.selection = TextSelection.collapsed(
        offset: recognizedText.length,
      );
    });

    if (!isFinal) return;

    final text = recognizedText.trim();

    // 빈 음성 결과는 분석하지 않습니다.
    if (text.isEmpty) {
      setState(() => _voicePhase = VoiceMicPhase.ready);
      _textController.clear();
      return;
    }

    // 인식된 문장을 전달했다는 표시를 짧게 보여준 뒤, 다시 누를 수 있는 상태로 돌아갑니다.
    setState(() {
      _voicePhase = VoiceMicPhase.success;
      _conversationManager.handleUserText(text);
      _textController.clear();
    });
    _scrollToBottom();

    _successResetTimer?.cancel();
    _successResetTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _voicePhase != VoiceMicPhase.success) return;
      setState(() => _voicePhase = VoiceMicPhase.ready);
    });
  }

  /// speech_to_text 플러그인의 상태 변화(listening/notListening/done)를 받습니다.
  void _handleSpeechStatusChange(String status) {
    if (!mounted) return;

    if (status == 'listening') {
      setState(() => _voicePhase = VoiceMicPhase.listening);
      return;
    }

    if ((status == 'notListening' || status == 'done') &&
        _voicePhase == VoiceMicPhase.listening) {
      setState(() => _voicePhase = VoiceMicPhase.processing);
    }
  }

  /// 음성 인식 중 오류가 발생했을 때 실행됩니다. 문자 입력은 그대로 유지됩니다.
  void _handleSpeechError(String errorMessage, bool permanent) {
    if (!mounted) return;
    setState(() => _voicePhase = VoiceMicPhase.error);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _conversationManager.currentDraft;
    // 수정 버튼을 눌러도(editing) 확인 카드는 절대 사라지지 않고 계속 보입니다.
    final showSummaryCard = _conversationManager.isSummaryAvailable;
    final isEditing = draft?.status == DraftCommandStatus.editing;
    final isSyncing =
        draft != null && draft.status == DraftCommandStatus.syncing;
    final showNewInputButton =
        draft != null && draft.status == DraftCommandStatus.synced;

    return CyberScaffold(
      appBar: CyberTopBar(
        title: 'ASON Connect',
        subtitle: 'Voice & Text Input',
        trailing: Tooltip(
          message: '설정',
          child: GlowIconButton(
            icon: Icons.settings_rounded,
            onPressed: _openSettings,
            filled: false,
            glow: false,
            size: 36,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 360 이하 소형 모바일에서는 카드 좌우 여백을 살짝 줄여 내용 공간을 확보합니다.
            final horizontalPadding = constraints.maxWidth <= 360 ? 10.0 : 16.0;

            return Column(
              children: [
                Expanded(
                  child: ChatArea(
                    messages: _conversationManager.messages,
                    scrollController: _scrollController,
                  ),
                ),
                // 확인 카드/새 입력 버튼이 나타나거나 사라질 때 레이아웃이 뚝 끊기지 않고
                // 부드럽게 높이가 바뀌도록 AnimatedSize로 감쌉니다.
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      if (showSummaryCard)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            4,
                            horizontalPadding,
                            8,
                          ),
                          child: SummaryCard(
                            title: _conversationManager.summaryTitle ?? '요약',
                            rows: _conversationManager.summaryRows,
                            primaryLabel: 'ASON에 동기화',
                            // 수정 질문에 아직 답하지 않은 동안에는 버튼을 비활성화합니다.
                            onPrimary: isEditing ? null : _handleSync,
                            secondaryLabel: '수정',
                            onSecondary: isEditing ? null : _handleEdit,
                          ),
                        ),
                      if (showNewInputButton)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            4,
                            horizontalPadding,
                            8,
                          ),
                          child: GlowButton(
                            label: '새 내용 입력',
                            onPressed: _handleNewInput,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: InputArea(
                    inputMode: _inputMode,
                    onModeSelected: _selectInputMode,
                    controller: _textController,
                    onSend: _handleSend,
                    micPhase: _voicePhase,
                    onMicPressed: _onMicPressed,
                    onToggleMode: _toggleInputMode,
                    isSyncing: isSyncing,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
