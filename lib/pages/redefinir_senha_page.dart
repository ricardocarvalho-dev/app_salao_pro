import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RedefinirSenhaPage extends StatefulWidget {
  const RedefinirSenhaPage({super.key});

  @override
  State<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  // 👁️ As duas variáveis de controle de visibilidade
  bool _obscurePassword = true; 
  bool _obscureConfirmPassword = true; 
  
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final newPassword = _senhaController.text.trim();
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session == null) {
        setState(() => _errorMessage = 'Sessão expirada. Solicite um novo link.');
        return;
      }

      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha redefinida com sucesso!')),
        );

        final userEmail = response.user!.email;
        if (userEmail != null) {
          await _storage.write(key: 'user_email', value: userEmail);
        }
        await _storage.write(key: 'user_password', value: newPassword);
        await _storage.write(key: 'use_bio', value: 'true');

        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir Senha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Digite sua nova senha',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo 1: Nova Senha
              TextFormField(
                controller: _senhaController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nova Senha',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 20),

              // Campo 2: Confirmar Senha (AGORA COM OLHINHO TAMBÉM)
              TextFormField(
                controller: _confirmacaoController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Senha',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (value) => (value != _senhaController.text) ? 'As senhas não coincidem' : null,
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Salvar Nova Senha', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}