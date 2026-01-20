import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_salao_pro/pages/login_page.dart';
import 'package:app_salao_pro/pages/home_page.dart';
import 'package:app_salao_pro/pages/redefinir_senha_page.dart';
import 'package:app_salao_pro/pages/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as myProvider;
import 'theme/theme_notifier.dart';
import 'package:app_salao_pro/theme/tema_salao_pro.dart';
import 'package:app_salao_pro/theme/horario_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Carregamento do .env
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: 'assets/.env');
    } catch (e) {
      debugPrint('Erro ao carregar .env: $e');
    }
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

  // ✅ Inicialização simplificada (Removemos o authOptions que deu erro)
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  await initializeDateFormatting('pt_BR', null);

  runApp(
    ProviderScope(
      child: myProvider.ChangeNotifierProvider(
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
  Widget build(BuildContext context) {
    final themeNotifier = myProvider.Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'App Salão Pro',
      navigatorKey: navigatorKey,
      theme: temaSalaoPro,
      darkTheme: temaSalaoProDark,
      themeMode: themeNotifier.themeMode,
      debugShowCheckedModeBanner: false,
      // ✅ Definindo as rotas necessárias
      routes: {
        '/login': (_) => const LoginPage(),
        '/redefinir-senha': (_) => const RedefinirSenhaPage(),
        // A rota '/' ou home será o SplashScreen definido abaixo
      },
      home: const SplashScreen(),
    );
  }
}