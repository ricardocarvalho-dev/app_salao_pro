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
import 'package:app_salao_pro/deep_link_handler.dart';
import 'package:app_salao_pro/theme/horario_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await dotenv.load(fileName: 'assets/.env');
  }

  await Supabase.initialize(
    url: kIsWeb
        ? 'https://xwbabsvbcwlqfgcnmxtj.supabase.co'
        : dotenv.env['SUPABASE_URL']!,
    anonKey: kIsWeb
        ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3YmFic3ZiY3dscWZnY25teHRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1MTY1NjMsImV4cCI6MjA3MzA5MjU2M30.ENSnMxK61X0jXuqyftmlw51p3K7pd_ON7eBDZppPY0U' 
        : dotenv.env['SUPABASE_ANON_KEY']!,
    // ⚠️ Removido o parâmetro authOptions, não existe na versão 1.x
  );

  await initializeDateFormatting('pt_BR', null);

  runApp(
    myProvider.ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
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
    // Inicializa deep links logo após o primeiro frame
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        DeepLinkHandler.initUniLinks(ctx);
      }
    });
    */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //DeepLinkHandler.initUniLinks();
      DeepLinkHandler.init();
    });
  }

  @override
  void dispose() {
    //DeepLinkHandler.disposeUniLinks();
    DeepLinkHandler.dispose();
    super.dispose();
  }

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
      routes: {
        '/login': (_) => const LoginPage(),
        '/redefinir-senha': (_) => const RedefinirSenhaPage(), // ✅ adicionada
      },
      home: const SplashScreen(),
    );
  }
}
