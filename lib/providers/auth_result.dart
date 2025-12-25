import '../models/user.dart';

class AuthResult {
  final User user;
  final String token;

  AuthResult({
    required this.user,
    required this.token,
  });
}
