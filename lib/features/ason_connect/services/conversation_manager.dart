// 대화 전체를 관리하는 서비스입니다.
// 채팅 메시지 목록, 지금 작성 중인 DraftCommand, 분류/질문/수정/동기화 상태를
// 이 클래스 하나가 책임집니다. 화면(위젯)은 이 결과만 읽어서 그립니다.
//
// 대화 내용은 메모리에서만 관리하며, 어디에도 영구 저장하지 않습니다.

import '../models/chat_message.dart';
import '../models/draft_command.dart';
import '../models/sync_payload.dart';
import 'command_parser_service.dart';
import 'korean_location_service.dart';
import 'mock_sync_service.dart';

class ConversationManager {
  factory ConversationManager({
    CommandParserService? parser,
    KoreanLocationService? locationService,
    MockSyncService? syncService,
  }) {
    final resolvedLocationService = locationService ?? KoreanLocationService();
    return ConversationManager._(
      parser:
          parser ??
          CommandParserService(locationService: resolvedLocationService),
      locationService: resolvedLocationService,
      syncService: syncService ?? MockSyncService(),
    );
  }

  ConversationManager._({
    required this._parser,
    required this._locationService,
    required this._syncService,
  }) {
    _addAson(_greetingText);
  }

  final CommandParserService _parser;
  final KoreanLocationService _locationService;
  final MockSyncService _syncService;

  // 한 번에 묶어서 물어볼 수 있는 항목의 최대 개수입니다.
  static const int _maxBatchSize = 3;

  static const String _greetingText =
      '안녕하세요.\n일정, 메모, 건강에 관한 내용을 말씀해 주세요.\nASON 통합 시스템에 정리해서 공유해 드리겠습니다.';

  final List<ChatMessage> _messages = [];

  /// 지금까지 주고받은 모든 메시지입니다. (읽기 전용, 영구 저장되지 않습니다)
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  DraftCommand? _draft;

  /// 지금 작성 중인 내용입니다. 없으면 null입니다.
  DraftCommand? get currentDraft => _draft;

  int _seq = 0;
  int _generalReplyIndex = 0;

