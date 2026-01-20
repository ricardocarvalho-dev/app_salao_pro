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

class HomePage extends StatefulWidget {
  final String salaoId;

  const HomePage({super.key, required this.salaoId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool isDono = false;
  String nomeSalao = '';
  String? emailDono;
  String? logoUrl;

  bool carregando = true;
  bool erro = false;
  
  // 🛡️ Trava de segurança para evitar múltiplas chamadas simultâneas
  bool _estaCarregandoProcesso = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 🔁 Reage quando o app volta do background (Resolve o travamento ao retornar)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 Home retomada do segundo plano - Validando estado...');
      _load();
    }
  }

  /// 🔐 Load protegido contra travamento, timeout e estresse de cliques
  Future<void> _load() async {
    // Se já estiver carregando ou o widget saiu da tela, ignora a nova chamada
    if (_estaCarregandoProcesso || !mounted) return;

    setState(() {
      _estaCarregandoProcesso = true;
      carregando = true;
      erro = false;
    });

    try {
      // Tenta executar a validação, mas aborta se demorar mais de 10 segundos
      await Future.any([
        _validarAcesso(),
        Future.delayed(
          const Duration(seconds: 10),
          () => throw Exception('Timeout na conexão com o servidor'),
        ),
      ]);

      if (!mounted) return;
      setState(() => carregando = false);
    } catch (e) {
      debugPrint('Erro no load da Home: $e');

      if (!mounted) return;
      setState(() {
        carregando = false;
        erro = true;
      });
    } finally {
      // Garante que a trava seja liberada para futuras tentativas
      if (mounted) {
        _estaCarregandoProcesso = false;
      }
    }
  }

  Future<void> _validarAcesso() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    
    // Se o usuário perdeu a sessão enquanto estava em background
    if (user == null || widget.salaoId.isEmpty) {
      _voltarParaLogin();
      throw Exception('Sessão inválida ou expirada');
    }

    await verificarPermissao();
    await carregarDadosSalao();
  }

  Future<void> verificarPermissao() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário inválido');

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
      throw Exception('Salão não encontrado');
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
    if (!mounted) return;
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
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    // ESTADO: CARREGANDO
    if (carregando) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Sincronizando dados..."),
            ],
          ),
        ),
      );
    }

    // ESTADO: ERRO (Evita que o app precise ser reinstalado)
    if (erro) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 80, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  "Não conseguimos conectar ao servidor.",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Isso pode acontecer por instabilidade na rede ao retornar ao aplicativo.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tentar novamente"),
                ),
                TextButton(
                  onPressed: () => logout(context),
                  child: const Text("Sair e fazer login novamente"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ESTADO: PRONTO
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleLarge?.copyWith(
                      color: t.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                    builder: (_) => EditarSalaoPage(salaoId: widget.salaoId),
                  ),
                ).then((_) => _load());
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
              MaterialPageRoute(
                builder: (_) => ClientesPage(salaoId: widget.salaoId),
              ),
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