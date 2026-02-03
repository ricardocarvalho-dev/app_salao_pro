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
      celularController.text = widget.cliente!.celular;
      emailController.text = widget.cliente!.email;
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
        style: Theme.of(context).textTheme.titleMedium,
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
        TextButton(
          onPressed: carregando ? null : _salvar,
          child: carregando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _salvar() async {
    final nome = nomeController.text.trim();
    final celular = celularController.text.trim();
    final email = emailController.text.trim();

    if (nome.isEmpty || celular.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios')),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      final cliente = ClienteModel(
        id: widget.cliente?.id ?? '',
        nome: nome,
        celular: celular,
        email: email,
        salaoId: widget.salaoId,
      );

      String clienteId;

      if (widget.cliente == null) {
        // ✅ Novo cliente → retorna ID
        clienteId =
            await _clienteService.adicionarRetornandoId(cliente);
      } else {
        // ✅ Edição
        await _clienteService.atualizar(cliente);
        clienteId = cliente.id;
      }

      Navigator.pop(context, clienteId);
    } catch (e) {
      final mensagem = e is Exception
          ? e.toString().replaceAll('Exception: ', '')
          : 'Erro ao salvar cliente';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }
}
