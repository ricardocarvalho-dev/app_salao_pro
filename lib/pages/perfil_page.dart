import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool carregando = false;

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

    try {
      final auth = Supabase.instance.client.auth;

      // Atualizar e-mail
      if (novoEmail.isNotEmpty) {
        await auth.updateUser(UserAttributes(email: novoEmail));
      }

      // Atualizar senha
      if (novaSenha.isNotEmpty) {
        if (novaSenha.length < 6) {
          mostrarMensagem('A senha deve ter pelo menos 6 caracteres.');
          setState(() => carregando = false);
          return;
        }
        await auth.updateUser(UserAttributes(password: novaSenha));
      }

      mostrarMensagem('Dados atualizados com sucesso!');
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
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // email opcional
                  if (!v.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// NOVA SENHA
              TextFormField(
                controller: senhaController,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // senha opcional
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
