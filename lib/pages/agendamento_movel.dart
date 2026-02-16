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
import '../widgets/cliente_modal.dart';


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

  bool carregandoDados = true;
  bool buscandoSlots = false;

  @override
  void initState() {
    super.initState();
    agendamentoService = service.AgendamentoService(widget.salaoId);

    Future.microtask(() async {
      if (!mounted) return;

      ref.invalidate(agendamentoProvider);

      // 1️⃣ PRIMEIRO carrega listas
      await _carregarDadosIniciais();

      // 2️⃣ DEPOIS aplica seleções iniciais
      await _initProvider();
    });
  }

  Future<void> _initProvider() async {
    final state = ref.read(agendamentoProvider);
    final notifier = ref.read(agendamentoProvider.notifier);

    // ✅ Sempre aplica a data selecionada
    notifier.setDataSelecionada(widget.dataSelecionada);

    if (state.clientes.isEmpty ||
        state.profissionais.isEmpty ||
        state.servicos.isEmpty) {
      debugPrint('⏳ _initProvider aguardando listas carregarem');
      return;
    }

    notifier.setHorarioSelecionado(null);
    notifier.setHorariosDisponiveis([]);
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
      
      if (!mounted) return;

      final notifier = ref.read(agendamentoProvider.notifier);
      notifier.setClientes(List<Map<String, dynamic>>.from(c));
      notifier.setProfissionais(List<Map<String, dynamic>>.from(p));
      notifier.setServicos(List<Map<String, dynamic>>.from(s));
      notifier.setEspecialidades(List<Map<String, dynamic>>.from(pe));

    } catch (e) {
      debugPrint('Erro ao carregar dados iniciais: $e');
    } finally {
      if (mounted) setState(() => carregandoDados = false);
    }
  }

  Future<void> carregarHorarios({
    String? profissionalIdForcado,
    String? servicoIdForcado,
  }) async {
    final state = ref.read(agendamentoProvider);

    final sId = servicoIdForcado ?? state.servicoSelecionado;
    final data = state.dataSelecionada;

    if (sId == null || data == null) return;

    final profissionalValido =
        profissionalIdForcado ?? state.profissionalSelecionado;

    // 🔐 REGRA D+30 (ROBUSTA)
    final dataSelecionada = DateUtils.dateOnly(data);
    final hoje = DateUtils.dateOnly(DateTime.now());
    final limite = hoje.add(const Duration(days: 30));

    final bool acimaD30 = dataSelecionada.isAfter(limite);

    if (mounted) setState(() => buscandoSlots = true);

    try {
      ref.read(agendamentoProvider.notifier).setHorariosDisponiveis([]);

      List<HorarioSlot> slots = [];

      if (acimaD30) {
        // ==========================
        // 🔵 PREVIEW (> D+30)
        // ==========================
        final preview = await agendamentoService.gerarSlotsPreview(
          servicoId: sId,
          data: dataSelecionada,
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
            .eq('data', DateFormat('yyyy-MM-dd').format(dataSelecionada))
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

          final dtSlot = DateTime(
            dataSelecionada.year,
            dataSelecionada.month,
            dataSelecionada.day,
            int.parse(partes[0]),
            int.parse(partes[1]),
          );

          return HorarioSlot(
            id: h['id'].toString(),
            hora:
                '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}',
            ocupado: h['ocupado'] == true,
            passado: dtSlot.isBefore(now),
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
    final state = ref.read(agendamentoProvider); // ou ref.watch, dependendo do caso
    //if (state.clienteId == null) { 
      //debugPrint('Erro: Nenhum cliente selecionado'); // aqui você pode mostrar um alerta para o usuário 
      //return; 
    //} 

    if (state.clienteId == null ||
        state.servicoSelecionado == null ||
        state.horarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final partes = state.horarioSelecionado!.split(':');
    final horaStr =
        '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}';

    final data = state.dataSelecionada!;
    final agora = DateTime.now();
    final limite = DateTime(agora.year, agora.month, agora.day)
        .add(const Duration(days: 30));

    final bool foraDaGrade = data.isAfter(limite);

    try {
      if (foraDaGrade) {
        // 🔥 FORA DA GRADE → RPC
        await agendamentoService.criarForaDaGrade(
          servicoId: state.servicoSelecionado!,
          profissionalId: state.profissionalSelecionado,
          data: data,
          horario: horaStr,
          clienteId: state.clienteId!,
        );
      } else {
        // 🔹 GRADE NORMAL
        final hora = TimeOfDay(
          hour: int.parse(partes[0]),
          minute: int.parse(partes[1]),
        );

        final agendamento = AgendamentoModel(
          id: '',
          data: data,
          hora: hora,
          profissionalId: state.profissionalSelecionado,
          servicoId: state.servicoSelecionado!,
          clienteId: state.clienteId!,
          salaoId: widget.salaoId,
          status: AgendamentoStatus.pendente,
          createdAt: DateTime.now(),
        );

        await agendamentoService.adicionar(
          agendamento,
          ref,
          context,
        );
      }

      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar agendamento')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agendamentoProvider);
    final hTheme = Theme.of(context).extension<HorarioTheme>()!;
    final servicosFiltrados = ref.read(agendamentoProvider.notifier).filtrarServicos(state.profissionalSelecionado);    

    // 🔎 Debug para verificar os valores antes de montar os dropdowns 
    debugPrint('Clientes: ${state.clientes}'); 
    debugPrint('ClienteId: ${state.clienteId}'); 
    debugPrint('Profissionais: ${state.profissionais}'); 
    debugPrint('ProfissionalSelecionado: ${state.profissionalSelecionado}');
  
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
            /*
            Text(
              'Data: ${DateFormat('dd/MM/yyyy').format(state.dataSelecionada!)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            */
            //////////////////////
            Text(
              state.dataSelecionada != null
                  ? 'Data: ${DateFormat('dd/MM/yyyy').format(state.dataSelecionada!)}'
                  : 'Data não selecionada',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            //////////////////////
            const SizedBox(height: 16),
            DropdownSeguro(
              labelText: 'Cliente',
              items: state.clientes,
              //value: state.clienteId,  // O valor do Dropdown deve ser o clienteId do estado
              value: state.clientes.isNotEmpty ? state.clienteId : null,
              //value: state.clientes.isNotEmpty ? state.clienteId : '', // string vazia quando não há clientes
              getId: (c) => c['id'].toString(),
              getLabel: (c) => c['nome'],
              //
              mostrarOpcaoVazia: true, 
              textoOpcaoVazia: 'Selecione um cliente',
              //
              onChanged: (v) {
                if (v != null) {
                  // Atualiza o cliente selecionado no provider
                  ref.read(agendamentoProvider.notifier).selecionarCliente(v);
                  debugPrint('Cliente selecionado no dropdown: $v');
                }
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Novo cliente'),
                onPressed: () async {
                  final clienteId = await showDialog<String>(
                    context: context,
                    builder: (context) => ClienteModal(
                      salaoId: widget.salaoId,
                    ),
                  );

                  if (clienteId == null || clienteId.isEmpty) return;
                  debugPrint('Cliente_id: $clienteId'); // Cliente criado com sucesso

                  // Recarregar clientes e atualizar o dropdown
                  final supabase = Supabase.instance.client;
                  final resp = await supabase
                      .from('clientes')
                      .select()
                      .eq('salao_id', widget.salaoId)
                      .order('nome');

                  debugPrint('Resposta da consulta Supabase: $resp'); // Verificando resposta

                  if (resp is List && resp.isNotEmpty) {
                    final listaClientes = List<Map<String, dynamic>>.from(resp);

                    final notifier = ref.read(agendamentoProvider.notifier);

                    // Verificar se o widget ainda está montado antes de tentar atualizar o estado
                    if (!mounted) {
                      debugPrint('Widget não mais montado, abortando atualização de estado.');
                      return;  // Verifica se o widget ainda está montado
                    } else {
                      debugPrint('Widget ainda está montado, continuando atualização de estado.');
                    }

                    // Atualiza a lista de clientes no estado
                    notifier.setClientes(listaClientes);

                    // Selecione automaticamente o novo cliente pelo ID
                    notifier.selecionarCliente(clienteId);

                    debugPrint('Cliente selecionado: $clienteId');
                  } else {
                    debugPrint('Erro: Nenhum cliente encontrado ou resposta inválida');
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            DropdownSeguro(
              labelText: 'Profissional (opcional)',
              mostrarOpcaoVazia: true,
              items: state.profissionais,
              //value: state.profissionalSelecionado,
              value: state.profissionais.isNotEmpty ? state.profissionalSelecionado : null,
              getId: (p) => p['id'].toString(),
              getLabel: (p) => p['nome'],
              textoOpcaoVazia: 'Selecione um profissional ou deixe em branco',
              onChanged: (v) async {
                ref.read(agendamentoProvider.notifier).selecionarProfissional(v);
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