import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

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

  /// Função interna para lidar com links (autenticação Supabase)
  static Future<void> _handleLink(Uri uri) async {
    try {
      await supabase.auth.getSessionFromUrl(uri);
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
