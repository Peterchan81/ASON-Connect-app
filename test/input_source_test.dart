// ConversationManager.handleUserText가 실제로 InputSource를 BrainEngine까지
// 전달하는지 검증합니다. 커스텀 Handler를 주입해 BrainContext에 실제로 도착한
// InputSource를 관찰합니다.

import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/context/brain_context.dart';
import 'package:ason_voice_app/features/brain/handlers/brain_turn_handler.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:ason_voice_app/features/brain/models/brain_result.dart';
import 'package:flutter_test/flutter_test.dart';

class _SpyHandler implements BrainTurnHandler {
  InputSource? capturedInputSource;

  @override
  bool canHandle(BrainContext context) => true;

  @override
  BrainResult handle(BrainContext context) {
    capturedInputSource = context.inputSource;
    return BrainResult(draft: context.draft);
  }
}

void main() {
  test('문자 입력은 InputSource.keyboard로 전달된다', () {
    final spy = _SpyHandler();
    final manager = ConversationManager(
      brainEngine: BrainEngine(handlers: [spy]),
    );

    manager.handleUserText('테스트', inputSource: InputSource.keyboard);

    expect(spy.capturedInputSource, InputSource.keyboard);
  });

  test('음성 입력은 InputSource.voice로 전달된다', () {
    final spy = _SpyHandler();
    final manager = ConversationManager(
      brainEngine: BrainEngine(handlers: [spy]),
    );

    manager.handleUserText('테스트', inputSource: InputSource.voice);

    expect(spy.capturedInputSource, InputSource.voice);
  });

  test('inputSource를 지정하지 않아도(기존 호출부) 기본값 unknown으로 동작한다', () {
    final spy = _SpyHandler();
    final manager = ConversationManager(
      brainEngine: BrainEngine(handlers: [spy]),
    );

    manager.handleUserText('테스트'); // 기존 방식 그대로 호출

    expect(spy.capturedInputSource, InputSource.unknown);
  });
}
