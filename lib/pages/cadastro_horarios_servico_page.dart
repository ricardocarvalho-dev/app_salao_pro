import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/horario_servico_model.dart';
import '../providers/horario_servico_provider.dart';

// ======================
// ENUM E EXTENSION PARA DIAS DA SEMANA
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
// PAGINA DE HORÁRIOS
// ======================
class CadastroHorariosServicoPage extends ConsumerStatefulWidget {
  final String servicoId;
  final String servicoNome;

  const CadastroHorariosServicoPage({
    super.key,
    required this.servicoId,
    required this.servicoNome,
  });

  @override
  ConsumerState<CadastroHorariosServicoPage> createState() =>
      _CadastroHorariosServicoPageState();
}

class _CadastroHorariosServicoPageState
    extends ConsumerState<CadastroHorariosServicoPage> {
  HorarioServicoModel? editando;

  DiaSemana? diaSelecionado;
  TimeOfDay? horarioInicio;
  TimeOfDay? horarioFim;

  final diasEnum = DiaSemana.values;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(horarioServicoProvider.notifier)
          .carregarHorarios(widget.servicoId);
    });
  }

  String formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ======================
  // SALVAR
  // ======================
  Future<void> salvar() async {
    if (diaSelecionado == null || horarioInicio == null || horarioFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione dia e horários')),
      );
      return;
    }

    final inicioMin = horarioInicio!.hour * 60 + horarioInicio!.minute;
    final fimMin = horarioFim!.hour * 60 + horarioFim!.minute;

    if (inicioMin >= fimMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horário inicial deve ser menor que o final'),
        ),
      );
      return;
    }

    final horarios = ref.read(horarioServicoProvider).value ?? [];
    final diaInt = diaSelecionado!.index == 6 ? 0 : diaSelecionado!.index + 1;

    final duplicado = horarios.any(
      (h) =>
          h.diaSemana == diaInt &&
          (editando == null || h.id != editando!.id),
    );

    if (duplicado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe horário cadastrado para este dia'),
        ),
      );
      return;
    }

    final model = HorarioServicoModel(
      id: editando?.id ?? '',
      servicoId: widget.servicoId,
      diaSemana: diaInt,
      horarioInicio: formatHora(horarioInicio!),
      horarioFim: formatHora(horarioFim!),
      ativo: editando?.ativo ?? true,
    );

    final notifier = ref.read(horarioServicoProvider.notifier);

    if (editando == null) {
      await notifier.adicionarHorario(model);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário adicionado com sucesso')),
      );
    } else {
      await notifier.atualizarHorario(model);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário atualizado com sucesso')),
      );
    }

    setState(() {
      editando = null;
      diaSelecionado = null;
      horarioInicio = null;
      horarioFim = null;
    });
  }

  // ======================
  // BUILD
  // ======================
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(horarioServicoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar horários'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (horarios) {
          // Ordena os horários de Segunda a Domingo
          horarios.sort((a, b) {
            final diaA = diaSemanaFromSupabase(a.diaSemana).ordem;
            final diaB = diaSemanaFromSupabase(b.diaSemana).ordem;
            return diaA.compareTo(diaB);
          });

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Configurar horários para: ${widget.servicoNome}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<DiaSemana>(
                  value: diaSelecionado,
                  items: diasEnum
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.nome),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Dia da semana'),
                  onChanged: (v) => setState(() => diaSelecionado = v),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: horarioInicio ?? TimeOfDay.now(),
                          );
                          if (t != null) setState(() => horarioInicio = t);
                        },
                        child: Text(
                          horarioInicio == null
                              ? 'Início'
                              : formatHora(horarioInicio!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: horarioFim ?? TimeOfDay.now(),
                          );
                          if (t != null) setState(() => horarioFim = t);
                        },
                        child: Text(
                          horarioFim == null
                              ? 'Fim'
                              : formatHora(horarioFim!),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: salvar,
                  child: Text(editando == null ? 'Adicionar' : 'Salvar'),
                ),

                const Divider(height: 32),

                Expanded(
                  child: ListView.builder(
                    itemCount: horarios.length,
                    itemBuilder: (_, i) {
                      final h = horarios[i];

                      final dia = diaSemanaFromSupabase(h.diaSemana);

                      return Card(
                        child: ListTile(
                          title: Text(dia.nome),
                          subtitle: Text('${h.horarioInicio} - ${h.horarioFim}'),
                          leading: Switch(
                            value: h.ativo,
                            onChanged: (v) => ref
                                .read(horarioServicoProvider.notifier)
                                .atualizarStatus(h, v),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  final iSplit = h.horarioInicio.split(':');
                                  final fSplit = h.horarioFim.split(':');

                                  setState(() {
                                    editando = h;
                                    diaSelecionado = dia;
                                    horarioInicio = TimeOfDay(
                                      hour: int.parse(iSplit[0]),
                                      minute: int.parse(iSplit[1]),
                                    );
                                    horarioFim = TimeOfDay(
                                      hour: int.parse(fSplit[0]),
                                      minute: int.parse(fSplit[1]),
                                    );
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Excluir horário'),
                                      content: const Text(
                                          'Deseja realmente excluir este horário?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (ok == true) {
                                    await ref
                                        .read(horarioServicoProvider.notifier)
                                        .excluirHorario(h);
                                  }
                                },
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
    );
  }
}
