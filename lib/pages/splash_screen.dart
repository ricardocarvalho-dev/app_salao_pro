import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'redefinir_senha_page.dart';
import '../deep_link_handler.dart';
import 'package:uni_links/uni_links.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _isNavigated = false;
  bool _aguardandoDeepLink = false;

  @override
  void initState() {
    super.initState();

    // Apenas mobile (Android/iOS)
    if (!kIsWeb) {
      DeepLinkHandler.init();
      _checkInitialDeepLink();
    }

    _setupAuthListener();

    // Fallback caso nada aconteça em 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _isNavigated || _aguardandoDeepLink) return;

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _navigateToHome(session);
      } else {
        _navigateToLogin();
      }
    });
  }

  /// Captura deep link inicial (somente mobile)
  Future<void> _checkInitialDeepLink() async {
    if (kIsWeb) return; // Protege o web

    try {
      final initialLink = await getInitialLink();
      if (initialLink != null && mounted) {
        _aguardandoDeepLink = true;
        await DeepLinkHandler.handleInitialLink(initialLink);
      }
    } catch (e) {
      debugPrint('Erro ao capturar deep link inicial: $e');
    }
  }

  void _setupAuthListener() {
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      _onAuthStateChange(event, session);
    });
  }

  void _onAuthStateChange(AuthChangeEvent event, Session? session) {
    if (!mounted || _isNavigated) return;

    // Password recovery disparado pelo Supabase
    if (event == AuthChangeEvent.passwordRecovery) {
      _isNavigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RedefinirSenhaPage()),
      );
      return;
    }

    // Usuário logado
    if (session != null &&
        (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed)) {
      _navigateToHome(session);
    }
  }

  void _navigateToHome(Session session) {
    if (_isNavigated || !mounted) return;

    final salaoId = session.user.userMetadata?['salao_id'] ?? '';
    _isNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage(salaoId: salaoId)),
    );
  }

  void _navigateToLogin() {
    if (_isNavigated || !mounted) return;
    _isNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    if (!kIsWeb) DeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
