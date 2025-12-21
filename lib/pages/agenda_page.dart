import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_salao_pro/models/agendamento_model.dart';
import 'package:app_salao_pro/services/agendamento_service.dart';
import 'package:app_salao_pro/pages/agendamento_movel.dart';
import 'package:app_salao_pro/widgets/cabecalho_salao_pro.dart';

class AgendaPage extends StatefulWidget {
  final String salaoId;
  final DateTime dataSelecionada;

  const AgendaPage({
    required this.salaoId,
    required this.dataSelecionada,
    super.key,
  });

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<AgendamentoModel> agendamentos = [];
  late AgendamentoService service;

  String modoAgendamento = 'por_profissional';
  String? profissionalSelecionado;
  String? servicoSelecionado;

  List<Map<String, dynamic>> profissionais = [];
  List<Map<String, dynamic>> servicos = [];
  List<Map<String, dynamic>> clientes = [];

  Map<String, String> mapaProfissionais = {};
  Map<String, String> mapaServicos = {};
  Map<String, String> mapaClientes = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    service = AgendamentoService(widget.salaoId);
    buscarModoAgendamento();
    carregarFiltros().then((_) => carregarAgendamentos());
  }

  Future<void> buscarModoAgendamento() async {
    try {
      final response = await Supabase.instance.client
          .from('saloes')
          .select('modo_agendamento')
          .eq('id', widget.salaoId)
          .single();

      setState(() {
        modoAgendamento = response['modo_agendamento'] ?? 'por_profissional';
      });
    } catch (_) {}
  }

  Future<void> carregarFiltros() async {
    final supabase = Supabase.instance.client;

    final profs = await supabase
        .from('profissionais')
        .select()
        .eq('salao_id', widget.salaoId)
        .order('nome');

    final servs = await supabase
        .from('servicos')
        .select()
        .eq('salao_id', widget.salaoId)
        .order('nome');

    final clis = await supabase
        .from('clientes')
        .select()
        .eq('salao_id', widget.salaoId)
        .order('nome');

    setState(() {
      profissionais = List<Map<String, dynamic>>.from(profs);
      servicos = List<Map<String, dynamic>>.from(servs);
      clientes = List<Map<String, dynamic>>.from(clis);

      mapaProfissionais = {for (var p in profs) p['id']: p['nome']};
      mapaServicos = {for (var s in servs) s['id']: s['nome']};
      mapaClientes = {for (var c in clis) c['id']: c['nome']};
    });
  }

  Future<void> carregarAgendamentos() async {
    if (_selectedDay == null) return;

    try {
      final ags = await service.getAgendamentos(
        _selectedDay!,
        profissionalId: profissionalSelecionado?.isEmpty ?? true ? null : profissionalSelecionado,
        servicoId: servicoSelecionado?.isEmpty ?? true ? null : servicoSelecionado,
      );

      setState(() {
        agendamentos = ags;
      });
    } catch (_) {}
  }

  Future<void> cancelarAgendamento(String agendamentoId) async {
    await Supabase.instance.client
        .from('agendamentos')
        .update({'status': 'cancelado'})
        .eq('id', agendamentoId);

    await carregarAgendamentos();
  }

  void excluirAgendamento(String id) async {
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
        await service.excluir(id);
        await carregarAgendamentos();
      } catch (_) {}
    }
  }

  Widget _buildFiltrosCalendario() {
    final estilo = Theme.of(context).textTheme.bodyMedium;

    return Column(
      children: [
        // ---- CALENDÁRIO CORRIGIDO ----
        TableCalendar(
          locale: 'pt_BR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

          // Agora permite clicar em qualquer data:
          enabledDayPredicate: (_) => true,

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

        // ---- FILTROS ----
        if (modoAgendamento == 'por_profissional')
          DropdownButtonFormField<String>(
            value: profissionalSelecionado,
            decoration: const InputDecoration(labelText: 'Profissional'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...profissionais.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['nome']))),
            ],
            onChanged: (v) {
              setState(() => profissionalSelecionado = v);
              carregarAgendamentos();
            },
            style: estilo,
          ),

        if (modoAgendamento == 'por_servico')
          DropdownButtonFormField<String>(
            value: servicoSelecionado,
            decoration: const InputDecoration(labelText: 'Serviço'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...servicos.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['nome']))),
            ],
            onChanged: (v) {
              setState(() => servicoSelecionado = v);
              carregarAgendamentos();
            },
            style: estilo,
          ),

        const SizedBox(height: 16),

        // ---- BOTÃO DE NOVO AGENDAMENTO ----
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

            final criado = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => AgendamentoMovelPage(
                  clienteId: Supabase.instance.client.auth.currentUser?.id ?? '',
                  salaoId: widget.salaoId,
                  dataSelecionada: _selectedDay!,
                  modoAgendamento: modoAgendamento,
                ),
              ),
            );

            if (criado == true) carregarAgendamentos();
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
    );
  }

  Widget _buildLista() {
    if (agendamentos.isEmpty) {
      return Center(
        child: Text('Nenhum agendamento para esse dia.',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    final ordenados = [...agendamentos]
      ..sort((a, b) {
        final minA = a.hora.hour * 60 + a.hora.minute;
        final minB = b.hora.hour * 60 + b.hora.minute;
        return minA.compareTo(minB);
      });

    return ListView.builder(
      itemCount: ordenados.length,
      itemBuilder: (context, index) {
        final ag = ordenados[index];
        final nomeProfissional = mapaProfissionais[ag.profissionalId ?? ''] ?? 'Profissional';
        final nomeServico = mapaServicos[ag.servicoId] ?? 'Serviço';
        final nomeCliente = mapaClientes[ag.clienteId] ?? 'Cliente';

        final horaFormatada =
            '${ag.hora.hour.toString().padLeft(2, '0')}:${ag.hora.minute.toString().padLeft(2, '0')}';

        Color statusColor;
        switch (ag.status) {
          case 'pendente':
            statusColor = Colors.blue;
            break;
          case 'reagendado':
            statusColor = Colors.orange;
            break;
          case 'cancelado':
            statusColor = Colors.red;
            break;
          case 'concluido':
            statusColor = Colors.green;
            break;
          default:
            statusColor = Colors.grey;
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
              // Conteúdo principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(horaFormatada,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(nomeCliente,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('$nomeServico — $nomeProfissional',
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(ag.status.toUpperCase(),
                        style: TextStyle(fontSize: 12, color: statusColor)),
                  ],
                ),
              ),

              // Ações
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: () async {
                      final alterado = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgendamentoMovelPage(
                            modoAgendamento:
                                ag.profissionalId != null ? 'por_profissional' : 'por_servico',
                            agendamentoId: ag.id,
                            profissionalId: ag.profissionalId,
                            servicoId: ag.servicoId,
                            clienteId: ag.clienteId,
                            salaoId: widget.salaoId,
                            dataSelecionada: widget.dataSelecionada,
                            podeAlterarCliente: false,
                          ),
                        ),
                      );
                      if (alterado == true) carregarAgendamentos();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () async {
                      await cancelarAgendamento(ag.id);
                    },
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
            _buildFiltrosCalendario(),
            const SizedBox(height: 12),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }
}
