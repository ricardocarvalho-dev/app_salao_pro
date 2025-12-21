import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/horario_servico_model.dart';
import '../services/horario_servico_service.dart';
import '../services/servico_service.dart';
import '../models/servico_model.dart';
import '../theme/tema_salao_pro.dart';

class CadastroHorariosServicoPage extends StatefulWidget {
  final String servicoId;
  final String salaoId;
  final String servicoNome;

  const CadastroHorariosServicoPage({
    required this.servicoId,
    required this.salaoId,
    required this.servicoNome,
    super.key,
  });

  @override
  State<CadastroHorariosServicoPage> createState() =>
      _CadastroHorariosServicoPageState();
}

class _CadastroHorariosServicoPageState
    extends State<CadastroHorariosServicoPage> {
  final service = HorarioServicoService();
  final diasSemana = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo'
  ];

  final Map<String, int> ordemDias = {
    'Segunda': 1,
    'Terça': 2,
    'Quarta': 3,
    'Quinta': 4,
    'Sexta': 5,
    'Sábado': 6,
    'Domingo': 7,
  };

  String? diaSelecionado;
  TimeOfDay? horarioInicio;
  TimeOfDay? horarioFim;
  List<HorarioServicoModel> horarios = [];
  bool carregando = true;
  String? nomeServico;
  HorarioServicoModel? horarioEditando;

  @override
  void initState() {
    super.initState();
    diaSelecionado = 'placeholder';
    carregarHorarios();
    carregarNomeServico();
  }

  Future<void> carregarHorarios() async {
    try {
      final lista = await service.listarPorServico(widget.servicoId);
      setState(() {
        horarios = lista
            .where((h) =>
                h.diaSemana != null && ordemDias.containsKey(h.diaSemana))
            .toList()
          ..sort((a, b) =>
              ordemDias[a.diaSemana]!.compareTo(ordemDias[b.diaSemana]!));
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar horários: $e');
    }
  }

  Future<void> carregarNomeServico() async {
    try {
      final servico =
          await ServicoService(widget.salaoId).buscarPorId(widget.servicoId);
      setState(() => nomeServico = servico?.nome ?? widget.servicoNome);
    } catch (e) {
      setState(() => nomeServico = widget.servicoNome);
    }
  }

  Future<void> adicionarHorario() async {
    if (diaSelecionado == null ||
        diaSelecionado == 'placeholder' ||
        horarioInicio == null ||
        horarioFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione dia e horários')),
      );
      return;
    }

    final existe = horarios.any((h) =>
        h.diaSemana == diaSelecionado &&
        (horarioEditando == null || h.id != horarioEditando!.id));

    if (existe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Já existe um horário para esse dia da semana')),
      );
      return;
    }

    final inicioFormatado =
        '${horarioInicio!.hour.toString().padLeft(2, '0')}:${horarioInicio!.minute.toString().padLeft(2, '0')}';
    final fimFormatado =
        '${horarioFim!.hour.toString().padLeft(2, '0')}:${horarioFim!.minute.toString().padLeft(2, '0')}';

    final novo = HorarioServicoModel(
      id: horarioEditando?.id ?? '',
      servicoId: widget.servicoId,
      diaSemana: diaSelecionado!,
      horarioInicio: inicioFormatado,
      horarioFim: fimFormatado,
      ativo: horarioEditando?.ativo ?? true,
      createdAt: horarioEditando?.createdAt ?? DateTime.now(),
    );

    if (horarioEditando == null) {
      await service.adicionar(novo);
    } else {
      await service.atualizar(novo);
    }

    await carregarHorarios();
    setState(() {
      diaSelecionado = 'placeholder';
      horarioInicio = null;
      horarioFim = null;
      horarioEditando = null;
    });
  }

  Future<void> excluirHorario(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este horário?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
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
        await carregarHorarios();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não é possível excluir: este horário possui agendamentos')),
        );
      }
    }
  }

  Future<TimeOfDay?> selecionarHorario(
      BuildContext context, String label) async {
    return await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: label,
      builder: (context, child) {
        return MediaQuery(
          data:
              MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
  }

  String formatarHorario(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }

  String formatarTextoHorario(String hora) {
    final partes = hora.split(':');
    return '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horários do Serviço')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (nomeServico != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Configurar horários para: $nomeServico',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: diaSelecionado ?? 'placeholder',
                        decoration: const InputDecoration(
                          labelText: 'Dia da semana',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'placeholder',
                            child: Text(
                              'Dia da semana',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ...diasSemana.map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                        ],
                        onChanged: (value) =>
                            setState(() => diaSelecionado = value),
                      ),
                      const SizedBox(height: 12),
                      // Botões seguem o tema (brancos)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final selecionado = await selecionarHorario(
                                context, 'Selecionar horário de início');
                            if (selecionado != null) {
                              setState(() => horarioInicio = selecionado);
                            }
                          },
                          child: Text(
                            horarioInicio == null
                                ? 'Selecionar horário de início'
                                : 'Início: ${formatarHorario(horarioInicio!)}',
                          ),
                        ),
                      ),
                      /*
                      ElevatedButton(
                        onPressed: () async {
                          final selecionado = await selecionarHorario(
                              context, 'Selecionar horário de início');
                          if (selecionado != null) {
                            setState(() => horarioInicio = selecionado);
                          }
                        },
                        child: Text(
                          horarioInicio == null
                              ? 'Selecionar horário de início'
                              : 'Início: ${formatarHorario(horarioInicio!)}',
                        ),
                      ),
                      */
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final selecionado = await selecionarHorario(
                                context, 'Selecionar horário de fim');
                            if (selecionado != null) {
                              setState(() => horarioFim = selecionado);
                            }
                          },
                          child: Text(
                            horarioFim == null
                                ? 'Selecionar horário de fim'
                                : 'Fim: ${formatarHorario(horarioFim!)}',
                          ),
                        ),
                      ),                      
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: adicionarHorario,
                          child: Text(
                            horarioEditando == null
                                ? 'Adicionar horário'
                                : 'Salvar alterações',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // LISTA DE HORÁRIOS
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: horarios.length,
                    itemBuilder: (context, index) {
                      final h = horarios[index];
                      /*
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dia da semana:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontSize: 16)),
                              Text(h.diaSemana ?? ''),
                              const SizedBox(height: 8),

                              Text('Horário:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontSize: 16)),
                              Text(
                                  '${formatarTextoHorario(h.horarioInicio)} - '
                                  '${formatarTextoHorario(h.horarioFim)}'),
                              const SizedBox(height: 8),

                              Text('Status:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontSize: 16)),
                              Text(h.ativo == true ? 'Ativo' : 'Inativo'),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(h.ativo == true
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => service
                                        .atualizarStatus(
                                            h.id, !(h.ativo ?? false))
                                        .then((_) => carregarHorarios()),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        horarioEditando = h;
                                        diaSelecionado =
                                            h.diaSemana ?? 'placeholder';

                                        final pI =
                                            h.horarioInicio.split(':');
                                        final pF = h.horarioFim.split(':');

                                        horarioInicio = TimeOfDay(
                                          hour: int.parse(pI[0]),
                                          minute: int.parse(pI[1]),
                                        );
                                        horarioFim = TimeOfDay(
                                          hour: int.parse(pF[0]),
                                          minute: int.parse(pF[1]),
                                        );
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => excluirHorario(h.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                      */
                      /*
                      return Card(
                        color: Theme.of(context).cardColor,
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // -------------------------------------
                              // COLUNA DE INFORMAÇÕES
                              // -------------------------------------
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // DIA DA SEMANA
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Dia da semana:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(fontSize: 16),
                                        ),
                                        Text(
                                          h.diaSemana ?? '',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // HORÁRIO
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Horário:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(fontSize: 16),
                                        ),
                                        Text(
                                          '${formatarTextoHorario(h.horarioInicio)} - ${formatarTextoHorario(h.horarioFim)}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // STATUS
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Status:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(fontSize: 16),
                                        ),

                                        // Status color adaptável
                                        Text(
                                          h.ativo == true ? 'Ativo' : 'Inativo',
                                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                color: h.ativo == true
                                                    ? Colors.greenAccent.shade400
                                                    : Colors.redAccent.shade200,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // -------------------------------------
                              // COLUNA DE BOTÕES
                              // -------------------------------------
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      h.ativo == true ? Icons.visibility : Icons.visibility_off,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    onPressed: () => service
                                        .atualizarStatus(h.id, !(h.ativo ?? false))
                                        .then((_) => carregarHorarios()),
                                  ),

                                  IconButton(
                                    icon: Icon(Icons.edit,
                                        color: Theme.of(context).iconTheme.color),
                                    onPressed: () {
                                      setState(() {
                                        horarioEditando = h;
                                        diaSelecionado = h.diaSemana ?? 'placeholder';

                                        final pI = h.horarioInicio.split(':');
                                        final pF = h.horarioFim.split(':');

                                        horarioInicio = TimeOfDay(
                                          hour: int.parse(pI[0]),
                                          minute: int.parse(pI[1]),
                                        );
                                        horarioFim = TimeOfDay(
                                          hour: int.parse(pF[0]),
                                          minute: int.parse(pF[1]),
                                        );
                                      });
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => excluirHorario(h.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                      */
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              // ======= COLUNA ESQUERDA (Labels + Valores) =======
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // --- Dia da semana ---
                                    Row(
                                      children: [
                                        Text(
                                          'Dia da semana: ',
                                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16),
                                        ),
                                        Text(
                                          h.diaSemana ?? '',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // --- Horário ---
                                    Row(
                                      children: [
                                        Text(
                                          'Horário: ',
                                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16),
                                        ),
                                        Text(
                                          '${formatarTextoHorario(h.horarioInicio)} - ${formatarTextoHorario(h.horarioFim)}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // --- Status ---
                                    Row(
                                      children: [
                                        Text(
                                          'Status: ',
                                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16),
                                        ),
                                        Text(
                                          h.ativo == true ? 'Ativo' : 'Inativo',
                                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                color: h.ativo == true ? Colors.green : Colors.red,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // ======= COLUNA DIREITA (Botões) =======
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(h.ativo == true ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () =>
                                        service.atualizarStatus(h.id, !(h.ativo ?? false)).then((_) => carregarHorarios()),
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        horarioEditando = h;
                                        diaSelecionado = h.diaSemana ?? 'placeholder';

                                        final pI = h.horarioInicio.split(':');
                                        final pF = h.horarioFim.split(':');

                                        horarioInicio = TimeOfDay(
                                          hour: int.parse(pI[0]),
                                          minute: int.parse(pI[1]),
                                        );
                                        horarioFim = TimeOfDay(
                                          hour: int.parse(pF[0]),
                                          minute: int.parse(pF[1]),
                                        );
                                      });
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => excluirHorario(h.id),
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
  }
}
