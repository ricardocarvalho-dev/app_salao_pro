import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importe suas páginas (ajuste os caminhos conforme necessário)
import 'package:app_salao_pro/pages/home_page.dart';
import 'package:app_salao_pro/pages/login_page.dart';
import 'package:app_salao_pro/pages/redefinir_senha_page.dart';

class AuthRedirectHandler extends StatefulWidget {
  const AuthRedirectHandler({super.key});

  @override
  State<AuthRedirectHandler> createState() => _AuthRedirectHandlerState();
}

class _AuthRedirectHandlerState extends State<AuthRedirectHandler> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      _handleRouting(event);
    });
  }

  void _handleRouting(AuthChangeEvent event) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 1. Recuperação de senha
      if (event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RedefinirSenhaPage()),
        );
      } 
      // 2. Login normal
      else if (event == AuthChangeEvent.signedIn) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          // Aqui usamos o user.id como salaoId (ajuste se precisar outro campo)
          final salaoId = session.user?.id ?? '';
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomePage(salaoId: salaoId),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } 
      // 3. Logout
      else if (event == AuthChangeEvent.signedOut) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
      // Outros eventos (userUpdated, tokenRefreshed, etc) podem ser ignorados
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
