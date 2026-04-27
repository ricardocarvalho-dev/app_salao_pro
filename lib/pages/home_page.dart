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
// 🔹 ADICIONADO:
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_salao_pro/main.dart';
import 'package:app_salao_pro/pages/agendamento_movel.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_salao_pro/pages/configuracao_agenda_page.dart';

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
  bool chatbotAtivo = false; // 🔹 ADICIONADO
  String statusConexao = 'checking'; // 'checking', 'connected', 'disconnected'
  String? instanciaWhatsapp; // 🔹 ADICIONE ESTA LINHA

  bool carregando = true;
  bool erro = false;
  String? mensagemStatus; // 🔹 adicione esta linha
  Timer? _refreshTimer; // 🔹 timer para refresh automático

  
  // 🛡️ Trava de segurança para evitar múltiplas chamadas simultâneas
  bool _estaCarregandoProcesso = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 🎯 1. VERIFICAÇÃO DE NOTIFICAÇÃO PENDENTE (O Pulo do Gato)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notificacaoPendente != null) {
        final data = notificacaoPendente!.data;
        notificacaoPendente = null; // Esvazia a mochila para não repetir

        try {
          final dataAgendamento = DateTime.parse(data['dataAgendamento']);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgendamentoMovelPage(
                salaoId: data['salaoId'],
                dataSelecionada: dataAgendamento,
                clienteId: data['clienteId'],
                profissionalId: (data['profissionalId']?.toString().isEmpty ?? true) 
                    ? null 
                    : data['profissionalId'],
                servicoId: data['servicoId'],
                modoAgendamento: 'por_servico',
              ),
            ),
          );
        } catch (e) {
          debugPrint("❌ Erro ao processar notificação na Home: $e");
        }
      }
    });
    
    // 1. Tenta carregar imediatamente ao abrir
    _load();

    // 2. 🔹 NOVO: Configura o recebimento de notificações para este celular
    //_configurarPushNotifications();
    if (!kIsWeb) {
      _configurarPushNotifications();
    }

    // 3. 🔹 Refresh AGRESSIVO (Mude de 30 para 2 ou 3 segundos)
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
      // 🔹 ADICIONE ISSO AQUI PARA O STATUS APARECER ASSIM QUE ENTRAR NA HOME
      if (chatbotAtivo && instanciaWhatsapp != null) {
        _verificarStatusWhatsApp(instanciaWhatsapp!);
      }   
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
        .select('nome, email, logo_url, chatbot_ativo, instancia_whatsapp')
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
      chatbotAtivo = response['chatbot_ativo'] ?? false; // 👈 Inicializa a variável
      instanciaWhatsapp = response['instancia_whatsapp']; // Certifique-se de ter essa variável
    });

    // 🔹 ADICIONE ISSO AQUI:
    if (chatbotAtivo && instanciaWhatsapp != null) {
      _verificarStatusWhatsApp(instanciaWhatsapp!);
    }
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

  // 🔹 NOVO MÉTODO ADICIONADO:
  Future<void> _configurarPushNotifications() async {
    // 🔹 REGRA DE OURO: Não roda push notifications se estiver no navegador
    if (kIsWeb) return;

    try {
      final fcm = FirebaseMessaging.instance;
      final supabase = Supabase.instance.client;

      // Solicita permissão (especialmente para Android 13+ e iOS)
      NotificationSettings settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await fcm.getToken();
        final userId = supabase.auth.currentUser?.id;

        if (token != null && userId != null) {
          // Salva o token na tabela fcm_tokens que configuramos no DBeaver
          await supabase.from('fcm_tokens').upsert({
            'usuario_id': userId,
            'token': token,
            'dispositivo_tipo': 'android',
          }, onConflict: 'token');
          debugPrint('✅ Push Token registrado com sucesso!');
        }
      }
    } catch (e) {
      debugPrint('Erro ao configurar push: $e');
    }
  }

  Future<void> _toggleChatbot(bool status, String salaoId) async {
    try {
      // 1. Atualiza o banco de dados primeiro
      await Supabase.instance.client
          .from('saloes')
          .update({'chatbot_ativo': status})
          .eq('id', salaoId);

      setState(() {
        chatbotAtivo = status;
        if (status) statusConexao = 'checking'; // Reseta o visual para carregar o QR Code se for ativado
      });

      // 2. Se o status for ATIVO (true), chama a Edge Function
      /*
      if (status) {
        _chamarSetupEdgeFunction(salaoId);
      }
      */
      if (status) {
        // 1. Faz o setup (que abre o QR Code se necessário)
        await _chamarSetupEdgeFunction(salaoId);
        
        // 2. 🔹 ADICIONE ISSO: Força uma checagem de status logo após
        if (instanciaWhatsapp != null) {
          _verificarStatusWhatsApp(instanciaWhatsapp!);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status ? "Chatbot ativado e configurando..." : "Chatbot desativado."),
          backgroundColor: status ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao atualizar chatbot: $e');
    }
  }

  // 3. Nova função para chamar a Edge Function
  Future<void> _chamarSetupEdgeFunction(String salaoId) async {
    try {
      // Primeiro buscamos os dados atuais do salão para montar o body
      final res = await Supabase.instance.client
          .from('saloes')
          .select('instancia_whatsapp, celular, nome')
          .eq('id', salaoId)
          .single();

      // Chama a Edge Function via cliente do Supabase
      // O nome 'setup_salao_premium' deve ser o mesmo que está no seu console do Supabase
      final response =await Supabase.instance.client.functions.invoke(
        'setup_salao_premium',
        body: {
          "instancia": res['instancia_whatsapp'],
          "celular": res['celular'],
          "salaoNome": res['nome']
        },
      );

      debugPrint('✅ Edge Function chamada com sucesso!');

      // O retorno da function está em response.data
      final data = response.data;

      if (data != null && data['qrcode'] != null) {
        _exibirModalQRCode(data['qrcode']);
      } else {
        debugPrint('Instância já conectada ou QR Code não gerado.');
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao chamar Edge Function: $e');
      // Opcional: Avisar o usuário que o setup falhou
     }
  }  

  // 4. Função para verificar o status da conexão do WhatsApp (pode ser chamada em um timer ou após a função de setup)
  Future<void> _verificarStatusWhatsApp(String instancia) async {
    if (!mounted) return;

    try {
      // Vamos chamar a Evolution para ver o estado da conexão
      // Dica: Você pode criar uma Edge Function simplificada só para o check 
      // ou usar o invoke para uma que retorne o connectionState.
      final response = await Supabase.instance.client.functions.invoke(
        'setup_salao_premium', // Ela já tem o check de existência que retorna se está pronto
        body: { "instancia": instancia, 
                "celular": "CHECK", // Valor fictício só para passar na validação
                "salaoNome": nomeSalao
              },
      );

      if (!mounted) return;

      setState(() {
        statusConexao = response.data['success'] == true ? 'connected' : 'disconnected';
      });
      
    } catch (e) {
      if (mounted) setState(() => statusConexao = 'disconnected');
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

  void _exibirModalQRCode(String base64Image) {
    // Remove prefixos comuns se a API enviar (ex: data:image/png;base64,)
    final String cleanBase64 = base64Image.replaceFirst(RegExp(r'data:image\/[a-zA-Z]+;base64,'), '');

    showDialog(
      context: context,
      barrierDismissible: false, // Obriga o usuário a fechar no botão
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Escaneie o QR Code", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Abra o WhatsApp > Aparelhos Conectados > Conectar um aparelho.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.memory(
                  base64Decode(cleanBase64),
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

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
              leading: Icon(Icons.calendar_month),
              title: Text("Gerenciar Datas e Folgas"),
              subtitle: Text("Bloqueie datas específicas ou feriados"),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navega para a nova tela de gerenciamento de datas
                Navigator.push(context, MaterialPageRoute(builder: (context) => ConfiguracaoAgendaPage()));
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
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: t.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Status do Chatbot', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      if (statusConexao == 'checking' && chatbotAtivo)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                      else
                      // Bolinha de status
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: !chatbotAtivo 
                              ? Colors.grey 
                              : (statusConexao == 'connected' ? Colors.green : Colors.red),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        !chatbotAtivo ? "Desativado" : (statusConexao == 'connected' ? "Conectado" : "Aguardando Aparelho"),
                        style: TextStyle(color: chatbotAtivo && statusConexao == 'connected' ? Colors.green : Colors.grey),
                      ),
                    ],
                  ),
                  value: chatbotAtivo,
                  secondary: Icon(Icons.smart_toy_rounded, color: chatbotAtivo ? Colors.green : Colors.grey),
                  onChanged: (bool value) => _toggleChatbot(value, idSeguro),
                ),
                
                // 🔹 ITEM 2: BOTÃO QR CODE (Sempre visível se o bot estiver ativo)
                if (chatbotAtivo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => _chamarSetupEdgeFunction(idSeguro),
                      icon: const Icon(Icons.qr_code_scanner),
                      // Texto muda conforme o status para dar feedback ao usuário
                      label: Text(statusConexao == 'connected' 
                        ? "Reconectar / Ver QR Code" 
                        : "Visualizar QR Code"),
                      style: ElevatedButton.styleFrom(
                        // Cor muda para um tom mais neutro se já estiver conectado
                        backgroundColor: statusConexao == 'connected'
                            ? t.colorScheme.surfaceVariant
                            : t.colorScheme.primaryContainer,
                        foregroundColor: statusConexao == 'connected'
                            ? t.colorScheme.onSurfaceVariant
                            : t.colorScheme.onPrimaryContainer,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 20), // Espaço entre o card e os botões
          
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


    Widget _botaoNavegacao(String texto, VoidCallback onPressed, {bool isPremium = false}) {
      final t = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          height: 58, // Aumentei de 55 para 58 para dar mais margem de segurança no Android
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isPremium ? Colors.green.shade600 : t.colorScheme.primaryContainer,
              foregroundColor: isPremium ? Colors.white : t.colorScheme.onPrimaryContainer,
              elevation: isPremium ? 4 : 0,
              // Ajustamos o padding interno para garantir que o texto não encoste no fundo
              padding: const EdgeInsets.symmetric(vertical: 8), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
                // O 'height' ajuda a centralizar a fonte verticalmente e evita o corte do 'g' e 'p'
                height: 1.2, 
              ),
            ),
          ),
        ),
      );
    }

}