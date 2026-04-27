import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'cadastro_page.dart';
import 'package:app_salao_pro/services/biometria_service.dart'; // ✅ Certifique-se que o caminho está correto
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // adicione o import e a instância do storage
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final _storage = const FlutterSecureStorage(); // No início da classe _LoginPageState

  @override
  void initState() {
    super.initState();

    // ✅ Dispara a tentativa de biometria assim que a tela abre
    if (!kIsWeb) {
      // Aqui vai o seu código de Acesso Rápido/Biometria
      _tentarBiometriaAutomatica();
    }

  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  // ✅ Método para Bio estilo "App de Banco"
  Future<void> _tentarBiometriaAutomatica() async {
    // --- ADICIONE ESTA LINHA AQUI ---
    final useBio = await _storage.read(key: 'use_bio');
    if (useBio != 'true') return; // Se o usuário não ativou explicitamente, para aqui.
    
    // 1. Tenta ler o que está no cofre
    final emailSalvo = await _storage.read(key: 'user_email');
    final senhaSalva = await _storage.read(key: 'user_password');

    // Só prossegue se tiver algo guardado
    if (emailSalvo != null && senhaSalva != null) {
      // Pequeno delay para a UI respirar
      await Future.delayed(const Duration(milliseconds: 600));

      // 2. Pede o desbloqueio do celular (Digital/PIN/Face)
      bool sucessoBio = await BiometriaService.autenticar();

      if (sucessoBio && mounted) {
        setState(() => carregando = true);
        try {
          // 3. Tenta o login silencioso no Supabase
          final response = await Supabase.instance.client.auth.signInWithPassword(
            email: emailSalvo,
            password: senhaSalva,
          );

          if (response.user != null && mounted) {
            // Busca o perfil (reaproveite sua lógica existente aqui)
            final perfil = await Supabase.instance.client
                .from('profiles')
                .select('salao_id')
                .eq('id', response.user!.id)
                .maybeSingle();

            if (perfil != null && perfil['salao_id'] != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomePage(salaoId: perfil['salao_id'].toString())),
              );
            }
          }
        } on AuthException catch (e) {
          // Se a senha mudou e o cofre está velho, limpa para não dar erro na próxima
          if (e.message.contains('Invalid login credentials')) {
            await _storage.delete(key: 'user_password');
          }
          debugPrint('Erro no login auto: ${e.message}');
        } finally {
          if (mounted) setState(() => carregando = false);
        }
      }
    }
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
      else {
        // 1. Verifica se já perguntamos sobre a biometria antes
        String? jaPerguntou = await _storage.read(key: 'perguntou_bio');
        String? useBio = await _storage.read(key: 'use_bio');

        if (jaPerguntou == null && mounted) {
          // 2. PRIMEIRA VEZ: Abre o diálogo perguntando
          bool desejaBio = await showDialog(
            context: context,
            barrierDismissible: false, // Obriga a escolher sim ou não
            builder: (context) => AlertDialog(
              title: const Text('Acesso Rápido'),
              content: const Text('Deseja usar a biometria ou senha do celular para entrar nas próximas vezes?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false), 
                  child: const Text('Agora não'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true), 
                  child: const Text('Sim, ativar'),
                ),
              ],
            ),
          ) ?? false;

          if (desejaBio) {
            await _storage.write(key: 'use_bio', value: 'true');
            await _storage.write(key: 'user_email', value: email);
            await _storage.write(key: 'user_password', value: senha);
          }
          // Marca que já fizemos a pergunta uma vez na vida
          await _storage.write(key: 'perguntou_bio', value: 'true');
          
        } else if (useBio == 'true') {
          // 3. JÁ ATIVOU NO PASSADO: Apenas atualiza as credenciais (caso tenham mudado)
          await _storage.write(key: 'user_email', value: email);
          await _storage.write(key: 'user_password', value: senha);
        }
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
      if (mounted) setState(() => carregando = false);
    }
  }

  void mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                  isDarkMode 
                    ? 'assets/salao-pro-logo-negativa.png' 
                    : 'assets/salao-pro-logo-positiva.png',
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