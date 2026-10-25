import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, HttpServer, InternetAddress, HttpClient;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/localization/app_localizations.dart';
import '../main.dart';

const _googleClientIdWeb = '985067510832-58bkm6uf22c1klrqf5mj298frajkpmqa.apps.googleusercontent.com';
const _googleClientIdDesktop = '985067510832-n9jktv8pts8oev83fr72uv5ppaelgg0p.apps.googleusercontent.com';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    try {
      if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        await _signInWithGooglePlugin();
      } else {
        await _signInWithGoogleDesktop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGooglePlugin() async {
    final googleUser = await GoogleSignIn(
      clientId: kIsWeb ? _googleClientIdWeb : null,
      scopes: ['email'],
    ).signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _finishFirebaseAuth(credential);
  }

  Future<void> _signInWithGoogleDesktop() async {
    // ignore: unused_local_variable
    final loc = AppLocalizations.of(context);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final redirectUri = 'http://localhost:$port';

    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': _googleClientIdDesktop,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'access_type': 'offline',
    }).toString();

    await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);

    final codeCompleter = Completer<String>();
    server.listen((request) {
      final code = request.uri.queryParameters['code'];
      if (code != null && !codeCompleter.isCompleted) {
        codeCompleter.complete(code);
      }
      request.response.headers.set('Content-Type', 'text/html; charset=utf-8');
      request.response.write('<html><body><h2>${loc.loginSuccess}</h2><p>${loc.closeWindow}</p></body></html>');
      request.response.close();
    });

    final code = await codeCompleter.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => throw Exception(loc.timeoutError),
    );
    server.close();

    final api = ApiService();
    final res = await api.post('/api/auth/google-desktop', body: {
      'code': code,
      'redirect_uri': redirectUri,
    });

    if (!res.isSuccess || res.data == null) {
      throw Exception(res.error ?? loc.sessionError);
    }

    final firebaseToken = res.data!['firebase_token'] as String?;
    if (firebaseToken == null) throw Exception(loc.tokenNotFound);

    api.setToken(firebaseToken);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  Future<void> _finishFirebaseAuth(OAuthCredential credential) async {
    final loc = AppLocalizations.of(context);
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) return;

    final firebaseToken = await firebaseUser.getIdToken(true);
    if (firebaseToken == null) throw Exception(loc.sessionError);
    final api = ApiService();
    final res = await api.post('/api/auth/firebase', body: {'firebase_token': firebaseToken});
    if (res.isSuccess && res.data != null) {
      api.setToken(firebaseToken);
    } else {
      throw Exception(res.error ?? loc.sessionError);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.asset('assets/logo.png', width: 120, height: 120, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text('Linky', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  const SizedBox(height: 12),
                  Text(loc.connectYourWorld, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16, letterSpacing: 4)),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(clayPrimary(context))))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network('https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg', width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24)),
                                  const SizedBox(width: 12),
                                  Text(loc.connectWithGoogle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      loc.termsAndPrivacy,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
