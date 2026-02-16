import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:app_salao_pro/pages/home_page.dart';

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
  String mensagemStatus = 'Criando sua conta...'; // Para feedback de progresso

  // Instância do storage seguro
  final storage = const FlutterSecureStorage();

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

    setState(() {
      carregando = true;
      mensagemStatus = 'Criando sua conta...';
    });

    try {
      // 🔹 Timeout de 15 segundos para evitar loop infinito
      await Future.any([
        _processoCadastro(email, senha, nomeSalao, celularSalao),
        Future.delayed(const Duration(seconds: 15), () {
          throw TimeoutException('Tempo limite atingido');
        }),
      ]);
    } catch (e) {
      if (e is TimeoutException) {
        // 🔹 SnackBar com botão "Tentar novamente"
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Demorou demais. Deseja tentar novamente?'),
              action: SnackBarAction(
                label: 'Tentar novamente',
                onPressed: () {
                  cadastrarDono(); // retry
                },
              ),
            ),
          );
        }
      } else {
        mostrarErro(_traduzErroSupabase(e));
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }
  /*
  Future<void> _processoCadastro(
      String email, String senha, String nomeSalao, String celularSalao) async {
    // 1. Auth SignUp
    final authResponse = await Supabase.instance.client.auth.signUp(
      email: email,
      password: senha,
    );

    final user = authResponse.user;
    if (user == null) {
      throw Exception('Erro ao criar conta. Tente novamente mais tarde.');
    }

    // 🔹 Salvar token para login automático
    final token = authResponse.session?.accessToken;
    if (token != null) {
      await storage.write(key: 'jwt_token', value: token);
    }

    // 2. Criar Profile
    await Supabase.instance.client.from('profiles').insert({
      'id': user.id,
      'email': email,
      'nome': nomeSalao,
      'role': 'dono',
    });

    // 3. Criar Salão
    setState(() => mensagemStatus = 'Finalizando configuração...');
    final salaoResponse =
        await Supabase.instance.client.from('saloes').insert({
      'nome': nomeSalao,
      'celular': celularSalao,
      'dono_id': user.id,
      'modo_agendamento': modoAgendamento,
    }).select().single();

    final salaoId = salaoResponse['id']?.toString();
    if (salaoId == null || salaoId.isEmpty) {
      throw Exception('Erro ao criar salão.');
    }
    
    /*
    // 4. Clonar Templates
    setState(() => mensagemStatus = 'Configurando serviços e agenda...');
    await Supabase.instance.client.rpc(
      'clonar_templates_para_novo_salao',
      params: {'p_salao_id': salaoId},
    );
    */

    // 5. Vincular Salão ao Profile
    await Supabase.instance.client
        .from('profiles')
        .update({'salao_id': salaoId}).eq('id', user.id);

    // 🔹 Feedback rápido + redirecionamento automático
    mostrarErro('Cadastro realizado com sucesso! Seu salão está sendo configurado.');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
  */
  Future<void> _processoCadastro(
        String email, String senha, String nomeSalao, String celularSalao) async {
      // 1. Auth SignUp
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: senha,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('Erro ao criar conta. Tente novamente mais tarde.');
      }

      // Salvar token para login automático
      final token = authResponse.session?.accessToken;
      if (token != null) {
        await storage.write(key: 'jwt_token', value: token);
      }

      // 2. Criar Profile
      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'email': email,
        'nome': nomeSalao,
        'role': 'dono',
      });

      // 3. Criar Salão
      setState(() => mensagemStatus = 'Finalizando configuração...');

      // Inserimos sem esperar o retorno do objeto completo
      await Supabase.instance.client.from('saloes').insert({
        'nome': nomeSalao,
        'celular': celularSalao,
        'dono_id': user.id,
        'modo_agendamento': modoAgendamento,
      });

      // BUSCA EXPLÍCITA: Pegamos o ID do salão mais recente deste dono
      final buscaSalao = await Supabase.instance.client
          .from('saloes')
          .select('id')
          .eq('dono_id', user.id)
          .order('created_at', ascending: false) // <--- O termo correto é este
          .limit(1)
          .maybeSingle();
          
      if (buscaSalao == null || buscaSalao['id'] == null) {
        throw Exception('Salão criado, mas o sistema de segurança impediu a leitura do ID. Verifique o RLS.');
      }

      //final String idFinalSeguro = buscaSalao['id'].toString();
      final String idFinalSeguro = buscaSalao?['id']?.toString() ?? '';
      debugPrint('DEBUG: ID recuperado com sucesso: $idFinalSeguro');

      // 4. Vincular Salão ao Profile
      await Supabase.instance.client
          .from('profiles')
          .update({'salao_id': idFinalSeguro})
          .eq('id', user.id);
      /*
      // 5. Feedback e Navegação
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
      */
      // No passo 5 do seu processo de cadastro:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );

        // Em vez de usar a rota nomeada, passamos a página diretamente com o ID
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(salaoId: idFinalSeguro),
          ),
        );
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
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
      body: SingleChildScrollView(
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
            const SizedBox(height: 32),
            if (carregando)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    mensagemStatus,
                    style: estiloCampo?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              SizedBox(
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
