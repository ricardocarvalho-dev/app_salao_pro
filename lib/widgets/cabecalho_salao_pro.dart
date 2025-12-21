import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login_page.dart';

class CabecalhoSalaoPro extends StatelessWidget {
  final String? titulo;
  final bool mostrarLogout;
  final String? salaoId;

  const CabecalhoSalaoPro({
    super.key,
    this.titulo,
    this.mostrarLogout = false,
    this.salaoId,
  });

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/logo_salao_pro_horiz.png',
          height: 80,
        ),
        if (titulo != null) ...[
          const SizedBox(height: 8),
          Text(
            titulo!,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        if (mostrarLogout)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
              onPressed: () => _logout(context),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
