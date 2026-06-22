class AuthResult {
  final String accessToken;
  final String userId;
  final String username;

  const AuthResult({
    required this.accessToken,
    required this.userId,
    required this.username,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final user = json['User'];

    return AuthResult(
      accessToken: json['AccessToken'],
      userId: user['Id'],
      username: user['Name'],
    );
  }
}
