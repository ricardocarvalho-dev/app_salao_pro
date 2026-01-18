import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/agendamento_provider.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart' as service;
import '../widgets/dropdown_seguro.dart';
import '../widgets/horarios_seguro.dart';
import '../theme/horario_theme.dart';

class AgendamentoMovelPage extends ConsumerStatefulWidget {
  final String salaoId;
  final DateTime dataSelecionada;
  final String? clienteId;
  final String? profissionalId;
  final String? servicoId;
  final String modoAgendamento;

  const AgendamentoMovelPage({
    super.key,
    required this.salaoId,
    required this.dataSelecionada,
    this.clienteId,
    this.profissionalId,
    this.servicoId,
    this.modoAgendamento = 'por_servico',
  });

  @override
  ConsumerState<AgendamentoMovelPage> createState() =>
      _AgendamentoMovelPageState();
}

class _AgendamentoMovelPageState extends ConsumerState<AgendamentoMovelPage> {
  late service.AgendamentoService agendamentoService;

  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> profissionais = [];
  List<Map<String, dynamic>> especialidades = [];
  List<Map<String, dynamic>> servicos = [];

  bool carregandoDados = true;
  bool buscandoSlots = false;

  @override
  void initState() {
    super.initState();
    agendamentoService = service.AgendamentoService(widget.salaoId);

    Future.microtask(() async {
      if (mounted) {
        ref.invalidate(agendamentoProvider);
        await _initProvider(); 
        await _carregarDadosIniciais();
      }
    });
  }

  Future<void> _initProvider() async {
    final notifier = ref.read(agendamentoProvider.notifier);
    notifier.setHorarioSelecionado(null);
    notifier.setHorariosDisponiveis([]);
    notifier.setDataSelecionada(widget.dataSelecionada);
    notifier.selecionarCliente(widget.clienteId);
    notifier.selecionarProfissional(widget.profissionalId);
    notifier.selecionarServico(widget.servicoId);
  }

