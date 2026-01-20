import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../pages/login_page.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager instance =
      AppLifecycleManager._internal();

  AppLifecycleManager._internal();

  static const Duration maxBackgroundTime = Duration(minutes: 2);

  DateTime? _pausedAt;

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      if (_pausedAt == null) return;

      final elapsed = DateTime.now().difference(_pausedAt!);

      debugPrint('⏱️ App ficou em background por ${elapsed.inSeconds}s');

      if (elapsed > maxBackgroundTime) {
        debugPrint('🔐 Tempo excedido → logout');

        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }

      _pausedAt = null;
    }
  }
}
