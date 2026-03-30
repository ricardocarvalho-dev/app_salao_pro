import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../models/cliente_model.dart';
import '../services/cliente_service.dart';
import 'package:app_salao_pro/utils/string_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // <--- ESSA LINHA AQUI

class ClientesPage extends StatefulWidget {
  final String salaoId;
  const ClientesPage({required this.salaoId, super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final ClienteService _clienteService = ClienteService();

  List<ClienteModel> _clientes = [];
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

  Future<void> _carregarClientes() async {
    final lista = await _clienteService.listarPorSalao(widget.salaoId);
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    setState(() {
      _clientes = lista;
    });
  }

  Future<void> _mostrarFormulario({ClienteModel? cliente}) async {
    if (cliente != null) {
      clienteIdEditando = cliente.id;
      nomeController.text = cliente.nome;
      // Se o número começar com 55, removemos para a máscara do formulário não bugar
      /*
      String telExibicao = cliente.celular.toTelefoneElegante();      
      if (telExibicao.startsWith('55')) {
          telExibicao = telExibicao.substring(2);
      } 
      */ 
      /*    
      // LOGICA: Remove o 55 se existir para a máscara não bugar
      String numeroLimpo = cliente.celular.replaceAll(RegExp(r'\D'), '');
      if (numeroLimpo.startsWith('55')) {
        numeroLimpo = numeroLimpo.substring(2);
      }      
      celularController.text = numeroLimpo; // A máscara (00) 00000-0000 fará o resto do trabalho de formatação
      */
      // LIMPEZA: Remove o 55 para o controller receber apenas o DDD + Numero
      String telbanco = cliente.celular.replaceAll(RegExp(r'\D'), '');
      if (telbanco.startsWith('55') && telbanco.length > 11) {
        celularController.text = telbanco.substring(2);
      } else {
        celularController.text = telbanco;
      }      
      emailController.text = cliente.email;

    } else {
      clienteIdEditando = null;
      nomeController.clear();
      celularController.clear();
      emailController.clear();
    }

    /*
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(cliente == null ? 'Novo Cliente' : 'Editar Cliente',
            style: Theme.of(context).textTheme.titleMedium),
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
            child: Text('Cancelar',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          TextButton(
            onPressed: _carregandoOperacao
                ? null
                : () async {
                    /*
                    final celularDigitado = celularController.text.trim();
                    // Remove tudo que não é número: ( ) - e espaços
                    String celularLimpo = celularDigitado.replaceAll(RegExp(r'\D'), '');
                    // Validação simples de tamanho (ex: 71999883190 tem 11 dígitos)
                    if (celularLimpo.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Celular incompleto!')),
                      );
                      return;
                    }   
                    // Garante que salve com 55 no banco
                    final celularParaBanco = celularLimpo.startsWith('55') ? celularLimpo : '55$celularLimpo';                                     
                    final nome = nomeController.text.trim();
                    //final celular = celularController.text.trim();
                    //final celularOriginal = celularController.text.trim();
                    //final celularLimpo = celularOriginal.replaceAll(RegExp(r'\D'), '');
                    //final celularParaBanco = celularLimpo.startsWith('55') ? celularLimpo : '55$celularLimpo';
                    final email = emailController.text.trim();

                    if (nome.isEmpty || celularParaBanco.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Preencha os campos obrigatórios!')),
                      );
                      return;
                    }

                    final cliente = ClienteModel(
                      id: clienteIdEditando ?? '',
                      nome: nome,
                      celular: celularParaBanco,
                      email: email,
                      salaoId: widget.salaoId,
                    );
                    */
                    final nome = nomeController.text.trim();
                      
                      // 1. Pegamos o que está no campo e removemos TUDO que não é número
                      String celularLimpo = celularController.text.replaceAll(RegExp(r'\D'), '');

                      // 2. Se o usuário digitou (71) 99966-4411, celularLimpo terá 11 dígitos.
                      // Se por acaso ele já digitou o 55, celularLimpo terá 13.
                      if (celularLimpo.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Celular inválido. Informe DDD + número')),
                        );
                        return;
                      }

                      // 3. PADRONIZAÇÃO: Agora forçamos o 55 para o banco
                      final celularParaBanco = celularLimpo.startsWith('55') 
                          ? celularLimpo 
                          : '55$celularLimpo';

                      final cliente = ClienteModel(
                        id: clienteIdEditando ?? '',
                        nome: nome,
                        celular: celularParaBanco, // Aqui vai o 5571999664411
                        email: emailController.text.trim(),
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
                      await _carregarClientes();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Cliente salvo com sucesso!')),
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Salvar',
                    style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
    */

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(cliente == null ? 'Novo Cliente' : 'Editar Cliente'),
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
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              
              // 1. Limpeza de celular (Igual ao Profissionais)
              String celularLimpo = celularController.text.replaceAll(RegExp(r'\D'), '');

              // 2. Validação de tamanho (Igual ao Profissionais)
              if (celularLimpo.length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Celular inválido. Informe DDD + número')),
                );
                return;
              }

              // 3. Validação de campos obrigatórios (Adaptado para Clientes)
              if (nome.isEmpty || celularLimpo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha nome e celular')),
                );
                return;
              }

              // 4. Padronização para o banco (Igual ao Profissionais)
              final celularParaBanco = celularLimpo.startsWith('55') 
                  ? celularLimpo 
                  : '55$celularLimpo';

              final model = ClienteModel(
                id: cliente?.id ?? '',
                nome: nome,
                celular: celularParaBanco,
                email: emailController.text.trim(),
                salaoId: widget.salaoId,
              );

              try {
                // Usando a lógica de salvar do Profissionais
                if (cliente == null) {
                  await _clienteService.adicionar(model);
                } else {
                  await _clienteService.atualizar(model);
                }
                
                if (mounted) Navigator.pop(context);
                await _carregarClientes(); // Supondo que sua função de atualizar lista seja esta
                
              } catch (e) {
                debugPrint('Erro ao salvar cliente: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao salvar cliente')),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

  }

