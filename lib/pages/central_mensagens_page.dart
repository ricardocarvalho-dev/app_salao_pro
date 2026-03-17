import 'package:flutter/material.dart';
import '../widgets/conversa_card.dart';

class CentralMensagensPage extends StatefulWidget {
  final String salaoId; // 👈 O ID que passamos da HomePage

  const CentralMensagensPage({super.key, required this.salaoId});

  @override
  State<CentralMensagensPage> createState() => _CentralMensagensPageState();
}

class _CentralMensagensPageState extends State<CentralMensagensPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens do Chatbot'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Configurações do Bot (Exclusivo Premium)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner informativo do Plano Premium
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Seu assistente virtual está ativo e respondendo.",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          // Lista de conversas (Agora as buscas internas vão funcionar)
          Expanded(
            child: ListView(
              children: const [
                ConversaCard(
                  telefoneBanco: "(71) 98765-9043", // O "Match" acontece dentro deste Widget
                  ultimaMensagem: "Gostaria de saber o preço do corte.",
                  hora: "09:45",
                ),
                ConversaCard(
                  telefoneBanco: "(11) 99999-8888",
                  ultimaMensagem: "Quero agendar para amanhã às 14h.",
                  hora: "Ontem",
                ),
                ConversaCard(
                  telefoneBanco: "(71) 91234-5678",
                  ultimaMensagem: "Obrigada pelo atendimento!",
                  hora: "Segunda",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}