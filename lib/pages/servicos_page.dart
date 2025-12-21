import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/servico_model.dart';
import '../services/servico_service.dart';
import '../pages/cadastro_horarios_servico_page.dart';

class ServicosPage extends StatefulWidget {
  final String salaoId;
  const ServicosPage({required this.salaoId, super.key});

  @override
  State<ServicosPage> createState() => _ServicosPageState();
}

class _ServicosPageState extends State<ServicosPage> {
  late ServicoService service;
  List<ServicoModel> servicos = [];
  List<Map<String, dynamic>> especialidades = [];
  bool carregando = true;
  String? especialidadeFiltro;

  final List<String> duracoes = List.generate(
    (24 * 4) - 1,
    (index) {
      final minutoTotal = (index + 1) * 15; 
      final hora = minutoTotal ~/ 60;
      final minuto = minutoTotal % 60;
      return '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
    },
  );

  @override
  void initState() {
    super.initState();
    service = ServicoService(widget.salaoId);
    carregarServicos();
    carregarEspecialidades();
  }

  Future<void> carregarServicos() async {
    final lista = await service.listar();
    lista.sort((a, b) {
      final espA = a.nomeEspecialidade?.toLowerCase() ?? '';
      final espB = b.nomeEspecialidade?.toLowerCase() ?? '';
      final nomeA = a.nome.toLowerCase();
      final nomeB = b.nome.toLowerCase();
      final compEsp = espA.compareTo(espB);
      return compEsp != 0 ? compEsp : nomeA.compareTo(nomeB);
    });
    setState(() {
      servicos = lista;
      carregando = false;
    });
  }

  Future<void> carregarEspecialidades() async {
    final response = await Supabase.instance.client
        .from('especialidades')
        .select('id, nome')
        .eq('salao_id', widget.salaoId)
        .order('nome');

    setState(() {
      especialidades = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> mostrarFormulario({ServicoModel? servico}) async {
    final nomeController = TextEditingController(text: servico?.nome ?? '');
    final descricaoController = TextEditingController(text: servico?.descricao ?? '');
    final precoController = TextEditingController(
      text: servico != null
          ? toCurrencyString(
              servico.preco.toStringAsFixed(2),
              leadingSymbol: 'R\$',
              useSymbolPadding: true,
              thousandSeparator: ThousandSeparator.Period,
            )
          : '',
    );
    String? duracaoSelecionada = servico != null
        ? '${(servico.duracaoMinutos ~/ 60).toString().padLeft(2, '0')}:${(servico.duracaoMinutos % 60).toString().padLeft(2, '0')}'
        : null;
    String? especialidadeId = servico?.especialidadeId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(servico == null ? 'Novo Serviço' : 'Editar Serviço'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do serviço'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precoController,
                decoration: const InputDecoration(labelText: 'Preço do serviço (R\$)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  MoneyInputFormatter(
                    leadingSymbol: 'R\$',
                    useSymbolPadding: true,
                    thousandSeparator: ThousandSeparator.Period,
                    mantissaLength: 2,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: duracaoSelecionada,
                decoration: const InputDecoration(labelText: 'Duração (horas:minutos)'),
                items: duracoes.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (value) => duracaoSelecionada = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: especialidadeId,
                decoration: const InputDecoration(labelText: 'Especialidade'),
                items: especialidades.map((e) {
                  return DropdownMenuItem(value: e['id'].toString(), child: Text(e['nome'].toString()));
                }).toList(),
                onChanged: (value) => especialidadeId = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              final descricao = descricaoController.text.trim();
              final preco = double.tryParse(
                precoController.text.replaceAll(RegExp(r'[^0-9,\.]'), '').replaceAll(',', '.'),
              ) ?? 0;

              if (nome.isEmpty || preco <= 0 || duracaoSelecionada == null || especialidadeId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha todos os campos corretamente')),
                );
                return;
              }

              final partes = duracaoSelecionada!.split(':');
              final duracao = int.parse(partes[0]) * 60 + int.parse(partes[1]);

              final model = ServicoModel(
                id: servico?.id ?? '',
                nome: nome,
                descricao: descricao,
                preco: preco,
                duracaoMinutos: duracao,
                salaoId: widget.salaoId,
                especialidadeId: especialidadeId,
              );

              if (servico == null) {
                await service.adicionar(model);
              } else {
                await service.atualizar(model);
              }

              Navigator.pop(context);
              await carregarServicos();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> excluirServico(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este serviço?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await service.excluir(id);
        await carregarServicos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = especialidadeFiltro == null
        ? servicos
        : servicos.where((s) => s.especialidadeId == especialidadeFiltro).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
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
                      ...especialidades.map((esp) => DropdownMenuItem(value: esp['id'], child: Text(esp['nome']))),
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
                        ? const Center(child: Text('Nenhum serviço cadastrado.'))
                        : ListView.builder(
                            itemCount: listaFiltrada.length,
                            itemBuilder: (context, index) {
                              final servico = listaFiltrada[index];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (servico.nomeEspecialidade != null) ...[
                                              Row(
                                                children: [
                                                  Text('Especialidade: ',
                                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                                  Text(servico.nomeEspecialidade!,
                                                      style: Theme.of(context).textTheme.bodyMedium),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                            Row(
                                              children: [
                                                Text('Nome do serviço: ',
                                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                                Text(servico.nome, style: Theme.of(context).textTheme.bodyMedium),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Text('Preço: ',
                                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                                Text(
                                                  toCurrencyString(
                                                    servico.preco.toStringAsFixed(2),
                                                    leadingSymbol: 'R\$',
                                                    useSymbolPadding: true,
                                                    thousandSeparator: ThousandSeparator.Period,
                                                  ),
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Text('Duração: ',
                                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                                Text('${servico.duracaoMinutos} minutos',
                                                    style: Theme.of(context).textTheme.bodyMedium),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.schedule),
                                            tooltip: 'Horários',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => CadastroHorariosServicoPage(
                                                    servicoId: servico.id,
                                                    salaoId: widget.salaoId,
                                                    servicoNome: servico.nome,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            tooltip: 'Editar',
                                            onPressed: () => mostrarFormulario(servico: servico),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            tooltip: 'Excluir',
                                            onPressed: () => excluirServico(servico.id),
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
