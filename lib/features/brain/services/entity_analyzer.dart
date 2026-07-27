// 문장에서 카테고리별 필요한 값(날짜/시간/장소/내용/건강 수치 등)을 뽑아내는
// 인터페이스입니다. RuleBasedEntityAnalyzer 외에 향후 GPT/Gemini 기반 구현으로
// 교체할 수 있도록 분리했습니다.

import '../../ason_connect/models/draft_command.dart';
import '../../ason_connect/services/field_correction_parser.dart';
import '../models/entity_result.dart';

abstract class EntityAnalyzer {
  /// [category]에 맞는 값을 [text]에서 뽑아냅니다. (장소가 불확실하면 pendingLocation*로)
  EntityResult extract(DraftCommandCategory category, String text);

  /// "수정" 대화에서 사용자가 어떤 항목을 어떤 값으로 바꾸려는지 해석합니다.
  /// [availableFields]는 지금 카테고리에서 수정할 수 있는 항목 key 목록입니다.
  FieldCorrection? parseCorrection(String text, List<String> availableFields);
}
