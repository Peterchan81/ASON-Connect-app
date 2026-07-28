// 대화 전체를 관리하는 서비스입니다.
// 채팅 메시지 목록과 지금 작성 중인 DraftCommand를 보관하고, 사용자 입력 한 건이
// 오면 BrainEngine에 판단을 맡긴 뒤 그 결과(BrainResult)를 화면 상태에 반영합니다.
//
// Intent 분류, Entity 추출, 부족한 필드 계산, 질문 문구 결정, Summary 준비 여부
// 판단은 모두 BrainEngine(features/brain)이 담당합니다. 이 클래스는 메시지 이력
// 관리, 대화 단계 관리, BrainEngine 호출, 상태 전이, Reset·Mock Sync 실행만
// 담당합니다.
//
// 대화 내용은 메모리에서만 관리하며, 어디에도 영구 저장하지 않습니다.

import '../../brain/brain_engine.dart';
import '../../brain/models/brain_input.dart';
import '../../core_sync/services/core_sync_mapper.dart';
import '../models/chat_message.dart';
import '../models/draft_command.dart';
import '../models/sync_payload.dart';
import 'command_parser_service.dart';
import 'korean_location_service.dart';
import 'mock_sync_service.dart';
import 'summary_builder.dart';

class ConversationManager {
  factory ConversationManager({
    CommandParserService? parser,
    KoreanLocationService? locationService,
    MockSyncService? syncService,
    BrainEngine? brainEngine,
    CoreSyncMapper? coreSyncMapper,
  }) {
    final resolvedLocationService = locationService ?? KoreanLocationService();
    final resolvedParser =
        parser ??
        CommandParserService(locationService: resolvedLocationService);
    return ConversationManager._(
      syncService: syncService ?? MockSyncService(),
      coreSyncMapper: coreSyncMapper ?? CoreSyncMapper(),
      brain:
          brainEngine ??
          BrainEngine(
            parser: resolvedParser,
            locationService: resolvedLocationService,
          ),
    );
  }

  ConversationManager._({
    required this._syncService,
    required this._coreSyncMapper,
    required this._brain,
  }) {
    _addAson(_greetingText);
  }

  final MockSyncService _syncService;
  final CoreSyncMapper _coreSyncMapper;
  final BrainEngine _brain;
  final SummaryBuilder _summaryBuilder = const SummaryBuilder();

  static const String _greetingText =
      '안녕하세요.\n일정, 메모, 건강에 관한 내용을 말씀해 주세요.\nASON 통합 시스템에 정리해서 공유해 드리겠습니다.';

  final List<ChatMessage> _messages = [];

  /// 지금까지 주고받은 모든 메시지입니다. (읽기 전용, 영구 저장되지 않습니다)
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  DraftCommand? _draft;

  /// 지금 작성 중인 내용입니다. 없으면 null입니다.
  DraftCommand? get currentDraft => _draft;

  int _seq = 0;

  /// 확인 카드를 보여줄 수 있는 상태인지 여부입니다.
  /// 수정 버튼을 눌러도(editing) 확인 카드는 절대 사라지지 않고 계속 보입니다.
  bool get isSummaryAvailable {
    final draft = _draft;
    return draft != null &&
        (draft.status == DraftCommandStatus.ready ||
            draft.status == DraftCommandStatus.editing);
  }

  /// 확인 카드에 보여줄, 지금 draft를 정리한 미리보기입니다.
  SyncPayload? get syncPreview {
    final draft = _draft;
    if (draft == null || !isSummaryAvailable) return null;
    return _summaryBuilder.payload(draft);
  }

  /// 확인 카드 제목입니다.
  String? get summaryTitle {
    final draft = _draft;
    if (draft == null || !isSummaryAvailable) return null;
    return _summaryBuilder.title(draft);
  }

  /// 확인 카드에 정해진 순서대로 보여줄 라벨-값 목록입니다.
  List<MapEntry<String, String>> get summaryRows {
    final draft = _draft;
    if (draft == null || !isSummaryAvailable) return const [];
    return _summaryBuilder.rows(draft);
  }

