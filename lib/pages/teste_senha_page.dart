import 'package:flutter/material.dart';

class TesteSenhaPage extends StatefulWidget {
  const TesteSenhaPage({super.key});

  @override
  State<TesteSenhaPage> createState() => _TesteSenhaPageState();
}

class _TesteSenhaPageState extends State<TesteSenhaPage> {
  final senhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teste de Senha')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: senhaController,
              obscureText: !_senhaVisivel,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _senhaVisivel = !_senhaVisivel;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