  /*
  Future<void> _excluirCliente(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão',
            style: Theme.of(context).textTheme.titleMedium),
        content: Text('Deseja realmente excluir este cliente?',
            style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar',
                  style: Theme.of(context).textTheme.bodyMedium)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Excluir',
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _clienteService.excluir(id);
        await _carregarClientes();

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
  */

  Future<void> _excluirCliente(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // UI REATIVA: Remove da lista privada _clientes imediatamente
      setState(() {
        //_clientes.removeWhere((c) => c['id'] == id);
        _clientes.removeWhere((c) => c.id == id); 
      });

      try {
        await _clienteService.excluir(id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente excluído com sucesso!')),
          );
        }
      } catch (e) {
        // Se falhar, recarrega do banco para restaurar o item na tela
        await _carregarClientes();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir cliente: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesFiltrados = termoBusca.isEmpty
        ? _clientes
        : _clientes
            .where((c) =>
                c.nome.toLowerCase().contains(termoBusca.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: Padding(
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
                  ? Center(
                      child: Text('Nenhum cliente encontrado.',
                          style: Theme.of(context).textTheme.bodyMedium))
                  : ListView.builder(
                      itemCount: clientesFiltrados.length,
                      itemBuilder: (context, index) {
                        final cliente = clientesFiltrados[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cliente.nome,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(cliente.celular.toTelefoneElegante(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                      if (cliente.email.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(cliente.email,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
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
                                      onPressed: () =>
                                          _mostrarFormulario(cliente: cliente),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: 'Excluir',
                                      onPressed: () =>
                                          _excluirCliente(cliente.id),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, 
      {bool isPhone = false, bool isEmail = false, List<TextInputFormatter>? formatters}) {
    return TextField(
      controller: controller,
      inputFormatters: formatters,
      keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        // MOLDURA (Border)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }    

}
