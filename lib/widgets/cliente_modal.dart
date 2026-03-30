import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../models/cliente_model.dart';
import '../services/cliente_service.dart';

class ClienteModal extends StatefulWidget {
  final String salaoId;
  final ClienteModel? cliente;

  const ClienteModal({
    super.key,
    required this.salaoId,
    this.cliente,
  });

  @override
  State<ClienteModal> createState() => _ClienteModalState();
}

class _ClienteModalState extends State<ClienteModal> {
  final ClienteService _clienteService = ClienteService();

  final nomeController = TextEditingController();
  final celularController = TextEditingController();
  final emailController = TextEditingController();

  bool carregando = false;

  @override
  void initState() {
    super.initState();

    if (widget.cliente != null) {
      nomeController.text = widget.cliente!.nome;
      emailController.text = widget.cliente!.email;
      
      String telBanco = widget.cliente!.celular.replaceAll(RegExp(r'\D'), '');
      if (telBanco.startsWith('55') && telBanco.length > 11) {
        celularController.text = telBanco.substring(2);
      } else {
        celularController.text = telBanco;
      }      
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    celularController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.cliente == null ? 'Novo Cliente' : 'Editar Cliente',
        // Removido o style antigo para seguir o padrão limpo
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: celularController,
              decoration: const InputDecoration(labelText: 'Celular *'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                MaskedInputFormatter('(00) 00000-0000'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: carregando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton( // Alterado para ElevatedButton para seguir o padrão
          onPressed: carregando ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF97316), // Laranja padrão
            foregroundColor: Colors.white,
          ),
          child: carregando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, 
                    color: Colors.white
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _salvar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();

    // 1. Limpeza de celular (Igual ao ClientesPage)
    String celularLimpo = celularController.text.replaceAll(RegExp(r'\D'), '');

    // 2. Validação de tamanho (Igual ao ClientesPage)
    if (celularLimpo.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Celular inválido. Informe DDD + número')),
      );
      return;
    }

    // 3. Validação de campos obrigatórios
    if (nome.isEmpty || celularLimpo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e celular')),
      );
      return;
    }

    // 4. Padronização para o banco
    final celularParaBanco = celularLimpo.startsWith('55') 
        ? celularLimpo 
        : '55$celularLimpo';

    setState(() => carregando = true);

    try {
      final model = ClienteModel(
        id: widget.cliente?.id ?? '',
        nome: nome,
        celular: celularParaBanco,
        email: email,
        salaoId: widget.salaoId,
      );

      String clienteId;

      if (widget.cliente == null) {
        // Usa o método que retorna o ID (importante para o AgendamentoMovel)
        clienteId = await _clienteService.adicionarRetornandoId(model);
      } else {
        await _clienteService.atualizar(model);
        clienteId = model.id;
      }

      if (mounted) Navigator.pop(context, clienteId);
    } catch (e) {
      debugPrint('Erro ao salvar cliente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar cliente')),
        );
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }
}