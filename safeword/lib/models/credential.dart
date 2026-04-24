class Credential {
  final String id;
  final String userId;
  final String title;
  final String? username;
  final String password; // encrypted
  final String? moreInfo;
  final String? category;
  final String iv;
  final String salt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Decrypted password – only populated client-side after decryption.
  /// Never serialized to JSON.
  String? decryptedPassword;

  Credential({
    required this.id,
    required this.userId,
    required this.title,
    this.username,
    required this.password,
    this.moreInfo,
    this.category,
    required this.iv,
    required this.salt,
    required this.createdAt,
    required this.updatedAt,
    this.decryptedPassword,
  });

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String,
      username: json['username'] as String?,
      password: json['password'] as String,
      moreInfo: json['more_info'] as String?,
      category: json['category'] as String?,
      iv: json['iv'] as String,
      salt: json['salt'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'username': username,
      'password': password,
      'more_info': moreInfo,
      'category': category,
      'iv': iv,
      'salt': salt,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Credential copyWith({
    String? id,
    String? userId,
    String? title,
    String? username,
    String? password,
    String? moreInfo,
    String? category,
    String? iv,
    String? salt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? decryptedPassword,
  }) {
    return Credential(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      moreInfo: moreInfo ?? this.moreInfo,
      category: category ?? this.category,
      iv: iv ?? this.iv,
      salt: salt ?? this.salt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      decryptedPassword: decryptedPassword ?? this.decryptedPassword,
    );
  }
}