  /// 사용자가 문자 또는 음성으로 전달한 문장 하나를 처리합니다.
  /// [inputSource]는 이 문장이 음성/문자 중 어디서 왔는지이며, BrainEngine에 그대로
  /// 전달됩니다. (기존 호출부와의 호환을 위해 기본값은 unknown입니다)
  /// 실제 판단(분류/추출/질문 계획)은 BrainEngine이 하고, 여기서는 그 결과를
  /// 메시지 이력과 draft 상태에 반영하기만 합니다.
  void handleUserText(
    String rawInput, {
    InputSource inputSource = InputSource.unknown,
  }) {
    final rawText = rawInput.trim();
    if (rawText.isEmpty) return;

    _addUser(rawText);

    final result = _brain.process(
      BrainInput(text: rawText, draft: _draft, inputSource: inputSource),
    );

    _draft = result.draft;
    for (final message in result.messages) {
      _addAson(message.text, type: message.type);
    }
  }

  /// 수정 버튼: 지금 내용을 지우지 않고, 무엇을 바꿀지 되묻습니다.
  void beginEdit() {
    final draft = _draft;
    if (draft == null) return;

    _draft = draft.copyWith(status: DraftCommandStatus.editing);
    _addAson('어떤 내용을 수정할까요?', type: ChatMessageType.question);
  }

  /// ASON에 동기화 버튼: 동기화 상태로 전환합니다. (동기 처리 부분)
  /// "동기화하는 중" 표시는 화면(로딩 인디케이터)에서 보여주므로 여기서는
  /// 별도의 대화 메시지를 남기지 않습니다.
  void beginSync() {
    final draft = _draft;
    if (draft == null || draft.status != DraftCommandStatus.ready) return;

    _draft = draft.copyWith(status: DraftCommandStatus.syncing);
  }

  /// 실제 가상 동기화를 수행합니다. (비동기 처리 부분)
  Future<void> finishSync() async {
    final draft = _draft;
    if (draft == null || draft.status != DraftCommandStatus.syncing) return;

    final payload = _summaryBuilder.payload(draft);
    final result = await _syncService.sync(payload);

    if (result.isSuccess) {
      try {
        // ASON-Core와 같은 저장 구조(SharedPreferences)에 실제로 반영합니다.
        // 같은 draft(같은 createdAt)를 다시 동기화하면 같은 id로 덮어써서
        // 중복 저장되지 않습니다.
        await _coreSyncMapper.sync(draft);
        _draft = draft.copyWith(status: DraftCommandStatus.synced);
        _addAson(
          'ASON Core에 동기화할 준비가 완료되었습니다.',
          type: ChatMessageType.syncComplete,
        );
      } catch (_) {
        _draft = draft.copyWith(status: DraftCommandStatus.ready);
        _addAson('동기화 중 오류가 발생했습니다.', type: ChatMessageType.error);
      }
    } else {
      _draft = draft.copyWith(status: DraftCommandStatus.ready);
      _addAson(
        result.errorMessage ?? '동기화 중 오류가 발생했습니다.',
        type: ChatMessageType.error,
      );
    }
  }

  /// 새 내용 입력 버튼: 대화, 작성 중이던 내용, 입력 상태를 모두 초기화합니다.
  /// 대화는 어디에도 저장하지 않으므로, 초기화하면 그대로 사라집니다.
  void reset() {
    _messages.clear();
    _draft = null;
    _addAson(_greetingText);
  }

  void _addUser(String text) {
    _messages.add(
      ChatMessage(
        id: _nextId(),
        text: text,
        sender: ChatSender.user,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _addAson(String text, {ChatMessageType type = ChatMessageType.normal}) {
    _messages.add(
      ChatMessage(
        id: _nextId(),
        text: text,
        sender: ChatSender.ason,
        createdAt: DateTime.now(),
        messageType: type,
      ),
    );
  }

  String _nextId() {
    _seq += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }
}
