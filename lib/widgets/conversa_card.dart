import 'package:flutter/material.dart';
import '../services/contato_service.dart';

class ConversaCard extends StatefulWidget {
  final String telefoneBanco; // Recebe (71) 98765-9043
  final String ultimaMensagem;
  final String hora;

  const ConversaCard({
    super.key,
    required this.telefoneBanco,
    required this.ultimaMensagem,
    required this.hora,
  });

  @override
  State<ConversaCard> createState() => _ConversaCardState();
}

class _ConversaCardState extends State<ConversaCard> {
  String? _nomeIdentificado;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _identificarContato();
  }

  Future<void> _identificarContato() async {
    // Chama o seu service que acabamos de criar
    final nome = await ContatoService.buscarNomeNaAgenda(widget.telefoneBanco);
    if (mounted) {
      setState(() {
        _nomeIdentificado = nome;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Icon(Icons.person, color: Colors.green.shade800),
      ),
      // Se achou na agenda, mostra o nome. Se não, mostra o número formatado.
      title: Text(
        _nomeIdentificado ?? widget.telefoneBanco,
        style: TextStyle(
          fontWeight: _nomeIdentificado != null ? FontWeight.bold : FontWeight.normal,
          color: _nomeIdentificado != null ? Colors.black : Colors.grey.shade700,
        ),
      ),
      subtitle: Text(
        widget.ultimaMensagem,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        widget.hora,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        // Aqui abriria a tela de histórico que criamos no banco
      },
    );
  }
}