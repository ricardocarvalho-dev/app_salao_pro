import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final nomeSalaoController = TextEditingController();
  final celularSalaoController = TextEditingController();
  String modoAgendamento = 'por_profissional';

  final celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool carregando = false;

  Future<void> cadastrarDono() async {
    if (carregando) return;

    final email = emailController.text.trim();
    final senha = senhaController.text.trim();
    final nomeSalao = nomeSalaoController.text.trim();
    final celularSalao = celularSalaoController.text.trim();

    if (!emailValido(email)) {
      mostrarErro('E-mail inválido.');
      return;
    }
    if (senha.length < 6) {
      mostrarErro('A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (nomeSalao.isEmpty || celularSalao.isEmpty) {
      mostrarErro('Preencha todos os campos corretamente.');
      return;
    }

    setState(() => carregando = true);
    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: senha,
      );

      final user = authResponse.user;
      if (user == null) {
        mostrarErro('Erro ao criar conta. Tente novamente mais tarde.');
        return;
      }

      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'email': email,
        'nome': nomeSalao,
        'role': 'dono',
      });

      final salaoResponse =
          await Supabase.instance.client.from('saloes').insert({
        'nome': nomeSalao,
        'celular': celularSalao,
        'dono_id': user.id,
        'modo_agendamento': modoAgendamento,
      }).select().single();

      final salaoId = salaoResponse['id']?.toString();
      if (salaoId == null || salaoId.isEmpty) {
        mostrarErro('Erro ao criar salão.');
        return;
      }

      await Supabase.instance.client
          .from('profiles')
          .update({'salao_id': salaoId}).eq('id', user.id);

      mostrarErro('Cadastro realizado com sucesso!');
      Navigator.pop(context, true);
    } catch (e) {
      mostrarErro(_traduzErroSupabase(e));
    } finally {
      setState(() => carregando = false);
    }
  }

  bool emailValido(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(email);
  }

  String _traduzErroSupabase(Object e) {
    final msg = e.toString();
    if (msg.contains('User already registered')) {
      return 'Este e-mail já está em uso.';
    }
    if (msg.contains('429')) return 'Muitas tentativas. Aguarde um momento.';
    if (msg.contains('network')) return 'Sem conexão com a internet.';
    return 'Erro inesperado: $msg';
  }

  void mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white, // Para garantir legibilidade no snackbar
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estiloCampo = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              style: estiloCampo,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: senhaController,
              decoration: const InputDecoration(
                labelText: 'Senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              style: estiloCampo,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: nomeSalaoController,
              decoration: const InputDecoration(
                labelText: 'Nome do Salão',
                prefixIcon: Icon(Icons.store_mall_directory_outlined),
              ),
              style: estiloCampo,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: celularSalaoController,
              decoration: const InputDecoration(
                labelText: 'Celular do Salão',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [celularMask],
              style: estiloCampo,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: modoAgendamento,
              decoration: const InputDecoration(
                labelText: 'Modo de Agendamento',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'por_profissional', child: Text('Por Profissional')),
                DropdownMenuItem(
                    value: 'por_servico', child: Text('Por Serviço')),
              ],
              onChanged: (value) =>
                  setState(() => modoAgendamento = value!),
              style: estiloCampo,
            ),

            const SizedBox(height: 24),

            carregando
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: cadastrarDono,
                      child: const Text('Criar Conta'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
