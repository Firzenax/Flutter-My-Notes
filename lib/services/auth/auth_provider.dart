import "package:tuto/services/auth/auth_user.dart";

abstract class AuthProvider {
  AuthUser? get currentUser;
  Future<AuthUser> logIn({required String email, required String password});
  Future<AuthUser> createUser(
      {required String email, required String password});
  Future<void> logout();
  Future<void> sendEmailVerification();
}