import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../models/profissional_model.dart';
import '../services/profissional_service.dart';

class ProfissionaisPage extends StatefulWidget {
  final String salaoId;
  const ProfissionaisPage({required this.salaoId, super.key});

  @override
  State<ProfissionaisPage> createState() => _ProfissionaisPageState();
}

class _ProfissionaisPageState extends State<ProfissionaisPage> {
  late ProfissionalService service;
  List<ProfissionalModel> profissionais = [];
  List<Map<String, dynamic>> especialidades = [];
  bool carregando = true;
  String? especialidadeFiltro;

  @override
  void initState() {
    super.initState();
    service = ProfissionalService();
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() => carregando = true);
    try {
      final lista = await service.listarPorSalao(widget.salaoId);

      final espResponse = await Supabase.instance.client
          .from('especialidades')
          .select('id, nome')
          .order('nome');

      final especialidadesMap = (espResponse as List<dynamic>)
          .map((e) => {
                'id': (e['id'] as dynamic).toString(),
                'nome': (e['nome'] as dynamic).toString(),
              })
          .toList();

      lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

      setState(() {
        profissionais = lista;
        especialidades = especialidadesMap;
        carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      setState(() => carregando = false);
    }
  }

  Future<void> mostrarFormulario({ProfissionalModel? profissional}) async {
    final nomeController = TextEditingController(text: profissional?.nome ?? '');
    List<String> especialidadesSelecionadas = [];
    String modoAgendamentoSelecionado = profissional?.modoAgendamento ?? 'por_profissional';

    if (profissional != null) {
      final profCompleto = await service.buscarPorId(profissional.id);
      especialidadesSelecionadas = profCompleto.especialidadeIds;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(profissional == null ? 'Novo Profissional' : 'Editar Profissional'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: modoAgendamentoSelecionado,
                decoration: const InputDecoration(labelText: 'Modo de Agendamento'),
                items: const [
                  DropdownMenuItem(value: 'por_profissional', child: Text('Por Profissional')),
                  DropdownMenuItem(value: 'por_servico', child: Text('Por Serviço')),
                ],
                onChanged: (value) {
                  modoAgendamentoSelecionado = value ?? 'por_profissional';
                },
              ),
              const SizedBox(height: 12),
              MultiSelectDialogField<String>(
                items: especialidades
                    .map((esp) => MultiSelectItem<String>(
                          (esp['id'] as dynamic).toString(),
                          (esp['nome'] as dynamic).toString(),
                        ))
                    .toList(),
                initialValue: especialidadesSelecionadas,
                title: const Text("Especialidades"),
                buttonText: const Text("Selecione especialidades"),
                onConfirm: (values) {
                  especialidadesSelecionadas = values;
                },
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
              if (nome.isEmpty || especialidadesSelecionadas.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha todos os campos')),
                );
                return;
              }

              final model = ProfissionalModel(
                id: profissional?.id ?? '',
                nome: nome,
                salaoId: widget.salaoId,
                especialidadeIds: especialidadesSelecionadas,
                modoAgendamento: modoAgendamentoSelecionado,
              );

              try {
                if (profissional == null) {
                  await service.adicionar(model);
                } else {
                  await service.atualizar(model);
                }
                Navigator.pop(context);
                await carregarDados();
              } catch (e) {
                debugPrint('Erro ao salvar profissional: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao salvar profissional')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> excluirProfissional(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este profissional?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await service.excluir(id);
        await carregarDados();
      } catch (e) {
        debugPrint('Erro ao excluir profissional: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = especialidadeFiltro == null
        ? profissionais
        : profissionais.where((p) => p.especialidadeIds.contains(especialidadeFiltro)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Profissionais')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: especialidadeFiltro,
                    decoration: const InputDecoration(labelText: 'Filtrar por especialidade'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ...especialidades.map((esp) {
                        return DropdownMenuItem(value: esp['id'], child: Text(esp['nome']));
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        especialidadeFiltro = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: listaFiltrada.isEmpty
                        ? const Center(child: Text('Nenhum profissional cadastrado.'))
                        : ListView.builder(
                            itemCount: listaFiltrada.length,
                            itemBuilder: (context, index) {
                              final profissional = listaFiltrada[index];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(profissional.nome,
                                          style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Especialidades: ${profissional.nomesEspecialidades?.join(", ") ?? "Nenhuma"}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Agendamento: ${profissional.modoAgendamento == 'por_profissional' ? 'Por Profissional' : 'Por Serviço'}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            tooltip: 'Editar',
                                            onPressed: () => mostrarFormulario(profissional: profissional),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            tooltip: 'Excluir',
                                            onPressed: () => excluirProfissional(profissional.id),
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