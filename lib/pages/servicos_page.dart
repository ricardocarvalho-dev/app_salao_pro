import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/servico_model.dart';
import '../services/servico_service.dart';
import '../pages/cadastro_horarios_servico_page.dart';

// ======================
// ENUM E EXTENSION PARA ORDEM DE DIAS
// ======================
enum DiaSemana { segunda, terca, quarta, quinta, sexta, sabado, domingo }

extension DiaSemanaExtension on DiaSemana {
  int get ordem {
    switch (this) {
      case DiaSemana.segunda:
        return 1;
      case DiaSemana.terca:
        return 2;
      case DiaSemana.quarta:
        return 3;
      case DiaSemana.quinta:
        return 4;
      case DiaSemana.sexta:
        return 5;
      case DiaSemana.sabado:
        return 6;
      case DiaSemana.domingo:
        return 7;
    }
  }

  String get nome => [
        'Segunda',
        'Terça',
        'Quarta',
        'Quinta',
        'Sexta',
        'Sábado',
        'Domingo'
      ][ordem - 1];
}

DiaSemana diaSemanaFromSupabase(int dia) {
  switch (dia) {
    case 0:
      return DiaSemana.domingo;
    case 1:
      return DiaSemana.segunda;
    case 2:
      return DiaSemana.terca;
    case 3:
      return DiaSemana.quarta;
    case 4:
      return DiaSemana.quinta;
    case 5:
      return DiaSemana.sexta;
    case 6:
      return DiaSemana.sabado;
    default:
      throw Exception('Dia da semana inválido: $dia');
  }
}

// ======================
// CLASSE PRINCIPAL
// ======================
class ServicosPage extends StatefulWidget {
  final String salaoId;

  const ServicosPage({
    super.key,
    required this.salaoId,
  });

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

  // ======================
  // DADOS
  // ======================
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

  // ======================
  // FORMULÁRIO
  // ======================
  Future<void> mostrarFormulario({ServicoModel? servico}) async {
    final nomeController = TextEditingController(text: servico?.nome ?? '');
    final descricaoController =
        TextEditingController(text: servico?.descricao ?? '');
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(servico == null ? 'Novo Serviço' : 'Editar Serviço'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration:
                    const InputDecoration(labelText: 'Nome do serviço'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descricaoController,
                decoration:
                    const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço do serviço (R\$)',
                ),
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
                decoration:
                    const InputDecoration(labelText: 'Duração'),
                items: duracoes
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      ),
                    )
                    .toList(),
                onChanged: (value) => duracaoSelecionada = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: especialidadeId,
                decoration:
                    const InputDecoration(labelText: 'Especialidade'),
                items: especialidades
                    .map(
                      (e) => DropdownMenuItem(
                        value: e['id'].toString(),
                        child: Text(e['nome'].toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) => especialidadeId = value,
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
              final descricao = descricaoController.text.trim();
              final preco = double.tryParse(
                    precoController.text
                        .replaceAll(RegExp(r'[^0-9,\.]'), '')
                        .replaceAll(',', '.'),
                  ) ??
                  0;

              if (nome.isEmpty ||
                  preco <= 0 ||
                  duracaoSelecionada == null ||
                  especialidadeId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Preencha todos os campos corretamente'),
                  ),
                );
                return;
              }

              final partes = duracaoSelecionada!.split(':');
              final duracao =
                  int.parse(partes[0]) * 60 + int.parse(partes[1]);

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

  // ======================
  // EXCLUIR
  // ======================
  Future<void> excluirServico(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content:
            const Text('Deseja realmente excluir este serviço?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await service.excluir(id);
      await carregarServicos();
    }
  }

  // ======================
  // BUILD
  // ======================
  @override
  Widget build(BuildContext context) {
    final listaFiltrada = especialidadeFiltro == null
        ? servicos
        : servicos
            .where((s) => s.especialidadeId == especialidadeFiltro)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: especialidadeFiltro,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por especialidade',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...especialidades.map(
                        (e) => DropdownMenuItem(
                          value: e['id'],
                          child: Text(e['nome']),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => especialidadeFiltro = value),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: listaFiltrada.isEmpty
                        ? const Center(
                            child:
                                Text('Nenhum serviço cadastrado.'),
                          )
                        : ListView.builder(
                            itemCount: listaFiltrada.length,
                            itemBuilder: (_, index) {
                              final servico = listaFiltrada[index];

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(servico.nome),
                                  subtitle: Text(
                                    '${servico.duracaoMinutos} min • '
                                    '${toCurrencyString(
                                      servico.preco
                                          .toStringAsFixed(2),
                                      leadingSymbol: 'R\$',
                                      thousandSeparator:
                                          ThousandSeparator.Period,
                                    )}',
                                  ),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.schedule),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CadastroHorariosServicoPage(
                                                servicoId: servico.id,
                                                servicoNome: servico.nome,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            mostrarFormulario(
                                          servico: servico,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            excluirServico(
                                          servico.id,
                                        ),
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
