import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import '../deep_link_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigated = false;
  bool _aguardandoDeepLink = false;

  @override
  void initState() {
    super.initState();

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

  Future<void> _checkInitialDeepLink() async {
    try {
      final initialLink = await AppLinks().getInitialAppLink();
      if (initialLink != null) {
        debugPrint('Deep link inicial detectado: $initialLink');
        _aguardandoDeepLink = true;

        // Processa o link e navega direto para redefinição
        await DeepLinkHandler.handleInitialLink(initialLink.toString());
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/redefinir-senha');
          _isNavigated = true;
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar deep link inicial: $e');
    }
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null && !_isNavigated) {
        _navigateToHome(session);
      }
    });
  }

  void _navigateToHome(Session session) {
    if (!mounted) return;
    _isNavigated = true;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _navigateToLogin() {
    if (!mounted) return;
    _isNavigated = true;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