  static const List<String> _moodWords = [
    '기분',
    '힘들',
    '피곤',
    '우울',
    '스트레스',
    '속상',
    '짜증',
    '불안',
    '걱정',
  ];
  static final RegExp _pastActivityPattern = RegExp(
    r'(했어|했다|먹었|갔다|갔어|만났|봤어|봤다|끝났|다녀왔|보냈)',
  );
  static const List<String> _genericRedirects = [
    '저는 사용자의 일정, 메모, 건강에 관한 내용을 정리하고\nASON 통합 시스템에 공유하도록 도와드립니다.',
    '이 내용을 메모로 남기거나 ASON에 공유할 수 있습니다.',
  ];
  static const List<String> _affirmativeWords = [
    '네',
    '응',
    '예',
    '맞아',
    '맞습니다',
    '어',
    'ㅇㅇ',
    '넵',
  ];
  static const List<String> _negativeWords = ['아니', '아니요', '아니에요', 'no', 'No'];

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
    return _buildSyncPayload(draft);
  }

  /// 확인 카드 제목입니다.
  String? get summaryTitle {
    final draft = _draft;
    if (draft == null || !isSummaryAvailable) return null;
    return '${draft.category!.label} 요약';
  }

  /// 확인 카드에 정해진 순서대로 보여줄 라벨-값 목록입니다.
  /// 일정은 반드시 시간 → 내용 → 장소 → 알림 → 반복 → 메모 순서로 보여줍니다.
  List<MapEntry<String, String>> get summaryRows {
    final draft = _draft;
    if (draft == null || !isSummaryAvailable) return const [];

    switch (draft.category!) {
      case DraftCommandCategory.schedule:
        return [
          MapEntry('시간', _combinedTime(draft)),
          MapEntry('내용', draft.title ?? '-'),
          MapEntry('장소', draft.location ?? '-'),
          MapEntry('알림', draft.alarm ?? '없음'),
          MapEntry('반복', draft.repeatOption ?? '없음'),
          MapEntry('메모', draft.memo ?? '-'),
        ];
      case DraftCommandCategory.health:
        return [
          MapEntry('항목', draft.healthItem ?? '-'),
          MapEntry('내용', draft.title ?? '-'),
          MapEntry('날짜', draft.date ?? '-'),
        ];
      case DraftCommandCategory.memo:
      case DraftCommandCategory.project:
      case DraftCommandCategory.todo:
        return [MapEntry('내용', draft.title ?? '-')];
    }
  }

  /// 일정의 날짜+시간을 "오늘 오후 3시"처럼 하나의 표시용 문자열로 합칩니다.
  String _combinedTime(DraftCommand draft) {
    final parts = [
      draft.date,
      draft.time,
    ].where((value) => value != null && value.trim().isNotEmpty);
    return parts.isEmpty ? '-' : parts.join(' ');
  }

  /// 사용자가 문자 또는 음성으로 전달한 문장 하나를 처리합니다.
  void handleUserText(String rawInput) {
    final rawText = rawInput.trim();
    if (rawText.isEmpty) return;

    _addUser(rawText);

    final draft = _draft;

    if (draft != null &&
        draft.status == DraftCommandStatus.clarifyingCategory) {
      _resolveCategoryClarification(draft, rawText);
      return;
    }

    if (draft != null && draft.status == DraftCommandStatus.editing) {
      _continueEditing(draft, rawText);
      return;
    }

    if (draft != null &&
        draft.status == DraftCommandStatus.collecting &&
        draft.category == DraftCommandCategory.schedule) {
      _continueSchedule(draft, rawText);
      return;
    }

    // 이전 내용이 이미 끝났거나(ready/synced) 없으면, 새 주제로 시작합니다.
    _startNewTopic(rawText);
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

    final payload = _buildSyncPayload(draft);
    final result = await _syncService.sync(payload);

    if (result.isSuccess) {
      _draft = draft.copyWith(status: DraftCommandStatus.synced);
      _addAson(
        'ASON Core에 동기화할 준비가 완료되었습니다.',
        type: ChatMessageType.syncComplete,
      );
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

  void _startNewTopic(String rawText) {
    final analysisText = _locationService.fixSpacingArtifacts(rawText);
    final classification = _parser.classify(analysisText);

    if (classification.isUnclassified) {
      _draft = null;
      _addAson(_buildGeneralReply(rawText));
      return;
    }

    if (classification.isAmbiguous) {
      final first = classification.best;
      final second = classification.second!;
      _draft = DraftCommand(
        originalText: rawText,
        status: DraftCommandStatus.clarifyingCategory,
        candidateCategories: [first, second],
      );
      _addAson(
        '이 내용을 ${first.label}${_euroRo(first.label)} 정리할까요, '
        '${second.label}${_euroRo(second.label)} 정리할까요?',
        type: ChatMessageType.question,
      );
      return;
    }

    _beginDraftForCategory(classification.best, analysisText, rawText);
  }

  void _resolveCategoryClarification(DraftCommand draft, String rawText) {
    DraftCommandCategory? chosen;
    final normalizedReply = rawText.replaceAll(' ', '');
    for (final candidate in draft.candidateCategories) {
      if (normalizedReply.contains(candidate.label.replaceAll(' ', ''))) {
        chosen = candidate;
        break;
      }
    }
    chosen ??= draft.candidateCategories.isNotEmpty
        ? draft.candidateCategories.first
        : null;

    if (chosen == null) {
      _draft = null;
      _addAson(_buildGeneralReply(rawText));
      return;
    }

    final analysisText = _locationService.fixSpacingArtifacts(
      draft.originalText,
    );
    _beginDraftForCategory(chosen, analysisText, draft.originalText);
  }

  void _continueEditing(DraftCommand draft, String rawText) {
    final fields = _correctionFieldsFor(draft);
    final correction = _parser.parseFieldCorrection(rawText, fields);

    if (correction == null) {
      _addAson('어떤 항목을 어떻게 바꿀지 다시 말씀해 주세요.', type: ChatMessageType.question);
      return;
    }

    final updated = _parser.applyFieldCorrection(draft, correction);
    final label =
        CommandParserService.fieldKeyToLabel[correction.field] ?? '내용';
    // 실제로 저장된 값을 기준으로 안내합니다. (예: "없어" -> "없음"으로 정리된 경우 반영)
    final appliedValue =
        _parser.scheduleFieldValue(updated, correction.field) ??
        correction.newValue;

    _draft = updated.copyWith(status: DraftCommandStatus.ready);
    _addAson(
      '$label${_eulReul(label)} $appliedValue${_euroRo(appliedValue)} 변경했습니다.',
    );
    _showReadyCard();
  }

  List<String> _correctionFieldsFor(DraftCommand draft) {
    switch (draft.category) {
      case DraftCommandCategory.schedule:
        return const [
          'date',
          'time',
          'location',
          'title',
          'alarm',
          'repeat',
          'memo',
        ];
      case DraftCommandCategory.health:
        return const ['date', 'healthItem', 'title'];
      case DraftCommandCategory.memo:
      case DraftCommandCategory.project:
      case DraftCommandCategory.todo:
        return const ['title'];
      case null:
        return const [];
    }
  }

  void _beginDraftForCategory(
    DraftCommandCategory category,
    String analysisText,
    String rawText,
  ) {
    switch (category) {
      case DraftCommandCategory.schedule:
        _beginSchedule(analysisText, rawText);
        break;
      case DraftCommandCategory.memo:
      case DraftCommandCategory.project:
      case DraftCommandCategory.todo:
        _beginSimpleContent(category, analysisText, rawText);
        break;
      case DraftCommandCategory.health:
        _beginHealth(analysisText, rawText);
        break;
    }
  }

  void _beginSchedule(String analysisText, String rawText) {
    final extracted = _parser.extractScheduleFields(analysisText);
    var draft = DraftCommand(
      originalText: rawText,
      status: DraftCommandStatus.collecting,
      category: DraftCommandCategory.schedule,
      date: extracted.date,
      time: extracted.time,
      location: extracted.location,
      title: extracted.title,
      pendingLocationGuess: extracted.pendingLocationGuess,
      pendingLocationOriginal: extracted.pendingLocationOriginal,
    );

    if (_parser.allMissingScheduleFields(draft).isEmpty) {
      draft = draft.copyWith(status: DraftCommandStatus.ready);
      _draft = draft;
      _showReadyCard();
      return;
    }

    _draft = draft;
    _askForSchedule(draft);
  }

  /// 이미 알고 있는 내용은 다시 묻지 않고, 부족한 내용만 최대 [_maxBatchSize]개씩 묶어서 질문합니다.
  /// 장소가 불확실할 때만 예외적으로, 다른 질문보다 먼저 단독으로 확인합니다.
  void _askForSchedule(DraftCommand draft) {
    if (draft.pendingLocationGuess != null &&
        (draft.location ?? '').trim().isEmpty) {
      _addAson(
        _parser.questionForScheduleField('location', draft),
        type: ChatMessageType.question,
      );
      return;
    }

    final batch = _currentScheduleBatch(draft);
    if (batch.isEmpty) return;

    if (batch.length == 1) {
      final field = batch.first;
      final question = _parser.questionForScheduleField(field, draft);
      // 다른 항목이 이미 다 채워진 상태에서 알림만 남았다면, 자연스러운 확인 인사를 덧붙입니다.
      final prefixed = field == 'alarm' ? '일정을 확인했습니다.\n$question' : question;
      _addAson(prefixed, type: ChatMessageType.question);
      return;
    }

    _addAson(_buildBatchQuestion(batch), type: ChatMessageType.question);
  }

  /// 이번 턴에 실제로 물어볼 항목입니다. 부족한 항목이 많아도 최대 [_maxBatchSize]개까지만
  /// 먼저 묻고, 나머지는 답변을 받은 뒤 다음 턴에 이어서 묻습니다.
  List<String> _currentScheduleBatch(DraftCommand draft) {
    final missing = _parser.allMissingScheduleFields(draft);
    return missing.length > _maxBatchSize
        ? missing.sublist(0, _maxBatchSize)
        : missing;
  }

  /// 부족한 항목 여러 개를 한 번에 묻는 문구를 만듭니다.
  /// 예: "① 시간 ② 알림 여부" — 답변은 줄바꿈 또는 쉼표로 구분해 한 번에 받을 수 있습니다.
  String _buildBatchQuestion(List<String> fields) {
    const numbering = ['①', '②', '③', '④', '⑤'];
    final buffer = StringBuffer('일정을 등록하기 위해\n다음 내용을 알려주세요.\n\n');

    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final label =
          CommandParserService.scheduleBatchLabel[field] ??
          CommandParserService.fieldKeyToLabel[field] ??
          field;
      final mark = numbering[i % numbering.length];
      buffer.writeln('$mark $label');
    }

    buffer.write('\n한 번에 답변하셔도 됩니다.');
    return buffer.toString();
  }

  void _continueSchedule(DraftCommand draft, String rawAnswer) {
    // 장소 확인 질문("~가 맞나요?")에 대한 단독 답변인 경우입니다.
    if (draft.pendingLocationGuess != null &&
        (draft.location ?? '').trim().isEmpty) {
      _resolveLocationConfirmation(draft, rawAnswer);
      return;
    }

    final batch = _currentScheduleBatch(draft);
    if (batch.isEmpty) {
      _draft = draft;
      return;
    }

    // 사용자가 줄바꿈이나 쉼표로 구분해서 여러 답을 한 번에 줄 수 있습니다.
    final segments = rawAnswer
        .split(RegExp(r'[\n,]'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    var updated = draft;
    final answerCount = segments.length < batch.length
        ? segments.length
        : batch.length;
    for (var i = 0; i < answerCount; i++) {
      final field = batch[i];
      // 알림 질문에 "아니요"처럼 거절 의사를 밝히면 "없음"으로 정리합니다.
      final value = field == 'alarm' && _isNegative(segments[i])
          ? '없음'
          : segments[i];
      updated = _parser.assignScheduleField(updated, field, value);
    }

    if (_parser.allMissingScheduleFields(updated).isEmpty) {
      updated = updated.copyWith(status: DraftCommandStatus.ready);
      _draft = updated;
      _showReadyCard();
      return;
    }

    _draft = updated;
    _askForSchedule(updated);
  }

  void _resolveLocationConfirmation(DraftCommand draft, String rawAnswer) {
    DraftCommand updated;

    if (_isAffirmative(rawAnswer)) {
      updated = _parser.assignScheduleField(
        draft,
        'location',
        draft.pendingLocationGuess!,
      );
    } else if (_isNegative(rawAnswer)) {
      _draft = draft.copyWith(clearPendingLocation: true);
      _addAson('장소를 다시 알려주세요.', type: ChatMessageType.question);
      return;
    } else {
      // 그 외 응답은 사용자가 직접 말해준 새 지명으로 보고 그대로 사용합니다.
      updated = _parser.assignScheduleField(draft, 'location', rawAnswer);
    }

    if (_parser.allMissingScheduleFields(updated).isEmpty) {
      updated = updated.copyWith(status: DraftCommandStatus.ready);
      _draft = updated;
      _showReadyCard();
      return;
    }

    _draft = updated;
    _askForSchedule(updated);
  }

  void _beginSimpleContent(
    DraftCommandCategory category,
    String analysisText,
    String rawText,
  ) {
    final content =
        (category == DraftCommandCategory.memo ||
            category == DraftCommandCategory.todo)
        ? _parser.normalizeMemoContent(analysisText)
        : _parser.cleanFreeformContent(analysisText);

    _draft = DraftCommand(
      originalText: rawText,
      status: DraftCommandStatus.ready,
      category: category,
      title: content,
    );
    _showReadyCard();
  }

  void _beginHealth(String analysisText, String rawText) {
    final extracted = _parser.extractHealthFields(analysisText);
    _draft = DraftCommand(
      originalText: rawText,
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.health,
      date: extracted.date,
      healthItem: extracted.item,
      title: extracted.value,
    );
    _showReadyCard();
  }

  /// 대화창에 "이 내용만 동기화합니다" 안내를 표시합니다.
  /// 실제 요약 내용은 별도의 확인 카드(위젯)에서 SyncPayload 기준으로 보여줍니다.
  void _showReadyCard() {
    _addAson('ASON에 다음 내용만 동기화합니다.', type: ChatMessageType.summary);
  }

  /// 지금 draft로 SyncPayload를 만듭니다. 대화 원문 전체가 아니라, 정리된 핵심만 담습니다.
  SyncPayload _buildSyncPayload(DraftCommand draft) {
    final category = draft.category!;

    switch (category) {
      case DraftCommandCategory.schedule:
        return SyncPayload(
          category: category.label,
          content: draft.title ?? '-',
          time: _combinedTime(draft),
          location: draft.location,
          alarm: draft.alarm ?? '없음',
          repeat: draft.repeatOption ?? '없음',
          memo: draft.memo ?? '-',
          createdAt: draft.createdAt,
          updatedAt: draft.updatedAt,
        );
      case DraftCommandCategory.health:
        final item = draft.healthItem ?? '';
        final value = draft.title ?? '';
        return SyncPayload(
          category: category.label,
          content: [item, value].where((part) => part.isNotEmpty).join(' : '),
          time: draft.date,
          createdAt: draft.createdAt,
          updatedAt: draft.updatedAt,
        );
      case DraftCommandCategory.memo:
      case DraftCommandCategory.project:
      case DraftCommandCategory.todo:
        return SyncPayload(
          category: category.label,
          content: draft.title ?? '-',
          createdAt: draft.createdAt,
          updatedAt: draft.updatedAt,
        );
    }
  }

  String _buildGeneralReply(String text) {
    if (_moodWords.any((word) => text.contains(word))) {
      return '오늘 컨디션이 좋지 않으셨군요.\n이 내용을 건강 기록이나 메모로 정리할까요?';
    }
    if (_pastActivityPattern.hasMatch(text)) {
      return '그런 하루를 보내셨군요.\n오늘의 일정이나 메모로 남길까요?';
    }
    final reply =
        _genericRedirects[_generalReplyIndex % _genericRedirects.length];
    _generalReplyIndex++;
    return reply;
  }

  bool _isAffirmative(String text) {
    final trimmed = text.trim();
    return _affirmativeWords.any(
      (word) => trimmed == word || trimmed.startsWith(word),
    );
  }

  bool _isNegative(String text) {
    final trimmed = text.trim();
    return _negativeWords.any(
      (word) => trimmed == word || trimmed.startsWith(word),
    );
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

  // 한글 조사(을/를, 으로/로)를 받침 유무에 맞게 골라줍니다. ('ㄹ' 받침은 '로'를 씁니다)
  String _eulReul(String word) {
    if (word.isEmpty) return '를';
    final code = word.codeUnitAt(word.length - 1);
    if (code < 0xAC00 || code > 0xD7A3) return '를';
    final hasBatchim = (code - 0xAC00) % 28 != 0;
    return hasBatchim ? '을' : '를';
  }

  String _euroRo(String word) {
    if (word.isEmpty) return '로';
    final code = word.codeUnitAt(word.length - 1);
    if (code < 0xAC00 || code > 0xD7A3) return '로';
    final batchimIndex = (code - 0xAC00) % 28;
    return (batchimIndex == 0 || batchimIndex == 8) ? '로' : '으로';
  }
}
