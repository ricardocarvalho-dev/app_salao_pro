import 'package:flutter/material.dart';
import 'login_page.dart';

class ErroRecuperacaoPage extends StatelessWidget {
  const ErroRecuperacaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro na recuperação')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 20),
            const Text(
              'Não foi possível validar o link de recuperação de senha.\nEle pode ter expirado ou já ter sido usado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              child: const Text('Voltar para o Login'),
            ),
          ],
        ),
      ),
    );
  }
}
