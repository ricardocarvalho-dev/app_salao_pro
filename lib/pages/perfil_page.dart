import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  bool carregando = false;
  // 1. Variável para controlar a visibilidade (igual à LoginPage)
  bool _senhaVisivel = false; 

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    emailController.text = user?.email ?? '';
  }

  Future<void> atualizarDados() async {
    if (!_formKey.currentState!.validate()) return;

    final novoEmail = emailController.text.trim();
    final novaSenha = senhaController.text.trim();

    if (novoEmail.isEmpty && novaSenha.isEmpty) {
      mostrarMensagem('Preencha ao menos um campo para atualizar.');
      return;
    }

    setState(() => carregando = true);

    final useBio = await _storage.read(key: 'use_bio') == 'true';

    try {
      final auth = Supabase.instance.client.auth;

      if (novoEmail.isNotEmpty) {
        await Supabase.instance.client.rpc(
          'atualizar_email_sem_confirmacao', 
          params: {'novo_email': novoEmail}
        );
        if (useBio) await _storage.write(key: 'user_email', value: novoEmail);
      }

      if (novaSenha.isNotEmpty) {
        if (novaSenha.length < 6) {
          mostrarMensagem('A senha deve ter pelo menos 6 caracteres.');
          setState(() => carregando = false);
          return;
        }
        await auth.updateUser(UserAttributes(password: novaSenha));
        if (useBio) await _storage.write(key: 'user_password', value: novaSenha);
      }

      mostrarMensagem('Dados atualizados com sucesso!');
      // Limpa o campo de senha após atualizar para segurança
      senhaController.clear();
    } catch (e) {
      mostrarMensagem('Erro: $e');
    } finally {
      setState(() => carregando = false);
    }
  }

  void mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do Dono')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),

              /// NOVO EMAIL
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Novo e-mail',
                  prefixIcon: Icon(Icons.email_outlined), // Ajustado para Outline igual à Login
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v)) {
                    return 'Digite um e-mail válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// NOVA SENHA (COM VISUALIZADOR)
              TextFormField(
                controller: senhaController,
                // 2. Controla se o texto fica escondido ou não
                obscureText: !_senhaVisivel, 
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: const Icon(Icons.lock_outline), // Ajustado para Outline
                  // 3. Adiciona o ícone do "olhinho"
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _senhaVisivel = !_senhaVisivel;
                      });
                    },
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              carregando
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: atualizarDados,
                        child: const Text(
                          'Atualizar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}