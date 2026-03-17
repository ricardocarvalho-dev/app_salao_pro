import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../models/profissional_model.dart';
import '../services/profissional_service.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:app_salao_pro/utils/string_extensions.dart';

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
    // Controller para o celular com o valor vindo do model se for edição
    final celularController = TextEditingController(text: profissional?.celular ?? '');
    
    
    List<String> especialidadesSelecionadas = [];
    String modoAgendamentoSelecionado = profissional?.modoAgendamento ?? 'por_profissional';

    if (profissional != null) {
      final profCompleto = await service.buscarPorId(profissional.id);
      especialidadesSelecionadas = profCompleto.especialidadeIds;
      // LIMPEZA: Remove o 55 para o controller receber apenas o DDD + Numero
      String telbanco = profissional.celular.replaceAll(RegExp(r'\D'), '');
      if (telbanco.startsWith('55') && telbanco.length > 11) {
        celularController.text = telbanco.substring(2);
      } else {
        celularController.text = telbanco;
      }      

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
              // NOVO: Campo de celular
              TextField(
                controller: celularController,
                decoration: const InputDecoration(labelText: 'Celular *'),
                keyboardType: TextInputType.phone,
                inputFormatters: [MaskedInputFormatter('(00) 00000-0000')],
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
              
              // LIMPEZA: Remove tudo que não for número e garante o 55
              //String celularLimpo = celularController.text.replaceAll(RegExp(r'[^0-9]'), '');
              //if (celularLimpo.isNotEmpty && !celularLimpo.startsWith('55')) {
              //  celularLimpo = '55$celularLimpo';
              //}

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

              if (nome.isEmpty || especialidadesSelecionadas.isEmpty || celularLimpo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha nome, especialidades e celular')),
                );
                return;
              }

              // 3. PADRONIZAÇÃO: Agora forçamos o 55 para o banco
              final celularParaBanco = celularLimpo.startsWith('55') 
                  ? celularLimpo 
                  : '55$celularLimpo';

              final model = ProfissionalModel(
                id: profissional?.id ?? '',
                nome: nome,
                salaoId: widget.salaoId,
                celular: celularParaBanco, // Enviando o número formatado para o banco
                especialidadeIds: especialidadesSelecionadas,
                modoAgendamento: modoAgendamentoSelecionado,
              );

              try {
                if (profissional == null) {
                  await service.adicionar(model);
                } else {
                  await service.atualizar(model);
                }
                if (mounted) Navigator.pop(context);
                await carregarDados();
              } catch (e) {
                debugPrint('Erro ao salvar profissional: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao salvar profissional')),
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

  Future<void> excluirProfissional(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este profissional?'),
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
      setState(() {
        profissionais.removeWhere((p) => p.id == id);
      });

      try {
        await service.excluir(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profissional excluído com sucesso!')),
          );
        }
      } catch (e) {
        await carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir profissional: $e')),
          );
        }
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
                                      const SizedBox(height: 4),
                                      Text(
                                        'Agendamento: ${profissional.modoAgendamento == 'por_profissional' ? 'Por Profissional' : 'Por Serviço'}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      // EXIBIÇÃO: Mostra o Zap salvo
                                      Text(
                                        (profissional.celular == 'null' || profissional.celular.isEmpty) ? '' : profissional.celular.toTelefoneElegante(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
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