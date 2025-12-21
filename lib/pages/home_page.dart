import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_salao_pro/pages/clientes_page.dart';
import 'package:app_salao_pro/pages/profissionais_page.dart' as prof;
import 'package:app_salao_pro/pages/servicos_page.dart' as serv;
import 'package:app_salao_pro/pages/agenda_page.dart';
import 'dashboard_page.dart';
import 'especialidades_page.dart';
import 'login_page.dart';
import 'editar_salao_page.dart';
import 'perfil_page.dart';
import 'package:app_salao_pro/widgets/theme_selector.dart';
//import 'pages/clientes_page.dart';
//import 'pages/profissionais_page.dart';
//import 'pages/servicos_page.dart';
//import 'pages/agenda_page.dart';


class HomePage extends StatefulWidget {
  final String salaoId;

  const HomePage({super.key, required this.salaoId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDono = false;
  String nomeSalao = '';
  String? emailDono;
  String? logoUrl;

  bool carregando = true; // Garante que nada é exibido antes da hora
  bool erro = false; // Evita travamento silencioso

  @override
  void initState() {
    super.initState();
    _validarAcesso();
  }

  Future<void> _validarAcesso() async {
    try {
      final client = Supabase.instance.client;

      // Verifica usuário
      final user = client.auth.currentUser;
      if (user == null || widget.salaoId.isEmpty) {
        _voltarParaLogin();
        return;
      }

      // Carrega permissões e dados
      await verificarPermissao();
      await carregarDadosSalao();

    } catch (e) {
      print("Erro ao validar acesso: $e");
      erro = true;
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> verificarPermissao() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final perfil = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      isDono = perfil?['role'] == 'dono';
    });
  }

  Future<void> carregarDadosSalao() async {
    final response = await Supabase.instance.client
        .from('saloes')
        .select('nome, email, logo_url')
        .eq('id', widget.salaoId)
        .maybeSingle();

    if (response == null) {
      erro = true;
      return;
    }

    if (!mounted) return;

    setState(() {
      nomeSalao = response['nome'] ?? 'Salão';
      emailDono = response['email'];
      logoUrl = response['logo_url'];
    });
  }

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _voltarParaLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  String _iniciaisSalao(String nome) {
    if (nome.trim().isEmpty) return '?';
    final partes = nome.trim().split(' ');
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    if (carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (erro) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "Erro ao carregar o salão.\nFaça login novamente.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => logout(context),
                child: const Text("Ir para Login"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Painel do Salão',
          style: t.textTheme.titleLarge?.copyWith(
            color: t.colorScheme.onPrimary,
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: t.colorScheme.primary),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 70,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: logoUrl != null && logoUrl!.isNotEmpty
                          ? Image.network(logoUrl!, fit: BoxFit.contain)
                          : Container(
                              color: t.colorScheme.onPrimary.withOpacity(0.15),
                              alignment: Alignment.center,
                              child: Text(
                                _iniciaisSalao(nomeSalao),
                                style: t.textTheme.headlineMedium?.copyWith(
                                  color: t.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nomeSalao,
                    textAlign: TextAlign.center,
                    style: t.textTheme.titleLarge?.copyWith(
                      color: t.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (emailDono != null)
                    Text(
                      emailDono!,
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodySmall?.copyWith(
                        color: t.colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
            const ListTile(
              leading: Icon(Icons.brightness_6_outlined),
              title: Text('Tema do aplicativo'),
              subtitle: ThemeSelector(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações do salão'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditarSalaoPage(salaoId: widget.salaoId),
                  ),
                ).then((_) => carregarDadosSalao());
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _botaoNavegacao('Dashboard', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardPage(salaoId: widget.salaoId),
              ),
            );
          }),
          _botaoNavegacao('Especialidades', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EspecialidadesPage(salaoId: widget.salaoId),
              ),
            );
          }),
          _botaoNavegacao('Serviços', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => serv.ServicosPage(salaoId: widget.salaoId),
              ),
            );
          }),
          _botaoNavegacao('Profissionais', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => prof.ProfissionaisPage(salaoId: widget.salaoId),
              ),
            );
          }),
          _botaoNavegacao('Clientes', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClientesPage(salaoId: widget.salaoId)),
            );
          }),
          _botaoNavegacao('Agenda', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AgendaPage(
                  salaoId: widget.salaoId,
                  dataSelecionada: DateTime.now(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _botaoNavegacao(String texto, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(texto),
        ),
      ),
    );
  }
}
