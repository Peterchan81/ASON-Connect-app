// ASON Connect의 메인(유일한) 입력 화면입니다.
// 흐름은 정확히 다음과 같습니다: 음성 또는 키보드 입력 -> 자동 분석 및 정리
// -> 사용자 확인 -> 수정 또는 동기화 -> 입력 초기화. 이 흐름 밖의 단계(홈 허브,
// 기능 선택, 채팅 이력 등)는 두지 않습니다. (앱에는 이 화면과 SplashScreen,
// 두 화면만 존재합니다)

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/voice/voice.dart';
import '../../brain/models/brain_input.dart' show InputSource;
import '../../settings/screens/settings_screen.dart';
import '../models/draft_command.dart';
import '../models/voice_mic_phase.dart';
import '../services/conversation_manager.dart';
import '../widgets/input_area.dart';

class AsonConnectScreen extends StatefulWidget {
  const AsonConnectScreen({super.key});

  @override
  State<AsonConnectScreen> createState() => _AsonConnectScreenState();
}

class _AsonConnectScreenState extends State<AsonConnectScreen> {
  final TextEditingController _textController = TextEditingController();
  final ConversationManager _conversationManager = ConversationManager();
  final VoiceService _voiceService = VoiceService(
    provider: SpeechRecognitionProvider(),
  );

  // 입력 방식은 이번 세션에서만 유지합니다(기기에 저장하지 않음). 선택 화면
  // 없이 곧바로 사용할 수 있도록 키보드 모드로 시작합니다.
  AsonInputMode _inputMode = AsonInputMode.keyboard;

  // 마이크 버튼이 연속으로 눌려도 중복 처리되지 않게 막는 잠금 장치입니다.
  bool _isHandlingVoiceTap = false;

  Timer? _successResetTimer;

  // 아직 전송하지 않은 문장을 실시간으로 미리 분석해, 입력창 바로 위 패널에
  // 보여주기 위한 상태입니다. (전송 전까지는 실제 draft에 반영되지 않는
  // 순수 미리보기)
  Timer? _previewDebounce;
  DraftCommand? _livePreviewDraft;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChangedForPreview);
  }

  @override
  void dispose() {
    // 화면이 사라질 때는 진행 중인 음성 인식을 반드시 정리합니다.
    _voiceService.dispose();
    _successResetTimer?.cancel();
    _previewDebounce?.cancel();
    _textController.removeListener(_handleTextChangedForPreview);
    _textController.dispose();
    super.dispose();
  }

  /// 이미 진행 중인 draft가 있으면(질문에 답하는 중 등) 실시간 미리보기는
  /// 쓰지 않고, 실제 커밋된 draft만 패널에 보여줍니다. 아직 아무 것도
  /// 시작하지 않았을 때만(= 첫 문장을 입력하는 중일 때만) 미리보기를 씁니다.
  void _handleTextChangedForPreview() {
    if (_conversationManager.currentDraft != null) return;

    _previewDebounce?.cancel();
    final text = _textController.text;
    if (text.trim().isEmpty) {
      if (_livePreviewDraft != null) setState(() => _livePreviewDraft = null);
      return;
    }

    _previewDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _livePreviewDraft = _conversationManager.previewDraft(text);
      });
    });
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
      _livePreviewDraft = null;
      _textController.clear();
    });

    FocusScope.of(context).unfocus();
  }

  /// 수정 버튼: 내용을 지우지 않고, ASON이 무엇을 바꿀지 되묻습니다.
  void _handleEdit() {
    setState(() {
      _conversationManager.beginEdit();
    });
  }

  /// ASON에 동기화 버튼: 동기화를 수행하고, 성공하면 짧게 안내한 뒤 곧바로
  /// 입력창과 결과 카드를 초기화합니다. 실패하면 카드에 이유를 남기고
  /// 그대로 유지합니다(다시 수정하거나 재시도할 수 있도록).
  Future<void> _handleSync() async {
    setState(() {
      _conversationManager.beginSync();
    });

    await _conversationManager.finishSync();

    if (!mounted) return;

    if (_conversationManager.lastSyncError == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ASON에 저장되었습니다.')));
      setState(() {
        _conversationManager.reset();
        _textController.clear();
      });
    } else {
      setState(() {});
    }
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
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

    setState(() => _textController.text = recognizedText);

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
      _livePreviewDraft = null;
      _textController.clear();
    });

    _successResetTimer?.cancel();
    _successResetTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _voiceService.state != VoiceState.success) return;
      _voiceService.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = _conversationManager.currentDraft;
    final panelDraft = draft ?? _livePreviewDraft;

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
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '말하거나 입력해 주세요.\nASON이 내용을 정리합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AsonColors.onBackgroundMuted(context),
                    ),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<VoiceState>(
              valueListenable: _voiceService.stateNotifier,
              builder: (context, voiceState, _) {
                return InputArea(
                  mode: _inputMode,
                  onToggleMode: _toggleInputMode,
                  controller: _textController,
                  onSend: _handleSend,
                  micPhase: _micPhaseFor(voiceState),
                  onMicPressed: _onMicPressed,
                  panelDraft: panelDraft,
                  panelIsPreviewOnly: draft == null,
                  panelPendingQuestion: _conversationManager.pendingQuestion,
                  panelSyncError: _conversationManager.lastSyncError,
                  onPanelEdit: _handleEdit,
                  onPanelSync: _handleSync,
                  standaloneGuidance: _conversationManager.standaloneGuidance,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
