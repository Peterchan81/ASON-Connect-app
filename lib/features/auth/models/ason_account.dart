// ASON Connect 로컬 계정 한 건입니다. (기기 안에서만 저장/검증됩니다)
// 비밀번호는 원문이 아니라 해시 값만 저장합니다.

class AsonAccount {
  const AsonAccount({
    required this.nickname,
    required this.id,
    required this.email,
    required this.passwordHash,
  });

  final String nickname;
  final String id;
  final String email;
  final String passwordHash;

  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'id': id,
    'email': email,
    'passwordHash': passwordHash,
  };

  factory AsonAccount.fromJson(Map<String, dynamic> json) {
    return AsonAccount(
      nickname: json['nickname'] as String,
      id: json['id'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
    );
  }
}
