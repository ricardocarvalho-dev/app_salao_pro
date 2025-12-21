class SignInWithApple {
  static Future<dynamic> getAppleIDCredential({
    List<dynamic>? scopes,
    String? nonce, // 👈 Adicione este parâmetro
  }) async {
    return null;
  }
}

class AppleIDAuthorizationScopes {
  static const email = 'email';
  static const fullName = 'fullName';
}
