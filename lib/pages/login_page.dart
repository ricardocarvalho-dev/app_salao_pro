import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'cadastro_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  bool carregando = false;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> logarUsuario() async {
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      mostrarErro('Informe o e-mail e a senha.');
      return;
    }

    setState(() => carregando = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      final user = response.user;
      if (user == null) {
        mostrarErro('Usuário não encontrado.');
        return;
      }

      final perfil = await Supabase.instance.client
          .from('profiles')
          .select('salao_id')
          .eq('id', user.id)
          .maybeSingle();

      if (perfil == null || perfil['salao_id'] == null) {
        mostrarErro('Salão não encontrado para este usuário.');
        return;
      }

      final salaoId = perfil['salao_id'].toString();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(salaoId: salaoId)),
      );
    } on AuthException catch (e) {
      mostrarErro(_traduzErro(e.message));
    } catch (e) {
      mostrarErro('Erro inesperado: ${e.toString()}');
    } finally {
      setState(() => carregando = false);
    }
  }

  void mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }
  /*
  Future<void> enviarEmailRedefinicaoSenha() async {
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();

    if (email.isEmpty) {
      mostrarErro('Informe o e-mail para redefinir a senha.');
      return;
    }

    const String deepLink = 'salaopro://redefinir-senha';

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: deepLink,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '📧 E-mail de redefinição enviado. Verifique sua caixa de entrada.')),
      );
    } on AuthException catch (e) {
      mostrarErro(_traduzErro(e.message));
    } catch (e) {
      mostrarErro('Erro ao enviar e-mail: ${e.toString()}');
    }
  }
  */
  Future<void> enviarEmailRedefinicaoSenha() async {
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();

    if (email.isEmpty) {
      mostrarErro('Informe o e-mail para redefinir a senha.');
      return;
    }

    const String deepLink = 'salaopro://redefinir-senha';

    try {
      debugPrint('Chamando resetPasswordForEmail para $email...');
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: deepLink,
      );
      debugPrint('Supabase retornou sucesso no resetPasswordForEmail');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📧 E-mail de redefinição enviado. Verifique sua caixa de entrada.'),
        ),
      );
    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.message}');
      mostrarErro(_traduzErro(e.message));
    } catch (e) {
      debugPrint('Erro inesperado: $e');
      mostrarErro('Erro ao enviar e-mail: ${e.toString()}');
    }
  }


  String _traduzErro(String erroOriginal) {
    final erro = erroOriginal.toLowerCase();
    if (erro.contains('invalid login credentials')) return 'E-mail ou senha incorretos.';
    if (erro.contains('email not confirmed')) return 'E-mail ainda não confirmado.';
    if (erro.contains('user not found')) return 'Usuário não encontrado.';
    if (erro.contains('network') || erro.contains('socket')) return 'Problema de conexão com a internet.';
    if (erro.contains('too many requests')) return 'Muitas tentativas. Tente novamente mais tarde.';
    if (erro.contains('invalid email or password')) return 'E-mail ou senha inválidos.';
    return 'Erro: $erroOriginal';
  }

  @override
  Widget build(BuildContext context) {
    final estiloTexto = GoogleFonts.poppins(fontSize: 16);
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/logo_salao_pro.png',
                  height: 120,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: estiloTexto,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: senhaController,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _senhaVisivel ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                  ),
                  style: estiloTexto,
                ),
                const SizedBox(height: 24),
                carregando
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: logarUsuario,
                            child: const Text('Entrar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final resultado = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CadastroPage()),
                              );
                              if (resultado == true && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Cadastro realizado com sucesso! Faça login para continuar.'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Criar conta'),
                          ),
                          TextButton(
                            onPressed: enviarEmailRedefinicaoSenha,
                            child: const Text('Esqueci minha senha'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
