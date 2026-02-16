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
import 'dart:async';


class HomePage extends StatefulWidget {
  final String? salaoId;

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
  String? mensagemStatus; // 🔹 adicione esta linha
  Timer? _refreshTimer; // 🔹 timer para refresh automático

  
  // 🛡️ Trava de segurança para evitar múltiplas chamadas simultâneas
  bool _estaCarregandoProcesso = false;
  /*
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }
  */
  /*
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();

    // 🔹 Refresh automático a cada 30 segundos enquanto estiver configurando
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mensagemStatus != null) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel(); // 🔹 cancela o timer ao sair da tela
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
  */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 1. Tenta carregar imediatamente ao abrir
    _load();

    // 2. 🔹 Refresh AGRESSIVO (Mude de 30 para 2 ou 3 segundos)
    // Isso garante que assim que o banco terminar, o app perceba rápido.
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mensagemStatus != null && mounted) {
        _load(); 
      } else if (mensagemStatus == null) {
        timer.cancel(); // 🔹 Otimização: para o timer se já entrou na Home
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 Home retomada do segundo plano - Validando estado...');
      // Se o usuário alternou abas e voltou, forçamos o _load na hora
      if (mounted) _load();
    }
  }  

  /// 🔐 Load protegido contra travamento, timeout e estresse de cliques
  /*
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
  */
  Future<void> _load() async {
    // Se já estiver carregando ou o widget saiu da tela, ignora a nova chamada
    if (_estaCarregandoProcesso || !mounted) return;

    setState(() {
      _estaCarregandoProcesso = true;
      carregando = true;
      erro = false;
      mensagemStatus = null; // 🔹 reset do estado extra
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

      // 🔹 Se o salão ainda não tiver slots, mensagemStatus será preenchida
      if (mensagemStatus != null) {
        setState(() {
          carregando = false;
          erro = false;
        });
      } else {
        setState(() => carregando = false);
      }
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

  /*
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
    // 🔹 checa se já tem slots
    final inicializado = await verificarInicializacaoSalao(widget.salaoId);
    if (!inicializado) {
      setState(() {
        mensagemStatus = 'Seu salão está sendo configurado...';
      });
    }

  }
  */
  Future<void> _validarAcesso() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    
    // 1. Verifica sessão
    if (user == null) {
      _voltarParaLogin();
      return;
    }

    // 2. Recupera o ID de forma segura (Tratando o Null)
    // Usamos o operador ?? para dizer: "se for nulo, use uma string vazia"
    String idParaUso = widget.salaoId ?? '';
    
    // 3. Se ainda estiver vazio, tenta buscar no perfil do banco
    if (idParaUso.isEmpty) {
      final perfil = await client
          .from('profiles')
          .select('salao_id')
          .eq('id', user.id)
          .maybeSingle();
      
      // Novamente usamos ?? '' para garantir que idParaUso nunca seja null
      idParaUso = perfil?['salao_id']?.toString() ?? '';
    }

    // 4. Se após a busca no banco ainda estiver vazio, aguardamos o Timer
    if (idParaUso.isEmpty) {
      debugPrint('Aviso: salaoId ainda não disponível. Aguardando sincronização...');
      if (mounted) {
        setState(() {
          mensagemStatus = 'Finalizando configuração do seu salão...';
        });
      }
      return;
    }

    /*
    // 5. Se chegamos aqui, temos um ID válido!
    await verificarPermissao();
    await carregarDadosSalaoComId(idParaUso);  
    
    final inicializado = await verificarInicializacaoSalao(idParaUso);
    if (!inicializado) {
      if (mounted) {
        setState(() {
          mensagemStatus = 'Seu salão está sendo configurado...';
        });
      }
    } else {
      // Se já inicializou, limpamos a mensagem de status para mostrar o painel
      if (mounted) {
        setState(() {
          mensagemStatus = null;
        });
      }
    }
    */
    // 5. Se chegamos aqui, temos um ID válido!
    // IMPORTANTE: Só carregamos os dados pesados e limpamos o status 
    // SE o salão já tiver terminado a configuração no banco.
    
    final inicializado = await verificarInicializacaoSalao(idParaUso);
    
    if (!inicializado) {
      if (mounted) {
        setState(() {
          mensagemStatus = 'Seu salão está sendo configurado... Por favor, aguarde.';
        });
      }
      // Se não inicializou, saímos aqui e o Timer do initState chamará esta função de novo em 2 seg.
      return; 
    }

    // TUDO PRONTO! Agora sim carregamos e liberamos a tela.
    await verificarPermissao();
    await carregarDadosSalaoComId(idParaUso);  
    
    if (mounted) {
      setState(() {
        mensagemStatus = null; // Libera o acesso à Home
      });
      // ADICIONE ESTA LINHA:
      _refreshTimer?.cancel(); 
      debugPrint('✅ Sucesso: Salão pronto e Timer encerrado.');      
    }

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
  /*
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
  */
  Future<void> carregarDadosSalaoComId(String id) async {
    final response = await Supabase.instance.client
        .from('saloes')
        .select('nome, email, logo_url')
        .eq('id', id) // 👈 Usa o ID que passamos por parâmetro
        .maybeSingle();

    if (response == null) {
      throw Exception('Salão não encontrado no banco de dados.');
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

  Future<bool> verificarInicializacaoSalao(String salaoId) async {
    final count = await Supabase.instance.client
        .from('horarios_disponiveis')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('salao_id', salaoId);

    return (count.count ?? 0) > 0;
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

  /*
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
  */
  /*
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

    // 🔹 ESTADO: CONFIGURAÇÃO EM ANDAMENTO
    if (mensagemStatus != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(mensagemStatus!),
            ],
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
  */
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    // 1. ESTADO: CARREGANDO
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

    // 2. ESTADO: ERRO
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

    // 3. ESTADO: CONFIGURAÇÃO EM ANDAMENTO (Trata o salaoId nulo ou vazio)
    // Criamos o idSeguro aqui. Se widget.salaoId for null, tentamos pegar o que carregamos.
    final String idSeguro = widget.salaoId ?? '';

    if (mensagemStatus != null || idSeguro.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(mensagemStatus ?? "Finalizando configuração..."),
            ],
          ),
        ),
      );
    }

    // 4. ESTADO: PRONTO (Aqui o Dart já sabe que idSeguro NÃO é nulo e NÃO é vazio)
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
                    builder: (_) => EditarSalaoPage(salaoId: idSeguro), // 👈 Uso do idSeguro
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
                builder: (_) => DashboardPage(salaoId: idSeguro), // 👈 Uso do idSeguro
              ),
            );
          }),
          _botaoNavegacao('Especialidades', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EspecialidadesPage(salaoId: idSeguro),
              ),
            );
          }),
          _botaoNavegacao('Serviços', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => serv.ServicosPage(salaoId: idSeguro),
              ),
            );
          }),
          _botaoNavegacao('Profissionais', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => prof.ProfissionaisPage(salaoId: idSeguro),
              ),
            );
          }),
          _botaoNavegacao('Clientes', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClientesPage(salaoId: idSeguro),
              ),
            );
          }),
          _botaoNavegacao('Agenda', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AgendaPage(
                  salaoId: idSeguro,
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