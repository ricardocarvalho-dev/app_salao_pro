import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'main.dart'; // importa o navigatorKey definido no main.dart

final supabase = Supabase.instance.client;

class DeepLinkHandler {
  static StreamSubscription<Uri?>? _sub;
  static AppLinks? _appLinks;

  /// Inicializa a escuta de deep links (somente mobile)
  static void init() {
    if (kIsWeb) return;

    _appLinks = AppLinks();
    _sub = _appLinks!.uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        await _handleLink(uri);
      }
    });
  }

  /// Trata o deep link inicial (quando o app é aberto via link)
  static Future<void> handleInitialLink(String link) async {
    try {
      final uri = Uri.parse(link);
      await _handleLink(uri);
    } catch (e) {
      debugPrint('Erro ao tratar deep link inicial: $e');
    }
  }

  /// Função interna para lidar com links (autenticação Supabase + navegação)
  /*
  static Future<void> _handleLink(Uri uri) async {
    try {
      debugPrint('Processando deep link: $uri');

      final response = await supabase.auth.getSessionFromUrl(uri);

      if (response.session != null) {
        debugPrint('Sessão obtida: ${response.session!.accessToken}');
        // ✅ aplica a sessão ao cliente
        Supabase.instance.client.auth.currentSession = response.session;
      } else {
        debugPrint('Nenhuma sessão retornada do deep link');
      }

      // ✅ Substitui a SplashScreen pela tela de redefinição
      navigatorKey.currentState?.pushReplacementNamed('/redefinir-senha');
      debugPrint('Navegando para /redefinir-senha');
    } catch (e) {
      debugPrint('Erro ao processar deep link: $e');
    }
  }
  */
  /*
  static Future<void> _handleLink(Uri uri) async {
    try {
      debugPrint('Processando deep link: $uri');

      final response = await supabase.auth.getSessionFromUrl(uri);

      if (response.session != null) {
        debugPrint('Sessão obtida: ${response.session!.accessToken}');
        // Não precisa setar manualmente, Supabase já aplica a sessão
      } else {
        debugPrint('Nenhuma sessão retornada do deep link');
      }

      navigatorKey.currentState?.pushReplacementNamed('/redefinir-senha');
      debugPrint('Navegando para /redefinir-senha');
    } catch (e) {
      debugPrint('Erro ao processar deep link: $e');
    }
  }
  */
  static Future<void> _handleLink(Uri uri) async {
    try {
      debugPrint('Processando deep link: $uri');

      final response = await supabase.auth.getSessionFromUrl(uri);

      if (response.session != null) {
        debugPrint('Sessão obtida com sucesso!');
        debugPrint('AccessToken: ${response.session!.accessToken}');
        debugPrint('User ID: ${response.session!.user.id}');
        debugPrint('User Email: ${response.session!.user.email}');
      } else {
        debugPrint('Nenhuma sessão retornada do deep link');
      }

      navigatorKey.currentState?.pushReplacementNamed('/redefinir-senha');
      debugPrint('Navegando para /redefinir-senha');
    } catch (e) {
      debugPrint('Erro ao processar deep link: $e');
    }
  }

  /// Cancela a escuta de deep links
  static void dispose() {
    _sub?.cancel();
    _sub = null;
    _appLinks = null;
  }
}
