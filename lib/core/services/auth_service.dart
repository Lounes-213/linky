import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api_service.dart';
import '../constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _google = GoogleSignIn(
    clientId: kIsWeb ? '985067510832-58bkm6uf22c1klrqf5mj298frajkpmqa.apps.googleusercontent.com' : null,
  );
  final ApiService _api = ApiService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  void setToken(String token) => _api.setToken(token);
  void clearToken() => _api.clearToken();

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _exchangeFirebaseSession(credential.user);
    } catch (e) {
      return null;
    }
  }

  Future<String?> registerWithEmail(String email, String password, String name, {String? username}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      return _exchangeFirebaseSession(credential.user, username: username);
    } catch (e) {
      return null;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _google.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        return _exchangeFirebaseSession(user);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// The API receives an actual Firebase ID token, never an identity supplied by
  /// the client. This prevents account impersonation through a forged UID.
  Future<String?> _exchangeFirebaseSession(User? user, {String? username}) async {
    if (user == null) return null;
    final firebaseToken = await user.getIdToken(true);
    if (firebaseToken == null) return null;
    final response = await _api.post(
      AppConstants.firebaseAuthEndpoint,
      body: {
        'firebase_token': firebaseToken,
        if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
      },
    );
    if (!response.isSuccess || response.data == null) return null;
    // Use the short-lived Firebase token for every protected API call.
    _api.setToken(firebaseToken);
    return firebaseToken;
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
    _api.clearToken();
  }

  Future<bool> refreshFirebaseToken() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdToken(true);
      if (token != null) {
        _api.setToken(token);
        return true;
      }
    } catch (e) {
      debugPrint('refreshFirebaseToken error: $e');
    }
    return false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
