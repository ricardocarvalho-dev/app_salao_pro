import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importe suas páginas (ajuste os caminhos conforme necessário)
import 'home_page.dart';
import 'login_page.dart';
import 'redefinir_senha_page.dart';

// Este Widget deve ser o primeiro widget do seu app (ex: no lugar do home: de MaterialApp)
class AuthRedirectHandler extends StatefulWidget {
  const AuthRedirectHandler({super.key});

  @override
  State<AuthRedirectHandler> createState() => _AuthRedirectHandlerState();
}

class _AuthRedirectHandlerState extends State<AuthRedirectHandler> {
  // A chave para o Supabase é usar o listener de mudança de estado
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      // Chama a função de roteamento
      _handleRouting(event);
    });
  }

  void _handleRouting(AuthChangeEvent event) {
    // Garantir que a navegação ocorra apenas após a construção inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 1. **VERIFICAÇÃO CRÍTICA**: Se o evento for de recuperação de senha,
      // NAVEGUE DIRETAMENTE para a página de redefinição.
      if (event == AuthChangeEvent.passwordRecovery) {
        // Usa pushReplacement para garantir que o usuário não possa voltar
        // para a página de login usando o botão "voltar" do celular.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RedefinirSenhaPage()),
        );
      } 
      // 2. Se o evento for de SIGN IN (login normal) ou INITIAL_SESSION
      // (usuário já logado), vá para a Home.
      else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Se não houver sessão, vá para o login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } 
      // 3. Se o evento for de SIGN OUT, vá para o login.
      else if (event == AuthChangeEvent.signedOut) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
      // Outros eventos (ex: userUpdated, tokenRefreshed) podem ser ignorados para o roteamento inicial.
    });
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto o Supabase não resolve o estado inicial, mostre um indicador de carregamento.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
