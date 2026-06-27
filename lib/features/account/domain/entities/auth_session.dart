import 'package:rihla/features/account/domain/entities/auth_provider_type.dart';

/// Active authentication session.
class AuthSession {
  const AuthSession({
    required this.userId,
    this.email,
    this.displayName,
    this.accessToken,
    this.refreshToken,
    this.provider = AuthProviderType.email,
    this.isGuest = false,
    this.emailVerified = false,
    this.expiresAt,
    this.createdAt,
  });

  final String userId;
  final String? email;
  final String? displayName;
  final String? accessToken;
  final String? refreshToken;
  final AuthProviderType provider;
  final bool isGuest;
  final bool emailVerified;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  bool get isAuthenticated => userId.isNotEmpty;
  bool get isSignedIn => isAuthenticated && !isGuest;

  AuthSession copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? accessToken,
    String? refreshToken,
    AuthProviderType? provider,
    bool? isGuest,
    bool? emailVerified,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      provider: provider ?? this.provider,
      isGuest: isGuest ?? this.isGuest,
      emailVerified: emailVerified ?? this.emailVerified,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'provider': provider.name,
        'isGuest': isGuest,
        'emailVerified': emailVerified,
        'expiresAt': expiresAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      provider: AuthProviderType.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AuthProviderType.guest,
      ),
      isGuest: json['isGuest'] as bool? ?? false,
      emailVerified: json['emailVerified'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static const guest = AuthSession(
    userId: 'guest',
    isGuest: true,
    provider: AuthProviderType.guest,
  );
}