  Future<void> _carregarDadosIniciais() async {
    final supabase = Supabase.instance.client;
    try {
      final c = await supabase.from('clientes').select().eq('salao_id', widget.salaoId).order('nome', ascending: true);
      final p = await supabase.from('profissionais').select().eq('salao_id', widget.salaoId).order('nome', ascending: true);
      final s = await supabase.from('servicos').select().eq('salao_id', widget.salaoId).order('nome', ascending: true);
      final pe = await supabase.from('profissional_especialidades').select();

      if (mounted) {
        setState(() {
          clientes = List<Map<String, dynamic>>.from(c);
          profissionais = List<Map<String, dynamic>>.from(p);
          servicos = List<Map<String, dynamic>>.from(s);
        });

        final notifier = ref.read(agendamentoProvider.notifier);
        notifier.setClientes(List<Map<String, dynamic>>.from(c));
        notifier.setProfissionais(List<Map<String, dynamic>>.from(p));
        notifier.setServicos(List<Map<String, dynamic>>.from(s));
        notifier.setEspecialidades(List<Map<String, dynamic>>.from(pe));
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados iniciais: $e');
    } finally {
      if (mounted) setState(() => carregandoDados = false);
    }
  }

  // ✅ Função Corrigida com Parâmetros Forçados
  Future<void> carregarHorarios({
    String? profissionalIdForcado,
    String? servicoIdForcado,
  }) async {
    final state = ref.read(agendamentoProvider);

    final sId = servicoIdForcado ?? state.servicoSelecionado;
    final data = state.dataSelecionada;

    if (sId == null || data == null) return;

    // 🔐 Regra de modo de agendamento
    final profissionalValido =
        widget.modoAgendamento == 'por_profissional'
            ? (profissionalIdForcado ?? state.profissionalSelecionado)
            : null;

    final acimaD30 =
        data.isAfter(DateTime.now().add(const Duration(days: 30)));

    if (mounted) setState(() => buscandoSlots = true);

    try {
      List<HorarioSlot> slots = [];

      if (acimaD30) {
        // ==========================
        // 🔵 PREVIEW (D+30+)
        // ==========================
        final preview = await agendamentoService.gerarSlotsPreview(
          servicoId: sId,
          data: data,
          profissionalId: profissionalValido,
        );

        slots = preview.map((row) {
          return HorarioSlot(
            id: 'preview_${row['hora']}',
            hora: row['hora'],
            ocupado: row['ocupado'] == true,
            passado: row['passado'] == true,
          );
        }).toList();
      } else {
        // ==========================
        // 🟢 GRADE REAL (≤ D+30)
        // ==========================
        final supabase = Supabase.instance.client;

        var query = supabase
            .from('horarios_disponiveis')
            .select()
            .eq('servico_id', sId)
            .eq('data', DateFormat('yyyy-MM-dd').format(data))
            .eq('status', 'ativo');

        if (profissionalValido != null && profissionalValido.isNotEmpty) {
          query = query.eq('profissional_id', profissionalValido);
        } else {
          query = query.is_('profissional_id', null);
        }

        final resp = await query;
        final now = DateTime.now();

        slots = List<Map<String, dynamic>>.from(resp).map((h) {
          final partes = h['horario'].toString().split(':');

          final dt = DateTime(
            data.year,
            data.month,
            data.day,
            int.parse(partes[0]),
            int.parse(partes[1]),
          );

          return HorarioSlot(
            id: h['id'].toString(),
            hora:
                '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}',
            ocupado: h['ocupado'] == true,
            passado: dt.isBefore(now),
          );
        }).toList();
      }

      slots.sort((a, b) => a.hora.compareTo(b.hora));
      ref.read(agendamentoProvider.notifier).setHorariosDisponiveis(slots);
    } catch (e) {
      debugPrint('Erro ao carregar horários: $e');
      ref.read(agendamentoProvider.notifier).setHorariosDisponiveis([]);
    } finally {
      if (mounted) setState(() => buscandoSlots = false);
    }
  }

  Future<void> confirmarAgendamento() async {
    final state = ref.read(agendamentoProvider);
    if (state.clienteId == null ||
        state.servicoSelecionado == null ||
        state.horarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final partes = state.horarioSelecionado!.split(':');
    final hora = TimeOfDay(
      hour: int.parse(partes[0]),
      minute: int.parse(partes[1]),
    );

    final agendamento = AgendamentoModel(
      id: '',
      data: state.dataSelecionada!,
      hora: hora,
      profissionalId: state.profissionalSelecionado,
      servicoId: state.servicoSelecionado!,
      clienteId: state.clienteId!,
      salaoId: widget.salaoId,
      status: AgendamentoStatus.pendente,
      createdAt: DateTime.now(),
    );

    try {
      await agendamentoService.adicionar(
        agendamento,
        ref,        // WidgetRef do Riverpod, normalmente do ConsumerWidget ou HookConsumerWidget
        context,    // BuildContext da página atual
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agendamentoProvider);
    final hTheme = Theme.of(context).extension<HorarioTheme>()!;
    final servicosFiltrados = ref.read(agendamentoProvider.notifier).filtrarServicos(state.profissionalSelecionado);    

    if (carregandoDados) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agendamento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Data: ${DateFormat('dd/MM/yyyy').format(state.dataSelecionada!)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            DropdownSeguro(
              labelText: 'Cliente',
              items: clientes,
              value: state.clienteId,
              getId: (c) => c['id'].toString(),
              getLabel: (c) => c['nome'],
              onChanged: (v) =>
                  ref.read(agendamentoProvider.notifier).selecionarCliente(v),
            ),
            const SizedBox(height: 16),
            DropdownSeguro(
              labelText: 'Profissional (opcional)',
              mostrarOpcaoVazia: true,
              items: profissionais, 
              value: state.profissionalSelecionado,
              getId: (p) => p['id'].toString(),
              getLabel: (p) => p['nome'],
              onChanged: (v) async {
                ref.read(agendamentoProvider.notifier).selecionarProfissional(v);
                // Forçamos o ID do profissional para a consulta ser imediata
                await carregarHorarios(profissionalIdForcado: v);
              },
            ),            
            const SizedBox(height: 16),

            DropdownSeguro(
              labelText: 'Serviço',
              items: servicosFiltrados,
              value: state.servicoSelecionado,
              getId: (s) => s['id'].toString(),
              getLabel: (s) => s['nome'],
              onChanged: (v) async {
                ref.read(agendamentoProvider.notifier).selecionarServico(v);
                // Forçamos o ID do serviço para a consulta ser imediata
                await carregarHorarios(servicoIdForcado: v);
              },
            ),
            const SizedBox(height: 16),

            if (buscandoSlots)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.servicoSelecionado != null && state.horariosDisponiveis.isEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Não existem horários configurados para o dia selecionado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else          
              HorariosSeguro(
                horarios: state.horariosDisponiveis,
                selecionado: state.horarioSelecionado,
                carregando: false,
                buscaIniciada: state.horariosDisponiveis.isNotEmpty,
                theme: hTheme,
                onSelecionar: (h) =>
                    ref.read(agendamentoProvider.notifier).setHorarioSelecionado(h),
              ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: confirmarAgendamento,
              child: const Text('Confirmar Agendamento'),
            ),
          ],
        ),
      ),
    );
  }
}