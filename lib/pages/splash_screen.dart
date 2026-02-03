import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import '../deep_link_handler.dart';
import 'package:app_salao_pro/pages/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    // 1. Inicia DeepLinks se não for Web
    if (!kIsWeb) {
      DeepLinkHandler.init();
      final linkInicial = await _checkInitialDeepLink();
      if (linkInicial) return; // Se navegou por DeepLink, para aqui
    }

    // 2. O WATCHDOG: Teste real de integridade do Supabase
    await _verificarIntegridadeESessao();
  }

  Future<void> _verificarIntegridadeESessao() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      _navigateToLogin();
      return;
    }

    try {
      debugPrint('🛡️ Watchdog: Testando conexão com Supabase...');
      
      await client
          .from('profiles')
          .select('id')
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      debugPrint('✅ Watchdog: Conexão íntegra.');
      _navigateToHome(session);
      
    } catch (e) {
      debugPrint('🚨 Watchdog: Erro de integridade detectado: $e');
      
      try {
        await client.auth.signOut();
      } catch (_) {}

      _navigateToLogin();
    }
  }

  Future<bool> _checkInitialDeepLink() async {
    try {
      final initialLink = await AppLinks().getInitialAppLink();
      if (initialLink != null) {
        debugPrint('Deep link inicial detectado: $initialLink');
        await DeepLinkHandler.handleInitialLink(initialLink.toString());
        
        if (mounted) {
          _isNavigated = true;
          // Proteção para navegação via Deep Link
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/redefinir-senha');
            }
          });
          return true;
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar deep link inicial: $e');
    }
    return false;
  }

  void _navigateToHome(Session session) async {
    if (!mounted || _isNavigated) return;
    _isNavigated = true;

    final userId = session.user.id;
    final perfil = await Supabase.instance.client
        .from('profiles')
        .select('salao_id')
        .eq('id', userId)
        .maybeSingle();

    final salaoId = perfil?['salao_id'] ?? '';

    if (mounted) {
      // 🛡️ Proteção L_debugLocked: Navega apenas após o fim do frame de Splash
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomePage(salaoId: salaoId)),
          );
        }
      });
    }
  }

  void _navigateToLogin() {
    if (!mounted || _isNavigated) return;
    _isNavigated = true;

    // 🛡️ Proteção L_debugLocked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Verificando conexão...", 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}