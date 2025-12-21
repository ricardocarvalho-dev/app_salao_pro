import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../models/cliente_model.dart';
import '../services/cliente_service.dart';

class ClientesPage extends StatefulWidget {
  final String salaoId;
  const ClientesPage({required this.salaoId, super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final ClienteService _clienteService = ClienteService();
  late Future<List<ClienteModel>> clientesFuture;

  String? clienteIdEditando;
  final nomeController = TextEditingController();
  final celularController = TextEditingController();
  final emailController = TextEditingController();

  bool _carregandoOperacao = false;
  String termoBusca = '';

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  void _carregarClientes() {
    setState(() {
      clientesFuture = _clienteService.listarPorSalao(widget.salaoId).then((lista) {
        lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        return lista;
      });
    });
  }

  Future<void> _mostrarFormulario({ClienteModel? cliente}) async {
    if (cliente != null) {
      clienteIdEditando = cliente.id;
      nomeController.text = cliente.nome;
      celularController.text = cliente.celular;
      emailController.text = cliente.email;
    } else {
      clienteIdEditando = null;
      nomeController.clear();
      celularController.clear();
      emailController.clear();
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(cliente == null ? 'Novo Cliente' : 'Editar Cliente', style: Theme.of(context).textTheme.titleMedium),
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
                inputFormatters: [MaskedInputFormatter('(00) 00000-0000')],
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
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: Theme.of(context).textTheme.bodyMedium),
          ),
          TextButton(
            onPressed: _carregandoOperacao
                ? null
                : () async {
                    final nome = nomeController.text.trim();
                    final celular = celularController.text.trim();
                    final email = emailController.text.trim();

                    if (nome.isEmpty || celular.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preencha os campos obrigatórios!')),
                      );
                      return;
                    }

                    final cliente = ClienteModel(
                      id: clienteIdEditando ?? '',
                      nome: nome,
                      celular: celular,
                      email: email,
                      salaoId: widget.salaoId,
                    );

                    setState(() => _carregandoOperacao = true);

                    try {
                      if (clienteIdEditando == null) {
                        await _clienteService.adicionar(cliente);
                      } else {
                        await _clienteService.atualizar(cliente);
                      }

                      Navigator.pop(context);
                      _carregarClientes();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cliente salvo com sucesso!')),
                      );
                    } catch (e) {
                      final mensagem = e is Exception
                          ? e.toString().replaceAll('Exception: ', '')
                          : 'Erro ao salvar cliente';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(mensagem)),
                      );
                    } finally {
                      setState(() => _carregandoOperacao = false);
                    }
                  },
            child: _carregandoOperacao
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Salvar', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirCliente(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão', style: Theme.of(context).textTheme.titleMedium),
        content: Text('Deseja realmente excluir este cliente?', style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: Theme.of(context).textTheme.bodyMedium)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Excluir', style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _clienteService.excluir(id);
        _carregarClientes();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente excluído com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir cliente: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clientes')),
      body: FutureBuilder<List<ClienteModel>>(
        future: clientesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final todosClientes = snapshot.data!;
          final clientesFiltrados = termoBusca.isEmpty
              ? todosClientes
              : todosClientes.where((c) => c.nome.toLowerCase().contains(termoBusca.toLowerCase())).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar cliente por nome',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onChanged: (value) {
                    setState(() => termoBusca = value);
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: clientesFiltrados.isEmpty
                      ? Center(child: Text('Nenhum cliente encontrado.', style: Theme.of(context).textTheme.bodyMedium))
                      : ListView.builder(
                          itemCount: clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = clientesFiltrados[index];
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cliente.nome,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(cliente.celular, style: Theme.of(context).textTheme.bodyMedium),
                                          if (cliente.email.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(cliente.email, style: Theme.of(context).textTheme.bodyMedium),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Editar',
                                          onPressed: () => _mostrarFormulario(cliente: cliente),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Excluir',
                                          onPressed: () => _excluirCliente(cliente.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
