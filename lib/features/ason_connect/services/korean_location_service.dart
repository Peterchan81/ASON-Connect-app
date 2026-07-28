// 문장 안에서 대한민국 지역명을 찾아내는 서비스입니다.
// 외부 지도 API 없이, (1) 주요 지역명 사전 + (2) 행정구역/장소 접미사 정규식
// 두 가지 방식을 함께 사용하는 규칙 기반 로직입니다.

/// 장소 추출 결과입니다.
/// [text]는 확실하게 인식된 장소이고, 확실하지 않으면 null입니다.
/// 이때는 [uncertainOriginal]/[uncertainGuess]에 "이 표현이 아마 이 지역일 것"이라는
/// 추정값이 담기고, 화면에서는 사용자에게 되물어 확인합니다.
class LocationExtractionResult {
  const LocationExtractionResult({
    this.text,
    this.uncertainOriginal,
    this.uncertainGuess,
  });

  final String? text;
  final String? uncertainOriginal;
  final String? uncertainGuess;

  bool get isConfident => text != null;
  bool get isUncertain => text == null && uncertainGuess != null;
  bool get isEmpty => text == null && uncertainGuess == null;
}

class KoreanLocationService {
  // 광역 지역명(정식 명칭/축약형/캐주얼 표현) -> 축약형(표준 표기) 정규화 표입니다.
  // 매칭 시 긴 표현을 먼저 검사할 수 있도록 아래 _provinceKeysByLength에서 길이순 정렬해 사용합니다.
  static const Map<String, String> _provinceNormalization = {
    '서울특별시': '서울',
    '서울시': '서울',
    '서울': '서울',
    '부산광역시': '부산',
    '부산시': '부산',
    '부산': '부산',
    '대구광역시': '대구',
    '대구시': '대구',
    '대구': '대구',
    '인천광역시': '인천',
    '인천시': '인천',
    '인천': '인천',
    '광주광역시': '광주',
    '광주시': '광주',
    '광주': '광주',
    '대전광역시': '대전',
    '대전시': '대전',
    '대전': '대전',
    '울산광역시': '울산',
    '울산시': '울산',
    '울산': '울산',
    '세종특별자치시': '세종',
    '세종시': '세종',
    '세종': '세종',
    '경기도': '경기',
    '경기': '경기',
    '강원특별자치도': '강원',
    '강원도': '강원',
    '강원': '강원',
    '충청북도': '충북',
    '충북': '충북',
    '충청남도': '충남',
    '충남': '충남',
    '전북특별자치도': '전북',
    '전라북도': '전북',
    '전북': '전북',
    '전라남도': '전남',
    '전남': '전남',
    '경상북도': '경북',
    '경북': '경북',
    '경상남도': '경남',
    '경남': '경남',
    '제주특별자치도': '제주',
    '제주도': '제주',
    '제주': '제주',
  };

  // 길이가 긴 표현부터 매칭해야 "제주" 대신 "제주도"가 통째로 잡힙니다.
  static final List<String> _provinceKeysByLength =
      _provinceNormalization.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

  // 접미사만으로는 잘 안 잡히는(또는 접미사가 없는) 유명 동네를 소속 도시와 함께 기억해 둡니다.
  // 값이 null이면 이미 그 자체로 충분히 유명해서 광역 지역명을 덧붙이지 않습니다.
  static const Map<String, String?> _knownDistrictCity = {
    '둔산동': '대전',
    '불당동': '천안',
    '복대동': '청주',
    '나성동': '세종',
    '애월': '제주',
    '해운대': '부산',
    '홍대': null,
    '성수동': null,
    '강남역': null,
  };

  static final List<String> _knownDistrictKeysByLength =
      _knownDistrictCity.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

  // 이미 그 자체로 잘 알려진 지명(홍대/성수동/강남역 등)은 일부만 말해도 다른 뜻일 수 있어
  // "되묻기" 후보에서는 제외하고, 상대적으로 덜 알려진 동네만 되묻기 대상으로 둡니다.
  static const List<String> _fuzzyGuessCandidates = [
    '둔산동',
    '불당동',
    '복대동',
    '나성동',
    '해운대',
  ];

  // 행정구역 접미사입니다. 긴 표현을 먼저 검사합니다.
  static const List<String> _adminSuffixes = [
    '특별자치시',
    '특별자치도',
    '광역시',
    '특별시',
    '자치시',
    '자치도',
    '시',
    '군',
    '구',
    '동',
    '읍',
    '면',
    '리',
  ];

  // 역, 터미널, 공항, 병원, 학교, 회사, 카페 등 장소성 단어입니다.
  static const List<String> _landmarkSuffixes = [
    '터미널',
    '공항',
    '병원',
    '학교',
    '회사',
    '카페',
    '역',
  ];

  static final RegExp _suffixPattern = RegExp(
    '[가-힣A-Za-z0-9]{1,8}(?:${[..._adminSuffixes, ..._landmarkSuffixes].join('|')})',
  );

  // 이름 없이 "병원"/"카페"처럼 종류만 언급된 경우를 찾습니다. 앞뒤에 한글이
  // 붙어 있으면(예: "지역"의 "역") 오탐이므로 제외합니다.
  static final RegExp _bareLandmarkPattern = RegExp(
    '(?<![가-힣])(${_landmarkSuffixes.join('|')})(?![가-힣])',
  );

