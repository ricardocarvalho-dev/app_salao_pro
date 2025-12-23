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

    try {
      _appLinks = AppLinks();
      _sub = _appLinks!.uriLinkStream.listen((Uri? uri) async {
        if (uri != null) {
          try {
            await _handleLink(uri);
          } catch (e, s) {
            //debugPrint('Erro interno ao processar link: $e\n$s');
          }
        }
      }, onError: (err) {
        //debugPrint('Erro no stream de deep links: $err');
      });
    } catch (e, s) {
      //debugPrint('Erro ao inicializar AppLinks: $e\n$s');
    }
  }

  /// Trata o deep link inicial (quando o app é aberto via link)
  static Future<void> handleInitialLink(String link) async {
    try {
      final uri = Uri.parse(link);
      await _handleLink(uri);
    } catch (e, s) {
      //debugPrint('Erro ao tratar deep link inicial: $e\n$s');
    }
  }

  /// Função interna para lidar com links (autenticação Supabase + navegação)
  static Future<void> _handleLink(Uri uri) async {
    try {
      //debugPrint('Processando deep link: $uri');

      final response = await supabase.auth.getSessionFromUrl(uri);

      if (response.session != null) {
        //debugPrint('Sessão obtida com sucesso!');
        //debugPrint('User: ${response.session!.user.email}');
      } else {
        //debugPrint('Nenhuma sessão retornada do deep link');
      }

      // ✅ Navegação protegida
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushReplacementNamed('/redefinir-senha');
        //debugPrint('Navegando para /redefinir-senha');
      } else {
        debugPrint('Navigator ainda não está pronto');
      }
    } catch (e, s) {
      //debugPrint('Erro ao processar deep link: $e\n$s');
    }
  }

  /// Cancela a escuta de deep links
  static void dispose() {
    try {
      _sub?.cancel();
    } catch (_) {}
    _sub = null;
    _appLinks = null;
  }
}
