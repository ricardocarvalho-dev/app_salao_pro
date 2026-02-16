import 'package:flutter/material.dart';
import 'package:app_salao_pro/models/especialidade_model.dart';
import 'package:app_salao_pro/services/especialidade_service.dart';

class EspecialidadesPage extends StatefulWidget {
  final String salaoId;
  const EspecialidadesPage({required this.salaoId, Key? key}) : super(key: key);

  @override
  State<EspecialidadesPage> createState() => _EspecialidadesPageState();
}

class _EspecialidadesPageState extends State<EspecialidadesPage> {
  late EspecialidadeService service;
  List<EspecialidadeModel> especialidades = [];
  List<EspecialidadeModel> especialidadesFiltradas = [];
  final nomeController = TextEditingController();
  final pesquisaController = TextEditingController();
  String? especialidadeIdEditando;

  @override
  void initState() {
    super.initState();
    service = EspecialidadeService(widget.salaoId);
    carregarEspecialidades();

    pesquisaController.addListener(() {
      final termo = pesquisaController.text.toLowerCase();
      setState(() {
        especialidadesFiltradas = especialidades
            .where((e) => e.nome.toLowerCase().contains(termo))
            .toList();
      });
    });
  }

  Future<void> carregarEspecialidades() async {
    try {
      final lista = await service.listar();
      lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      setState(() {
        especialidades = lista;
        especialidadesFiltradas = lista;
      });
    } catch (e) {
      debugPrint('Erro ao carregar especialidades: $e');
    }
  }

  Future<void> mostrarFormulario({EspecialidadeModel? especialidade}) async {
    nomeController.text = especialidade?.nome ?? '';
    especialidadeIdEditando = especialidade?.id;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            especialidade == null ? 'Nova Especialidade' : 'Editar Especialidade',
          ),
          content: TextField(
            controller: nomeController,
            decoration: const InputDecoration(labelText: 'Nome da especialidade'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeController.text.trim();
                if (nome.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha o nome da especialidade')),
                  );
                  return;
                }

                try {
                  if (especialidade == null) {
                    await service.adicionar(EspecialidadeModel(
                      id: '',
                      nome: nome,
                      salaoId: widget.salaoId,
                    ));
                  } else {
                    await service.atualizar(EspecialidadeModel(
                      id: especialidade.id,
                      nome: nome,
                      salaoId: widget.salaoId,
                    ));
                  }

                  nomeController.clear();
                  especialidadeIdEditando = null;
                  Navigator.pop(context);
                  await carregarEspecialidades();
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  /*
  Future<void> excluirEspecialidade(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Deseja realmente excluir esta especialidade?'),
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
        );
      },
    );

    if (confirmar == true) {
      try {
        await service.excluir(id);
        await carregarEspecialidades();
      } catch (e) {
        debugPrint('Erro ao excluir especialidade: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }
  */
  Future<void> excluirEspecialidade(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Deseja realmente excluir esta especialidade?'),
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
        );
      },
    );

    if (confirmar == true) {
      try {
        await service.excluir(id);
        await carregarEspecialidades();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Especialidade excluída com sucesso!')),
        );
      } catch (e) {
        debugPrint('Erro ao excluir especialidade: $e');

        // 🔹 Tratamento personalizado
        /*
        final mensagem = e.toString().contains('serviços vinculados')
            ? 'Existem serviços vinculados a esta especialidade. Exclua ou edite os serviços antes.'
            : 'Erro ao excluir especialidade.';
        */         
        // 🔹 Se o backend retornar mensagem clara, usamos ela 
        final mensagem = e.toString().contains('foreign key') 
            ? 'Existem serviços vinculados a esta especialidade. Exclua ou edite os serviços antes.' 
            : 'Erro ao excluir especialidade.';            

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Especialidades')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: pesquisaController,
              decoration: const InputDecoration(
                labelText: 'Pesquisar especialidade',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: especialidadesFiltradas.isEmpty
                  ? const Center(child: Text('Nenhuma especialidade encontrada'))
                  : ListView.builder(
                      itemCount: especialidadesFiltradas.length,
                      itemBuilder: (context, index) {
                        final item = especialidadesFiltradas[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.nome,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Editar',
                                      onPressed: () =>
                                          mostrarFormulario(especialidade: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: 'Excluir',
                                      onPressed: () {
                                        if (item.id != null) {
                                          excluirEspecialidade(item.id!);
                                        }
                                      },
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
        onPressed: () => mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