  // 장소 뒤에 붙어도 장소의 일부로 유지할 표현입니다. (근처/앞/안/주변)
  static final RegExp _proximityPattern = RegExp(r'^\s*(근처|앞|안|주변)');

  /// 문장에서 대한민국 지역명 후보를 찾아냅니다.
  /// 확실한 장소를 찾으면 [LocationExtractionResult.text]에 담아 돌려주고,
  /// 부분적으로만 비슷한 표현(예: "둔산")이 있으면 되물을 수 있도록 uncertain 값을 채워줍니다.
  LocationExtractionResult extractLocation(String text) {
    final normalizedInput = fixSpacingArtifacts(text);

    final confident = _findConfidentLocation(normalizedInput);
    if (confident != null) {
      return LocationExtractionResult(text: confident);
    }

    final guess = _findFuzzyDistrictGuess(normalizedInput);
    if (guess != null) {
      return LocationExtractionResult(
        uncertainOriginal: guess.$1,
        uncertainGuess: guess.$2,
      );
    }

    return const LocationExtractionResult();
  }

  /// 문장 안에서 명확하게 인식되는 지역명 하나를 돌려줍니다. 없으면 null입니다.
  String? _findConfidentLocation(String text) {
    // 1) 접미사가 없는 유명 동네(사전)를 먼저 찾습니다. 예: 애월, 해운대, 홍대
    int matchStart = -1;
    int matchEnd = -1;
    String? base;

    for (final name in _knownDistrictKeysByLength) {
      final idx = text.indexOf(name);
      if (idx != -1) {
        base = name;
        matchStart = idx;
        matchEnd = idx + name.length;
        break;
      }
    }

    // 2) 사전에 없으면 행정구역/장소 접미사 정규식으로 찾습니다. 예: 둔산동, 유성구, 강남역
    if (base == null) {
      final match = _suffixPattern.firstMatch(text);
      if (match == null) return null;
      base = match.group(0)!;
      matchStart = match.start;
      matchEnd = match.end;
    }

    // 3) 바로 뒤에 근처/앞/안/주변이 오면 장소 표현의 일부로 포함합니다.
    final rest = text.substring(matchEnd);
    final proximityMatch = _proximityPattern.firstMatch(rest);
    var candidate = base;
    if (proximityMatch != null) {
      candidate = '$base ${proximityMatch.group(1)}';
    }

    // 4) 바로 앞에 광역 지역명이 있으면 함께 붙입니다. 예: "대전 둔산동"
    final before = text.substring(0, matchStart).trimRight();
    String? attachedProvince;
    for (final province in _provinceKeysByLength) {
      if (before.endsWith(province)) {
        attachedProvince = province;
        break;
      }
    }

    String? provinceShort = attachedProvince != null
        ? _provinceNormalization[attachedProvince]
        : null;

    // 5) 광역 지역명이 없고, 사전에 등록된 동네라면 소속 도시를 자동으로 붙여줍니다.
    provinceShort ??= _knownDistrictCity[base];

    if (provinceShort != null) {
      candidate = '$provinceShort $candidate';
    }

    return candidate;
  }

  /// 확실한 지역명은 없지만, 알려진 동네 이름의 앞부분과 비슷한 표현이 있으면
  /// (원래 표현, 추정 지역명) 형태로 돌려줍니다. 예: "둔산" -> ("둔산", "대전 둔산동")
  (String, String)? _findFuzzyDistrictGuess(String text) {
    for (final name in _fuzzyGuessCandidates) {
      final stem = name.substring(
        0,
        name.length - 1,
      ); // 마지막 글자를 뺀 부분 (동/읍 등 제외)
      if (stem.length < 2) continue;
      if (text.contains(name)) continue; // 이미 완전히 일치하면 확실한 매칭에서 처리됩니다.

      final idx = text.indexOf(stem);
      if (idx == -1) continue;

      final city = _knownDistrictCity[name];
      final guess = city != null ? '$city $name' : name;
      return (stem, guess);
    }
    return null;
  }

  /// 확실한 장소도, 되물을 만한 동네도 아니지만 "병원"처럼 종류만 언급된 경우
  /// 그 단어를 그대로 돌려줍니다. (예: "병원 예약" -> "병원"). 그런 표현이 없으면 null.
  String? findGenericLandmark(String text) {
    final normalized = fixSpacingArtifacts(text);
    if (_findConfidentLocation(normalized) != null) return null;
    return _bareLandmarkPattern.firstMatch(normalized)?.group(1);
  }

  /// 광역 지역명 표현을 표준 축약형으로 정규화합니다. (예: "제주도" -> "제주")
  String normalizeProvince(String token) {
    return _provinceNormalization[token] ?? token;
  }

  /// 음성 인식 결과에서 자주 생기는 지역명 관련 띄어쓰기를 가볍게 보정합니다.
  /// 사용자 원문 자체를 바꾸는 것이 아니라, 분석용으로만 사용하는 보정본을 만듭니다.
  String fixSpacingArtifacts(String text) {
    const spacingFixes = {
      '둔산 동': '둔산동',
      '유성 구': '유성구',
      '강남 역': '강남역',
      '해운 대': '해운대',
      '제주 도': '제주도',
      '세종 시': '세종시',
    };

    var result = text;
    spacingFixes.forEach((wrong, correct) {
      result = result.replaceAll(wrong, correct);
    });
    return result;
  }
}
