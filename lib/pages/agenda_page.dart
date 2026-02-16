import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_salao_pro/models/agendamento_model.dart';
import 'package:app_salao_pro/services/agendamento_service.dart';
import 'package:app_salao_pro/pages/agendamento_movel.dart';
import 'package:app_salao_pro/providers/agendamento_provider.dart';
import 'package:app_salao_pro/providers/agenda_filtro_provider.dart';
import 'package:app_salao_pro/pages/agenda_skeleton.dart';


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

  bool isLoading = false; // 🔹 adiciona aqui

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

  /*
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
  */
  Future<void> carregarAgendamentos() async {
    if (_selectedDay == null) return;

    final filtros = ref.read(agendaFiltroProvider);

    setState(() => isLoading = true);

    try {
      final lista = await service.getAgendamentos(
        _selectedDay!,
        profissionalId: filtros.profissionalId,
        servicoId: filtros.servicoId,
      );

      if (mounted) {
        setState(() {
          agendamentos = lista;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar agendamentos: $e")),
      );
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
        /*
        TableCalendar(
          locale: 'pt_BR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
          
          // 🔹 1. Aumenta a altura da linha para dar espaço vertical
          rowHeight: 62, 

          // 🔹 2. Ajusta o estilo dos dias com 'height' para centralizar a fonte
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 12, 
              color: Colors.black87,
              height: 1.5, // 👈 Isso empurra o texto para baixo
            ),
            weekendStyle: TextStyle(
              fontSize: 12, 
              color: Colors.redAccent,
              height: 1.5,
            ),
          ),

          // 🔹 3. Dá mais espaço entre o mês e os dias da semana
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronPadding: EdgeInsets.zero,
            rightChevronPadding: EdgeInsets.zero,
            headerPadding: EdgeInsets.only(top: 8.0, bottom: 14.0), // 👈 Aumentamos o bottom
          ),
          enabledDayPredicate: (day) => true,
        ),        
        */

        // 🔹 Envolvemos em um SizedBox para garantir que o widget tenha espaço para crescer
        SizedBox(
          height: 140, // Altura total suficiente para header + dias + números
          child: TableCalendar(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.week,
            availableCalendarFormats: const {
              CalendarFormat.week: 'Semana',
            },
            
            // 🔹 ESTA É A CHAVE: Define a altura específica para a linha dos dias (seg, ter...)
            daysOfWeekHeight: 25, 
            
            // 🔹 Altura para a linha dos números
            rowHeight: 52,

            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 13, 
                color: Colors.black87,
                // height: 1.1 ajuda a baixar um pouco a fonte dentro do espaço
                height: 1.1, 
              ),
              weekendStyle: TextStyle(
                fontSize: 13, 
                color: Colors.redAccent,
                height: 1.1,
              ),
            ),

            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronPadding: EdgeInsets.zero,
              rightChevronPadding: EdgeInsets.zero,
              // Ajustamos o padding para não empurrar tudo para cima
              headerPadding: EdgeInsets.only(bottom: 10.0), 
            ),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              carregarAgendamentos();
            },
            enabledDayPredicate: (day) => true,
          ),
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
          initialValue: filtros.servicoId,
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
        /*
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Novo Agendamento'),
          onPressed: () async {
            if (_selectedDay == null) return;

            final hoje = DateTime.now();
            final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);
            final dataSelecionada = DateTime(
              _selectedDay!.year,
              _selectedDay!.month,
              _selectedDay!.day,
            );

            if (dataSelecionada.isBefore(dataHoje)) {
              // 🔹 Feedback visual para o usuário
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Não é possível criar agendamentos em datas passadas."),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            // 🔹 Só abre a página de agendamento se for hoje ou futuro
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
        */
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Novo Agendamento'),
          onPressed: () async {
            if (_selectedDay == null) return;

            final hoje = DateTime.now();
            final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);
            final dataSelecionada = DateTime(
              _selectedDay!.year,
              _selectedDay!.month,
              _selectedDay!.day,
            );

            if (dataSelecionada.isBefore(dataHoje)) {
              // 🔹 Feedback visual para o usuário
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Não é possível criar agendamentos em datas passadas."),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            // 🔹 Só abre a página de agendamento se for hoje ou futuro
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

  /*
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
  */
  Widget _buildLista() {
    if (isLoading) {
      return AgendaSkeleton(); // componente visual de skeleton
    }

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

        return ListTile(
          title: Text('$hora — ${ag.clienteNome ?? ''}'),
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
