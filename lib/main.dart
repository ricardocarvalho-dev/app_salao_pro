import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_salao_pro/pages/login_page.dart';
import 'package:app_salao_pro/pages/home_page.dart';
import 'package:app_salao_pro/pages/redefinir_senha_page.dart';
import 'package:app_salao_pro/pages/splash_screen.dart';
import 'package:app_salao_pro/pages/agenda_page.dart'; // 🔹 Adicionado
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as my_provider;
import 'theme/theme_notifier.dart';
import 'package:app_salao_pro/theme/tema_salao_pro.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔹 Adicionado

final navigatorKey = GlobalKey<NavigatorState>();
// 🚀 Variável para guardar a notificação se o app ainda não estiver pronto
RemoteMessage? notificacaoPendente;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Carregamento do .env
  if (!kIsWeb) {
    // 1. Carrega o .env
    try {
      await dotenv.load(fileName: 'assets/.env');
    } catch (e) {
      debugPrint('Erro ao carregar .env: $e');
    }

    // 2. Inicializa o Firebase (Push Notifications)
    try {
      await Firebase.initializeApp();
      debugPrint('🔥 Firebase inicializado com sucesso (Mobile)');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Firebase: $e');
    }
  } else {
    debugPrint('🌐 Rodando no Chrome: Ignorando .env local e Firebase Push (usando chaves Web)');
  }

  // ✅ Busca das credenciais
  final supabaseUrl = kIsWeb 
      ? 'https://xwbabsvbcwlqfgcnmxtj.supabase.co' 
      : dotenv.env['SUPABASE_URL'];
  final supabaseKey = kIsWeb
      ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3YmFic3ZiY3dscWZnY25teHRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1MTY1NjMsImV4cCI6MjA3MzA5MjU2M30.ENSnMxK61X0jXuqyftmlw51p3K7pd_ON7eBDZppPY0U'
      : dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    throw Exception('SUPABASE_URL ou SUPABASE_ANON_KEY não encontrados');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  await initializeDateFormatting('pt_BR', null);

  runApp(
    ProviderScope(
      child: my_provider.ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    // 🔔 Só configura notificações se NÃO for Web (Chrome)
    // Isso evita o erro de "FirebaseException" que você viu no log
    if (!kIsWeb) {
      _setupNotificationListeners();
    } else {
      debugPrint("🌐 Info: Ambiente Web detectado. Notificações Push ignoradas.");
    }
  }  

  Future<void> _setupNotificationListeners() async {
    // 1. App totalmente fechado
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _tratarNavegacaoNotificacao(initialMessage);
    }

    // 2. App em segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen(_tratarNavegacaoNotificacao);
  }

  void _tratarNavegacaoNotificacao(RemoteMessage message) {
    final data = message.data;
    if (data['tipo'] == 'novo_agendamento') {
      try {
        final String dataStr = data['dataAgendamento'];
        DateTime dataAgendamento = DateTime.parse(dataStr);

        // 🎯 Se o Navigator ainda não existe (App abrindo), guardamos!
        if (navigatorKey.currentState == null) {
          notificacaoPendente = message; 
          debugPrint("⏳ App carregando... Notificação guardada para a Home.");
        } else {
          // Se já estamos com o app pronto, usamos a sua função atual
          _navegarComSeguranca(data, dataAgendamento);
        }
      } catch (e) {
        debugPrint("❌ Erro: $e");
      }
    }
  }
  
  // 🚀 Função que garante a navegação mesmo que o App esteja abrindo
  /*
  void _navegarComSeguranca(Map<String, dynamic> data, DateTime dataAgendamento) {
    if (navigatorKey.currentState != null) {
      debugPrint("✅ Navigator pronto! Navegando para o dia: $dataAgendamento");
      
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AgendamentoMovelPage(
            salaoId: data['salaoId'],
            dataSelecionada: dataAgendamento,
            clienteId: data['clienteId'],
            profissionalId: (data['profissionalId'] == null || data['profissionalId'].toString().isEmpty) 
                ? null 
                : data['profissionalId'],
            servicoId: data['servicoId'],
            modoAgendamento: 'por_servico',
          ),
        ),
      );
    } else {
      // Se o navigatorKey ainda for nulo, o App ainda está no Splash ou carregando.
      // Esperamos 500ms e tentamos de novo.
      debugPrint("⏳ Navigator ainda não disponível... tentando em 500ms");
      Future.delayed(
        const Duration(milliseconds: 500), 
        () => _navegarComSeguranca(data, dataAgendamento)
      );
    }
  }
  */
  // 🚀 Função atualizada para abrir a AGENDA e não o formulário
  void _navegarComSeguranca(Map<String, dynamic> data, DateTime dataAgendamento) {
    if (navigatorKey.currentState != null) {
      debugPrint("✅ Navigator pronto! Abrindo a Agenda no dia: $dataAgendamento");
      
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AgendaPage(
            salaoId: data['salaoId'],
            dataSelecionada: dataAgendamento, // Alinhado com o parâmetro da sua AgendaPage
          ),
        ),
      );
    } else {
      debugPrint("⏳ Navigator ainda não disponível... tentando em 500ms");
      Future.delayed(
        const Duration(milliseconds: 500), 
        () => _navegarComSeguranca(data, dataAgendamento)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = my_provider.Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Salão Pro', // 🔹 Alterado aqui também
      navigatorKey: navigatorKey,
      theme: temaSalaoPro,
      darkTheme: temaSalaoProDark,
      themeMode: themeNotifier.themeMode,
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (_) => const LoginPage(),
        '/redefinir-senha': (_) => const RedefinirSenhaPage(),
      },
      home: const SplashScreen(),
      onGenerateRoute: (settings) { 
        if (settings.name == '/home') { 
          final salaoId = settings.arguments as String; 
          return MaterialPageRoute( builder: (_) => HomePage(salaoId: salaoId)); 
        } 
        return null; 
      },      
    );
  }
}