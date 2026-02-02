import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_salao_pro/models/agendamento_model.dart';
import 'package:app_salao_pro/services/agendamento_service.dart';
import 'package:app_salao_pro/pages/agendamento_movel.dart';
import 'package:app_salao_pro/providers/agendamento_provider.dart';
import 'package:app_salao_pro/providers/agenda_filtro_provider.dart';

class AgendaPage extends ConsumerStatefulWidget {
  final String salaoId;
  final DateTime dataSelecionada;

  const AgendaPage({
    super.key,
    required this.salaoId,
    required this.dataSelecionada,
  });

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  late AgendamentoService service;
  List<AgendamentoModel> agendamentos = [];

  @override
  void initState() {
    super.initState();

    _selectedDay = widget.dataSelecionada;
    _focusedDay = widget.dataSelecionada;
    service = AgendamentoService(widget.salaoId);

    Future.microtask(() async {
      // 🔹 carrega SOMENTE dados base
      await ref
          .read(agendamentoProvider.notifier)
          .carregarFiltros(widget.salaoId);

      await carregarAgendamentos();
    });
  }

  /// 🔥 limpa apenas os filtros da agenda
  @override
  void dispose() {
    ref.read(agendaFiltroProvider.notifier).state = AgendaFiltroState();
    super.dispose();
  }

  Future<void> carregarAgendamentos() async {
    if (_selectedDay == null) return;

    final filtros = ref.read(agendaFiltroProvider);

    try {
      final lista = await service.getAgendamentos(
        _selectedDay!,
        profissionalId: filtros.profissionalId,
        servicoId: filtros.servicoId,
      );

      if (mounted) {
        setState(() => agendamentos = lista);
      }
    } catch (e) {
      debugPrint('Erro ao carregar agendamentos: $e');
    }
  }

  Future<void> excluirAgendamento(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir este agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await service.excluir(id, ref);
      await carregarAgendamentos();
    }
  }

  Widget _buildFiltrosCalendario() {
    final dados = ref.watch(agendamentoProvider);
    final filtros = ref.watch(agendaFiltroProvider);

    return Column(
      children: [
        TableCalendar(
          locale: 'pt_BR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) =>
              isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.week,
          availableCalendarFormats: const {
            CalendarFormat.week: 'Semana',
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            carregarAgendamentos();
          },
        ),

        const SizedBox(height: 16),

        /// 🔹 PROFISSIONAL
        DropdownButtonFormField<String?>(
          value: filtros.profissionalId,
          decoration: const InputDecoration(labelText: 'Profissional'),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Todos'),
            ),
            ...dados.profissionais.map(
              (p) => DropdownMenuItem<String?>(
                value: p['id'].toString(),
                child: Text(p['nome']),
              ),
            ),
          ],
          onChanged: (v) {
            ref.read(agendaFiltroProvider.notifier).state =
                //filtros.copyWith(profissionalId: v);
                AgendaFiltroState(
                  profissionalId: v,
                  servicoId: null, // 🔥 limpa o outro filtro
                );                
            carregarAgendamentos();
          },
        ),

        const SizedBox(height: 16),

        /// 🔹 SERVIÇO
        DropdownButtonFormField<String?>(
          value: filtros.servicoId,
          decoration: const InputDecoration(labelText: 'Serviço'),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Todos'),
            ),
            ...dados.servicos.map(
              (s) => DropdownMenuItem<String?>(
                value: s['id'].toString(),
                child: Text(s['nome']),
              ),
            ),
          ],
          onChanged: (v) {
            ref.read(agendaFiltroProvider.notifier).state =
                //filtros.copyWith(servicoId: v);
                AgendaFiltroState(
                  profissionalId: null, // 🔥 limpa o outro filtro
                  servicoId: v,
                );                
            carregarAgendamentos();
          },
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Novo Agendamento'),
          onPressed: () async {
            if (_selectedDay == null) return;

            final criado = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => AgendamentoMovelPage(
                  salaoId: widget.salaoId,
                  dataSelecionada: _selectedDay!,
                  clienteId: null,
                ),
              ),
            );

            if (criado == true) {
              await carregarAgendamentos();
            }
          },
        ),
      ],
    );
  }

  Widget _buildLista() {
    if (agendamentos.isEmpty) {
      return const Center(
        child: Text('Nenhum agendamento para este dia.'),
      );
    }

    return ListView.builder(
      itemCount: agendamentos.length,
      itemBuilder: (_, i) {
        final ag = agendamentos[i];

        final hora =
            '${ag.hora.hour.toString().padLeft(2, '0')}:${ag.hora.minute.toString().padLeft(2, '0')}';
        /*
        return ListTile(
          title: Text('$hora — ${ag.clienteNome ?? 'Cliente'}'),
          subtitle: Text(
            '${ag.servicoNome ?? 'Serviço'} • ${ag.profissionalNome ?? 'Por serviço'}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => excluirAgendamento(ag.id),
          ),
        );
        */ 
        return ListTile(
          title: Text(
            '$hora — ${ag.clienteNome ?? ''}',
          ),
          subtitle: Text(
            '${ag.servicoNome ?? ''} • '
            '${ag.profissionalNome != null ? ag.profissionalNome! : 'Por serviço'}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => excluirAgendamento(ag.id),
          ),
        );
        
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFiltrosCalendario(),
            const SizedBox(height: 12),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }
}
