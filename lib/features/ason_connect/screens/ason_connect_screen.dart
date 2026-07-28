// ASON Connect의 대화창 화면입니다.
// 입력 방식 선택, 문자·음성 입력, 대화, 부족한 정보 질문, 최종 확인, 수정, 동기화까지
// 이 화면 하나에서 모두 처리합니다. (앱에는 이 화면과 SplashScreen, 두 화면만 존재합니다)

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/voice/voice.dart';
import '../../brain/models/brain_input.dart' show InputSource;
import '../models/draft_command.dart';
import '../models/voice_mic_phase.dart';
import '../services/conversation_manager.dart';
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
  final VoiceService _voiceService = VoiceService(
    provider: SpeechRecognitionProvider(),
  );

  // 실제 ASON-Core 연결은 아직 없어, 화면 우측 상태 표시는 가상(Mock) 값입니다.
  // 사용자에게는 "연결 준비 완료" 문구만 보여줍니다.
  static const bool _simulatedReady = true;

  // 입력 방식은 이번 세션에서만 유지합니다. (기기에 저장하지 않고, 앱을 다시 실행하면 다시 고릅니다)
  AsonInputMode? _inputMode;

  // 마이크 버튼이 연속으로 눌려도 중복 처리되지 않게 막는 잠금 장치입니다.
  bool _isHandlingVoiceTap = false;

  Timer? _successResetTimer;

  @override
  void dispose() {
    // 화면이 사라질 때는 진행 중인 음성 인식을 반드시 정리합니다.
    _voiceService.dispose();
    _successResetTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  VoiceMicPhase _micPhaseFor(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return VoiceMicPhase.ready;
      case VoiceState.listening:
        return VoiceMicPhase.listening;
      case VoiceState.processing:
        return VoiceMicPhase.processing;
      case VoiceState.success:
        return VoiceMicPhase.success;
      case VoiceState.error:
        return VoiceMicPhase.error;
    }
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
      _conversationManager.handleUserText(
        text,
        inputSource: InputSource.keyboard,
      );
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

  /// 새 내용 입력 버튼: 대화와 작성 중이던 내용을 모두 초기화합니다.
  /// 대화는 어디에도 저장하지 않으므로, 초기화하면 그대로 사라집니다.
  void _handleNewInput() {
    setState(() {
      _conversationManager.reset();
      _textController.clear();
    });
  }

  /// 마이크 버튼을 눌렀을 때 실행됩니다.
  /// 듣고 있지 않으면 듣기를 시작하고, 듣는 중이면 멈춥니다. (VoiceService.toggle)
  Future<void> _onMicPressed() async {
    if (_isHandlingVoiceTap) return;
    _isHandlingVoiceTap = true;
    try {
      await _voiceService.toggle(onResult: _handleSpeechResult);
    } finally {
      _isHandlingVoiceTap = false;
    }
  }

  /// 음성 인식 도중/완료 시 인식된 문장을 전달받습니다.
  /// 상태 전환(listening/processing/success/error) 자체는 VoiceService가 처리하므로,
  /// 여기서는 텍스트 반영과 대화 처리만 담당합니다.
  void _handleSpeechResult(String recognizedText, bool isFinal) {
    if (!mounted) return;

    // TextField가 controller 변화를 직접 구독하므로, 인식 중간 결과 표시는
    // 화면 전체를 다시 그리는 setState 없이 controller만 갱신하면 됩니다.
    _textController.text = recognizedText;
    _textController.selection = TextSelection.collapsed(
      offset: recognizedText.length,
    );

    if (!isFinal) return;

    final text = recognizedText.trim();

    // 빈 음성 결과는 분석하지 않습니다. (VoiceService가 이미 idle로 되돌려 둡니다)
    if (text.isEmpty) {
      _textController.clear();
      return;
    }

    // 인식된 문장을 전달했다는 표시(success)는 VoiceService가 이미 보여주고 있습니다.
    setState(() {
      _conversationManager.handleUserText(text, inputSource: InputSource.voice);
      _textController.clear();
    });
    _scrollToBottom();

    _successResetTimer?.cancel();
    _successResetTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _voiceService.state != VoiceState.success) return;
      _voiceService.reset();
    });
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
        trailing: ConnectionStatus(
          label: _simulatedReady ? '연결 준비 완료' : '연결 대기 중',
          color: _simulatedReady ? AsonColors.success : AsonColors.error,
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
                  // 음성 상태(듣는 중/처리 중 등)는 이 부분에만 영향을 주므로,
                  // 화면 전체가 아니라 여기만 다시 그리도록 범위를 좁힙니다.
                  child: ValueListenableBuilder<VoiceState>(
                    valueListenable: _voiceService.stateNotifier,
                    builder: (context, voiceState, _) {
                      return InputArea(
                        inputMode: _inputMode,
                        onModeSelected: _selectInputMode,
                        controller: _textController,
                        onSend: _handleSend,
                        micPhase: _micPhaseFor(voiceState),
                        onMicPressed: _onMicPressed,
                        onToggleMode: _toggleInputMode,
                        isSyncing: isSyncing,
                      );
                    },
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
