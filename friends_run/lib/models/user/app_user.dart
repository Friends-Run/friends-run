class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? profileImageUrl;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  // Método fromJson (equivalente ao fromMap existente)
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  // Método toJson (equivalente ao toMap existente)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Mantendo os métodos fromMap e toMap existentes para compatibilidade
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? profileImageUrl,
  }) {
    return AppUser(
      // If a new value is provided (not null), use it. Otherwise, keep the current value.
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}