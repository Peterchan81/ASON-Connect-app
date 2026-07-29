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
import '../../brain/models/brain_result.dart';
import '../../brain/services/multi_intent_splitter.dart';
import '../../core_sync/services/core_sync_mapper.dart';
import '../models/chat_message.dart';
import '../models/connect_item.dart';
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
    MultiIntentSplitter? multiIntentSplitter,
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
      splitter: multiIntentSplitter ?? const MultiIntentSplitter(),
    );
  }

  ConversationManager._({
    required this._syncService,
    required this._coreSyncMapper,
    required this._brain,
    required this._splitter,
  });

  final MockSyncService _syncService;
  final CoreSyncMapper _coreSyncMapper;
  final BrainEngine _brain;
  final MultiIntentSplitter _splitter;
  final SummaryBuilder _summaryBuilder = const SummaryBuilder();

  final List<ChatMessage> _messages = [];

  /// 지금까지 주고받은 모든 메시지입니다. (읽기 전용, 영구 저장되지 않습니다)
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  DraftCommand? _draft;

  /// 지금 작성 중인 내용입니다. 없으면 null입니다.
  DraftCommand? get currentDraft => _draft;

  final List<ConnectItem> _items = [];

  /// 한 번의 입력에서 여러 개의 의도(일정/나의 하루 목표/다이어리/메모)로 나뉜
  /// 경우, 항목별로 보여줄 목록입니다. 나뉘지 않은 보통의 대화는 이 목록 대신
  /// [currentDraft] 하나만 사용합니다.
  List<ConnectItem> get items => List.unmodifiable(_items);

  /// 두 개 이상의 항목으로 나뉜 입력이 진행 중인지 여부입니다.
  bool get hasItems => _items.isNotEmpty;

  /// 모든 항목이 정보 부족 없이 준비되어, "모두 ASON에 동기화" 버튼을 보여줄 수
  /// 있는 상태인지 여부입니다.
  bool get allItemsReady =>
      _items.isNotEmpty &&
      _items.every((item) => item.draft.status == DraftCommandStatus.ready);

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

  String? _lastSyncError;

  /// 마지막 동기화 시도가 실패/중복이었다면 그 이유입니다. 성공하거나 아직
  /// 시도하지 않았으면 null입니다. 실시간 정리 패널이 이 값을 보여줍니다.
  String? get lastSyncError => _lastSyncError;

  /// 정보가 부족해 ASON이 되묻는 중이거나(정보 수집/분류/수정 답변 대기)일
  /// 때, 지금 사용자에게 보여줄 질문 문구입니다. 별도의 채팅 이력 없이, 이
  /// 값 하나를 정리 패널 안에 표시합니다. 되묻는 중이 아니면(정보가
  /// 충분하거나 아직 아무 것도 입력하지 않았으면) null입니다.
  String? get pendingQuestion {
    final draft = _draft;
    if (draft == null) return null;
    if (draft.status != DraftCommandStatus.collecting &&
        draft.status != DraftCommandStatus.clarifyingCategory &&
        draft.status != DraftCommandStatus.editing) {
      return null;
    }
    return _lastAsonMessageText;
  }

  /// 분류가 아직 없어(따라서 draft가 없어) 정리 패널을 보여줄 수 없을 때도
  /// 사용자에게 전할 안내가 있으면 그 문구입니다. (예: 애매한 일반 대화에
  /// 대한 안내) draft가 있으면 그 안에서 이미 보여주므로 null입니다.
  String? get standaloneGuidance {
    if (_draft != null || _items.isNotEmpty) return null;
    return _lastAsonMessageText;
  }

  String? get _lastAsonMessageText {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final message = _messages[i];
      if (message.sender == ChatSender.ason) return message.text;
    }
    return null;
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

    // 1) 단일 항목 대화가 진행 중이면(후속 질문 답변/수정 답변 등) 그대로
    // 이어갑니다. 기존 동작과 완전히 동일합니다.
    if (_draft != null) {
      _addUser(rawText);
      _lastSyncError = null;
      final result = _brain.process(
        BrainInput(text: rawText, draft: _draft, inputSource: inputSource),
      );
      _draft = result.draft;
      for (final message in result.messages) {
        _addAson(message.text, type: message.type);
      }
      return;
    }

    // 2) 여러 항목 중 하나가 정보 부족으로 답변을 기다리고 있으면, 그 항목에
    // 이어서 답합니다. (한 번에 하나씩만 묻고, 이미 아는 정보는 다시 묻지 않습니다)
    final pendingIndex = _items.indexWhere((item) => item.isPending);
    if (pendingIndex != -1) {
      final current = _items[pendingIndex];
      final result = _brain.process(
        BrainInput(
          text: rawText,
          draft: current.draft,
          inputSource: inputSource,
        ),
      );
      final updatedDraft = result.draft;
      if (updatedDraft == null) return;
      _items[pendingIndex] = ConnectItem(
        draft: updatedDraft,
        pendingQuestion: _questionFrom(result, updatedDraft),
      );
      return;
    }

    // 3) 새 입력입니다. 한 문장에 여러 의도가 섞여 있는지 먼저 나눠 봅니다.
    final clauses = _splitter.splitClauses(rawText);
    if (clauses.length <= 1) {
      _addUser(rawText);
      _lastSyncError = null;
      final result = _brain.process(
        BrainInput(text: rawText, draft: null, inputSource: inputSource),
      );
      _draft = result.draft;
      for (final message in result.messages) {
        _addAson(message.text, type: message.type);
      }
      return;
    }

    // 절이 2개 이상이면, 절 하나하나를 독립된 항목으로 분석해 카드로 보여줍니다.
    for (final clause in clauses) {
      final result = _brain.process(
        BrainInput(text: clause, draft: null, inputSource: inputSource),
      );
      final draft = result.draft;
      // 분류할 수 없는 절은 억지로 항목을 만들지 않고 건너뜁니다.
      if (draft == null) continue;
      _items.add(
        ConnectItem(
          draft: draft,
          pendingQuestion: _questionFrom(result, draft),
        ),
      );
    }
  }

  /// 이번 턴 결과에서, 지금 되묻는 중이면 보여줄 질문 문구를 뽑아냅니다.
  /// 되묻는 중이 아니면(정보가 충분하거나 준비 완료) null입니다.
  String? _questionFrom(BrainResult result, DraftCommand draft) {
    if (draft.status != DraftCommandStatus.collecting &&
        draft.status != DraftCommandStatus.clarifyingCategory &&
        draft.status != DraftCommandStatus.editing) {
      return null;
    }
    if (result.messages.isEmpty) return null;
    return result.messages.last.text;
  }

  /// 여러 항목 중 하나(수정 버튼): 내용을 지우지 않고 무엇을 바꿀지 되묻습니다.
  void beginEditItem(int index) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    if (item.draft.status != DraftCommandStatus.ready) return;
    _items[index] = item.copyWith(
      draft: item.draft.copyWith(status: DraftCommandStatus.editing),
      pendingQuestion: '어떤 내용을 수정할까요?',
    );
  }

  /// 여러 항목 중 하나(동기화 버튼): 동기화 상태로 전환합니다.
  void beginSyncItem(int index) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    if (item.draft.status != DraftCommandStatus.ready) return;
    _items[index] = item.copyWith(
      draft: item.draft.copyWith(status: DraftCommandStatus.syncing),
      clearSyncError: true,
    );
  }

  /// [index] 항목의 실제 동기화를 수행합니다. 성공하면 목록에서 사라지고
  /// (=화면에서 자동으로 정리됨), 실패하면 그 항목에 실패 이유를 남깁니다.
  /// 단일 카드(finishSync)와 완전히 같은 동기화 절차([_syncDraft])를 거칩니다.
  Future<bool> finishSyncItem(int index) async {
    if (index < 0 || index >= _items.length) return false;
    final item = _items[index];
    if (item.draft.status != DraftCommandStatus.syncing) return false;

    final outcome = await _syncDraft(item.draft);
    if (outcome.isSuccess) {
      if (index < _items.length) _items.removeAt(index);
      return true;
    }
    if (index < _items.length) {
      _items[index] = item.copyWith(
        draft: item.draft.copyWith(status: DraftCommandStatus.ready),
        syncError: outcome.errorMessage ?? '동기화 중 오류가 발생했습니다.',
      );
    }
    return false;
  }

  /// 준비된 모든 항목을 순서대로 동기화합니다. 실패한 항목은 목록에 남고,
  /// 실패 이유는 그 항목의 카드에 표시됩니다.
  Future<void> syncAllItems() async {
    var index = 0;
    while (index < _items.length) {
      if (_items[index].draft.status != DraftCommandStatus.ready) {
        index++;
        continue;
      }
      beginSyncItem(index);
      final succeeded = await finishSyncItem(index);
      if (!succeeded) index++;
    }
  }

  /// [rawInput]을 지금 당장 보낸 것처럼 미리 분석해 봅니다. 채팅 이력이나
  /// 실제 draft 상태는 전혀 바꾸지 않는(순수) 미리보기입니다. 사용자가 아직
  /// 전송하지 않고 입력 중인 문장을 실시간 정리 패널에 보여줄 때 사용합니다.
  /// BrainEngine.process 자체가 부작용이 없으므로, 결과를 커밋하지 않는
  /// 방식으로 안전하게 재사용할 수 있습니다(Brain Engine 로직은 그대로입니다).
  DraftCommand? previewDraft(String rawInput) {
    final rawText = rawInput.trim();
    if (rawText.isEmpty) return _draft;

    final result = _brain.process(
      BrainInput(
        text: rawText,
        draft: _draft,
        inputSource: InputSource.unknown,
      ),
    );
    return result.draft;
  }

  /// 실시간 정리 패널의 수정 화면에서, 사용자가 직접 입력한 값으로 필드를
  /// 바로 덮어씁니다. 자연어 재해석 없이(Brain Engine을 거치지 않고) 값만
  /// 바꾸는, 대화형 수정(beginEdit)과는 별개의 경로입니다.
  void updateDraftField({
    String? date,
    String? time,
    String? location,
    String? title,
    String? alarm,
    String? repeatOption,
    String? memo,
  }) {
    final draft = _draft;
    if (draft == null) return;

    _draft = draft.copyWith(
      date: date,
      time: time,
      location: location,
      title: title,
      alarm: alarm,
      repeatOption: repeatOption,
      memo: memo,
      status: draft.status == DraftCommandStatus.synced
          ? DraftCommandStatus.ready
          : draft.status,
    );
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
  /// 다중 카드(finishSyncItem)와 완전히 같은 동기화 절차([_syncDraft])를 거칩니다.
  Future<void> finishSync() async {
    final draft = _draft;
    if (draft == null || draft.status != DraftCommandStatus.syncing) return;

    _lastSyncError = null;
    final outcome = await _syncDraft(draft);

    if (outcome.isSuccess) {
      _draft = draft.copyWith(status: DraftCommandStatus.synced);
      _addAson(
        'ASON Core에 동기화할 준비가 완료되었습니다.',
        type: ChatMessageType.syncComplete,
      );
    } else {
      _lastSyncError = outcome.errorMessage;
      _draft = draft.copyWith(status: DraftCommandStatus.ready);
      _addAson(
        outcome.errorMessage ?? '동기화 중 오류가 발생했습니다.',
        type: ChatMessageType.error,
      );
    }
  }

  /// 단일 카드([finishSync])와 다중 카드([finishSyncItem])가 공통으로 거치는
  /// 동기화 절차입니다. 두 경로가 서로 다른 정책을 쓰지 않도록 이 메서드
  /// 하나로 통일합니다.
  ///
  /// 순서: ① 내용 유효성 검사(비어 있으면 MockSyncService/CoreSyncMapper를
  /// 아예 호출하지 않고 곧바로 실패) → ② MockSyncService(가상 사전 처리) →
  /// ③ CoreSyncMapper(ASON-Core와 같은 구조로 로컬 저장).
  Future<_SyncOutcome> _syncDraft(DraftCommand draft) async {
    if (!draft.hasRequiredContent) {
      return _SyncOutcome.failure(
        draft.validationMessage ?? '내용이 없어 동기화할 수 없습니다.',
      );
    }

    final payload = _summaryBuilder.payload(draft);
    final mockResult = await _syncService.sync(payload);
    if (!mockResult.isSuccess) {
      return _SyncOutcome.failure(
        mockResult.errorMessage ?? '동기화 중 오류가 발생했습니다.',
      );
    }

    try {
      // ASON-Core와 같은 저장 구조(SharedPreferences)에 실제로 반영합니다.
      // 같은 draft(같은 createdAt)를 다시 동기화하면 같은 id로 덮어써서
      // 중복 저장되지 않습니다. 완전히 동일한(다른 id의) 일정이 이미 있으면
      // duplicate로 거부됩니다.
      final coreResult = await _coreSyncMapper.sync(draft);
      if (!coreResult.isSuccess) {
        return _SyncOutcome.failure(
          coreResult.errorMessage ?? '동기화 중 오류가 발생했습니다.',
        );
      }
      return const _SyncOutcome.success();
    } catch (_) {
      return const _SyncOutcome.failure('동기화 중 오류가 발생했습니다.');
    }
  }

  /// 동기화가 끝나면(성공/새 입력 시작) 대화, 작성 중이던 내용, 입력 상태를
  /// 모두 초기화합니다. 대화는 어디에도 저장하지 않으므로, 초기화하면 그대로
  /// 사라집니다.
  void reset() {
    _messages.clear();
    _draft = null;
    _items.clear();
    _lastSyncError = null;
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

/// [ConversationManager._syncDraft]의 결과입니다. 단일/다중 카드가 이 결과
/// 하나를 똑같이 해석해서 각자의 화면 상태(메시지 또는 syncError)로 옮깁니다.
class _SyncOutcome {
  const _SyncOutcome.success() : isSuccess = true, errorMessage = null;
  const _SyncOutcome.failure(String message)
    : isSuccess = false,
      errorMessage = message;

  final bool isSuccess;
  final String? errorMessage;
}
