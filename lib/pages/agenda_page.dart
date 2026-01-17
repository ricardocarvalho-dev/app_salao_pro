import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_salao_pro/models/agendamento_model.dart';
import 'package:app_salao_pro/services/agendamento_service.dart';
import 'package:app_salao_pro/pages/agendamento_movel.dart';
import 'package:app_salao_pro/providers/agendamento_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgendaPage extends ConsumerStatefulWidget {
  final String salaoId;
  final DateTime dataSelecionada;

  const AgendaPage({
    required this.salaoId,
    required this.dataSelecionada,
    super.key,
  });

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<AgendamentoModel> agendamentos = [];
  late AgendamentoService service;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    service = AgendamentoService(widget.salaoId);

    Future.microtask(() async {
      await carregarFiltrosAgenda();

      final notifier = ref.read(agendamentoProvider.notifier);
      notifier.setDataSelecionada(widget.dataSelecionada);
      
      // Força todos os combos ao estado inicial
      notifier.selecionarProfissional(null);
      notifier.selecionarCliente(null);
      notifier.selecionarServico(null);

      await carregarAgendamentos();
    });
  }

  /// Carrega filtros (clientes/profissionais/serviços) do Supabase e atualiza o provider
  Future<void> carregarFiltrosAgenda() async {
    final supabase = Supabase.instance.client;

    final c = await supabase.from('clientes').select().eq('salao_id', widget.salaoId);
    final clientesList = List<Map<String, dynamic>>.from(c);

    final p = await supabase.from('profissionais').select().eq('salao_id', widget.salaoId).order('nome');
    final profissionaisList = List<Map<String, dynamic>>.from(p);

    final s = await supabase.from('servicos').select().eq('salao_id', widget.salaoId).order('nome');
    final servicosList = List<Map<String, dynamic>>.from(s);

    final notifier = ref.read(agendamentoProvider.notifier);
    notifier.setClientes(clientesList);
    notifier.setProfissionais(profissionaisList);
    notifier.setServicos(servicosList);
  }

  Future<void> carregarAgendamentos() async {
    final state = ref.read(agendamentoProvider);
    final profissionalSelecionado = state.profissionalSelecionado;
    final servicoSelecionado = state.servicoSelecionado;

    if (_selectedDay == null) return;

    try {
      final ags = await service.getAgendamentos(
        _selectedDay!,
        profissionalId: (profissionalSelecionado == null || profissionalSelecionado.isEmpty)
            ? null
            : profissionalSelecionado,
        servicoId: (servicoSelecionado == null || servicoSelecionado.isEmpty)
            ? null
            : servicoSelecionado,
      );

      if (mounted) {
        setState(() {
          agendamentos = ags;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar agendamentos: $e');
    }
  }

  Future<void> cancelarAgendamento(String agendamentoId) async {
    await Supabase.instance.client
        .from('agendamentos')
        .update({'status': 'cancelado'})
        .eq('id', agendamentoId);

    await carregarAgendamentos();
  }

  /// ✅ Método atualizado usando AgendamentoService e WidgetRef
  Future<void> excluirAgendamento(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir este agendamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await service.excluir(id, ref); // 🔑 Passa o WidgetRef para o Service
        await carregarAgendamentos();
      } catch (e) {
        debugPrint('Erro ao excluir: $e');
      }
    }
  }

  Widget _buildFiltrosCalendario(AgendamentoState state) {
    final estilo = Theme.of(context).textTheme.bodyMedium;

    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              carregarAgendamentos();
            },
            calendarFormat: CalendarFormat.week,
            availableCalendarFormats: const {CalendarFormat.week: 'Semana'},
            rowHeight: 36,
            daysOfWeekHeight: 16,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              leftChevronIcon: Icon(Icons.chevron_left, size: 20),
              rightChevronIcon: Icon(Icons.chevron_right, size: 20),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(fontSize: 12),
              weekendTextStyle: const TextStyle(fontSize: 12),
              todayTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              selectedTextStyle: const TextStyle(fontSize: 12, color: Colors.white),
              todayDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
          ),
          const SizedBox(height: 16),

          // Profissional
          DropdownButtonFormField<String?>(
            value: state.profissionalSelecionado != null &&
                    state.profissionais.any((p) => p['id'].toString() == state.profissionalSelecionado)
                ? state.profissionalSelecionado
                : null,
            decoration: const InputDecoration(labelText: 'Profissional'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              ...state.profissionais.map(
                (p) => DropdownMenuItem<String?>(
                  value: p['id'].toString(),
                  child: Text(p['nome'].toString()),
                ),
              ),
            ],
            onChanged: (v) {
              ref.read(agendamentoProvider.notifier).selecionarProfissional(v);
              carregarAgendamentos();
            },
            style: estilo,
          ),

          const SizedBox(height: 16),

          // Serviço
          DropdownButtonFormField<String?>(
            value: state.servicoSelecionado != null &&
                    state.servicos.any((s) => s['id'].toString() == state.servicoSelecionado)
                ? state.servicoSelecionado
                : null,
            decoration: const InputDecoration(labelText: 'Serviço'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              ...state.servicos.map(
                (s) => DropdownMenuItem<String?>(
                  value: s['id'].toString(),
                  child: Text(s['nome'].toString()),
                ),
              ),
            ],
            onChanged: (v) {
              ref.read(agendamentoProvider.notifier).selecionarServico(v);
              carregarAgendamentos();
            },
            style: estilo,
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () async {
              if (_selectedDay == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selecione uma data antes de agendar.')),
                );
                return;
              }

              final hoje = DateTime.now();
              final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
              final diaSemHora = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

              if (diaSemHora.isBefore(hojeSemHora)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não é permitido criar agendamentos em datas passadas.'),
                  ),
                );
                return;
              }

              // Atualiza a data selecionada no provider (para a próxima tela)
              ref.read(agendamentoProvider.notifier).setDataSelecionada(_selectedDay!);

              final criado = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AgendamentoMovelPage(
                    salaoId: widget.salaoId,
                    dataSelecionada: _selectedDay!,
                    modoAgendamento: state.profissionalSelecionado != null ? 'por_profissional' : 'por_servico',
                    profissionalId: state.profissionalSelecionado,
                    servicoId: state.servicoSelecionado, 
                    clienteId: state.clienteId,
                  ),
                ),
              );

              // Reset filtros ao voltar
              final notifier = ref.read(agendamentoProvider.notifier);
              notifier.selecionarCliente(null); 
              notifier.selecionarProfissional(null);
              notifier.selecionarServico(null);
              notifier.setHorarioSelecionado(null);

              if (mounted) setState(() {});

              if (criado == true) {
                carregarAgendamentos();
              }

            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Novo Agendamento', style: estilo?.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    final state = ref.watch(agendamentoProvider);

    if (agendamentos.isEmpty) {
      return Center(
        child: Text('Nenhum agendamento para esse dia.', 
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    final ordenados = [...agendamentos]
      ..sort((a, b) => (a.hora.hour * 60 + a.hora.minute).compareTo(b.hora.hour * 60 + b.hora.minute));

    return ListView.builder(
      itemCount: ordenados.length,
      itemBuilder: (context, index) {
        final ag = ordenados[index];

        final nomeCliente = state.mapaClientes[ag.clienteId.toString()] ?? 'Cliente não identificado';
        final nomeServico = state.mapaServicos[ag.servicoId.toString()] ?? 'Serviço não identificado';
        final nomeProfissional = (ag.profissionalId != null && ag.profissionalId!.isNotEmpty)
            ? state.mapaProfissionais[ag.profissionalId.toString()] ?? 'Profissional'
            : 'Por serviço';

        final horaFormatada = '${ag.hora.hour.toString().padLeft(2, '0')}:${ag.hora.minute.toString().padLeft(2, '0')}';

        Color statusColor;
        switch (ag.status) {
          case AgendamentoStatus.pendente: statusColor = Colors.blue; break;
          case AgendamentoStatus.reagendado: statusColor = Colors.orange; break;
          case AgendamentoStatus.cancelado: statusColor = Colors.red; break;
          case AgendamentoStatus.confirmado: statusColor = Colors.green; break;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(horaFormatada, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(nomeCliente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('$nomeServico — $nomeProfissional', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(ag.status.name.toUpperCase(), style: TextStyle(fontSize: 12, color: statusColor)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: () async {
                      ref.read(agendamentoProvider.notifier).selecionarProfissional(ag.profissionalId);
                      
                      final alterado = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgendamentoMovelPage(
                            modoAgendamento: ag.profissionalId != null ? 'por_profissional' : 'por_servico',
                            profissionalId: ag.profissionalId,
                            servicoId: ag.servicoId,
                            clienteId: ag.clienteId,
                            salaoId: widget.salaoId,
                            dataSelecionada: _selectedDay ?? widget.dataSelecionada,
                          ),
                        ),
                      );
                      if (alterado == true) carregarAgendamentos();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () async => await cancelarAgendamento(ag.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => excluirAgendamento(ag.id),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda do Salão')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(agendamentoProvider);
                return _buildFiltrosCalendario(state);
              },
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }
}
