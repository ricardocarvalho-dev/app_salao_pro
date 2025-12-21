import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:app_salao_pro/pages/login_page.dart';
import 'package:app_salao_pro/pages/home_page.dart';

class AuthService {
  static Future<Widget> verificarLogin() async {
    // Aguarda a inicialização completa do Supabase
    final client = Supabase.instance.client;

    // Verifica se há sessão ativa
    final session = client.auth.currentSession;
    final user = client.auth.currentUser;

    if (session == null || user == null) {
      return const LoginPage();
    }

    // Aqui você pode buscar o salaoId real do usuário, se necessário
    return const HomePage(salaoId: '');
  }
}
