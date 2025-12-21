import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart' as service;
import '../helpers/horario_helper.dart';// as helper;
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../services/cliente_service.dart';
import '../models/cliente_model.dart';
import '../models/profissional_model.dart';
import '../services/profissional_service.dart';
//import 'package:app_salao_pro/theme/tema_salao_pro.dart'; // Para HorarioTheme
import '../theme/horario_theme.dart';

class AgendamentoMovelPage extends StatefulWidget {
  final String clienteId;
  final String salaoId;
  final DateTime dataSelecionada;
  final String modoAgendamento;
  final String? agendamentoId;
  final String? profissionalId;
  final String? servicoId;
  final bool podeAlterarCliente;

  const AgendamentoMovelPage({
    required this.clienteId,
    required this.salaoId,
    required this.dataSelecionada,
    required this.modoAgendamento,
    this.agendamentoId,
    this.profissionalId,
    this.servicoId,
    super.key,
    this.podeAlterarCliente = true, // padrão: pode alterar
  });

  @override
  State<AgendamentoMovelPage> createState() => _AgendamentoMovelPageState();
}

class _AgendamentoMovelPageState extends State<AgendamentoMovelPage> {
  final ClienteService _clienteService = ClienteService();
  String? horarioSelecionado;
  String? profissionalSelecionado;
  String? especialidadeSelecionada;
  String? servicoSelecionado;
  String? clienteSelecionado;
  DateTime? dataSelecionada;
  bool _isLoading = true;
  late final String _modoAgendamento;
  final HorarioHelper helper = HorarioHelper();

  bool carregandoServicos = false;
  bool carregandoHorarios = false;
  bool buscaHorariosIniciada = false;
  bool modoEdicao = false;

  List<Map<String, dynamic>> profissionais = [];
  List<Map<String, dynamic>> especialidades = [];
  List<Map<String, dynamic>> servicos = [];
  List<Map<String, dynamic>> horariosDisponiveis = [];
  List<Map<String, dynamic>> clientes = [];

  late service.AgendamentoService agendamentoService;
  late ProfissionalService _profissionalService;

  @override
  void initState() {
    super.initState();
    _profissionalService = ProfissionalService();
    _modoAgendamento = widget.modoAgendamento.toLowerCase().trim();
    modoEdicao = widget.agendamentoId != null;
    dataSelecionada = widget.dataSelecionada;
    agendamentoService = service.AgendamentoService(widget.salaoId);
    if (widget.agendamentoId == null) {
      clienteSelecionado = widget.clienteId;
    }
    carregarDadosIniciais();
  }

  Future<void> carregarDadosIniciais() async {
    final supabase = Supabase.instance.client;

    List<Map<String, dynamic>> especs = [];
    List<Map<String, dynamic>> profsEspecs = [];

    try {
      final clientesResponse = await supabase
          .from('clientes')
          .select()
          .eq('salao_id', widget.salaoId);
      clientes = List<Map<String, dynamic>>.from(clientesResponse);
      clientes.sort((a, b) =>
          (a['nome'] as String).toLowerCase().compareTo((b['nome'] as String).toLowerCase()));

      if (_modoAgendamento == 'por_servico') {
        final especialidadesResponse = await supabase
            .from('especialidades')
            .select()
            .eq('salao_id', widget.salaoId)
            .order('nome');
        especs = List<Map<String, dynamic>>.from(especialidadesResponse);
        especs.sort((a, b) =>
            (a['nome'] as String).toLowerCase().compareTo((b['nome'] as String).toLowerCase()));
      }

      if (_modoAgendamento == 'por_profissional') {
        final profs = await supabase
            .from('profissionais')
            .select()
            .eq('salao_id', widget.salaoId)
            .order('nome');
        profsEspecs = List<Map<String, dynamic>>.from(profs);
        profsEspecs.sort((a, b) =>
            (a['nome'] as String).toLowerCase().compareTo((b['nome'] as String).toLowerCase()));

        final especialidadeIds = profsEspecs
            .map((p) => p['especialidade_id'])
            .where((id) => id != null)
            .toSet()
            .toList();

        if (especialidadeIds.isNotEmpty) {
          final especialidadesResponse = await supabase
              .from('especialidades')
              .select()
              .in_('id', especialidadeIds)
              .order('nome');
          especs = List<Map<String, dynamic>>.from(especialidadesResponse);
          especs.sort((a, b) =>
              (a['nome'] as String).toLowerCase().compareTo((b['nome'] as String).toLowerCase()));
        }
      }

      if (widget.agendamentoId != null) {
        final agendamentoResponse = await supabase
            .from('agendamentos')
            .select()
            .eq('id', widget.agendamentoId!)
            .single();

        clienteSelecionado = agendamentoResponse['cliente_id'];
        servicoSelecionado = agendamentoResponse['servico_id'];
        final dataAgendada = DateTime.tryParse(agendamentoResponse['data']);
        if (dataAgendada != null) dataSelecionada = dataAgendada;

        if (_modoAgendamento == 'por_servico' && servicoSelecionado != null) {
          final servicoResponse = await supabase
              .from('servicos')
              .select('especialidade_id')
              .eq('id', servicoSelecionado!)
              .single();
          especialidadeSelecionada = servicoResponse['especialidade_id'];
          if (especialidadeSelecionada != null) {
            await carregarServicosDaEspecialidade(especialidadeSelecionada!);
          }
        }

        if (_modoAgendamento == 'por_profissional') {
          profissionalSelecionado = agendamentoResponse['profissional_id'];
          final profissional = profsEspecs.firstWhere(
            (p) => p['id'] == profissionalSelecionado,
            orElse: () => {},
          );
          final especialidadeId = profissional['especialidade_id'];
          if (especialidadeId != null) {
            especialidadeSelecionada = especialidadeId;
            await carregarServicosDaEspecialidade(especialidadeId);
          }
        }

        await carregarHorarios();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}')),
      );
    } finally {
      setState(() {
        especialidades = especs;
        if (_modoAgendamento == 'por_profissional') {
          profissionais = profsEspecs;
        }
        if (widget.agendamentoId == null) {
          servicos = [];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> carregarEspecialidadesDoProfissional(String profissionalId) async {
    final profissional = profissionais.firstWhere(
      (p) => p['id'] == profissionalId,
      orElse: () => {},
    );
    final especialidadeId = profissional['especialidade_id'];

    setState(() {
      especialidadeSelecionada = null;
      servicos = [];
      servicoSelecionado = null;
      horariosDisponiveis = [];
    });

    if (especialidadeId == null) return;

    final especResponse = await Supabase.instance.client
        .from('especialidades')
        .select()
        .eq('id', especialidadeId)
        .single();

    final espec = especResponse;

    setState(() {
      especialidades = [espec];
      especialidadeSelecionada = especialidadeId;
    });

    await carregarServicosDaEspecialidade(especialidadeId);
  }

  Future<void> carregarServicosDaEspecialidade(String especialidadeId) async {
    final servs = await Supabase.instance.client
        .from('servicos')
        .select()
        .eq('especialidade_id', especialidadeId)
        .eq('salao_id', widget.salaoId)
        .order('nome');

    final listaServicos = List<Map<String, dynamic>>.from(servs);
    listaServicos.sort((a, b) =>
        (a['nome'] as String).toLowerCase().compareTo((b['nome'] as String).toLowerCase()));

    final idsUnicos = <String>{};
    final servicosFiltrados = listaServicos.where((s) => idsUnicos.add(s['id'])).toList();

    final idsServicos = servicosFiltrados.map((s) => s['id']).toList();
    String? novoServicoSelecionado = servicoSelecionado;

    if (servicoSelecionado != null &&
        !idsServicos.contains(servicoSelecionado)) {
      novoServicoSelecionado = null;
    }

    setState(() {
      servicos = servicosFiltrados;
      servicoSelecionado = novoServicoSelecionado;
      horariosDisponiveis = [];
    });

    if (servicos.length == 1 && servicoSelecionado == null) {
      setState(() {
        servicoSelecionado = servicos.first['id'];
      });
      await carregarHorarios();
    } else if (servicoSelecionado != null) {
      await carregarHorarios();
    }
  }

  /*
  Future<void> carregarHorarios() async {
    if (servicoSelecionado == null) return;

    setState(() {
      carregandoHorarios = true;
      buscaHorariosIniciada = true;
      horariosDisponiveis = [];
      horarioSelecionado = null;
    });

    final profissionalParaBusca = _modoAgendamento == 'por_profissional'
        ? profissionalSelecionado
        : null;

    try {
      final horarios = await helper.gerarHorariosDoDia(
        data: dataSelecionada!,
        servicoId: servicoSelecionado!,
        salaoId: widget.salaoId,
        profissionalId: profissionalParaBusca,
      );

      setState(() {
        horariosDisponiveis = horarios;
      });
    } catch (e) {
      debugPrint('Erro ao carregar horários: $e');
    } finally {
      setState(() {
        carregandoHorarios = false;
      });
    }
  }
  */

  Future<void> carregarHorarios() async {
    if (servicoSelecionado == null) return;

    setState(() {
      carregandoHorarios = true;
      buscaHorariosIniciada = true;
      horariosDisponiveis = [];
      horarioSelecionado = null;
    });

    final profissionalParaBusca = _modoAgendamento == 'por_profissional'
        ? profissionalSelecionado
        : null;

    try {
      final horarios = await helper.gerarHorariosDoDia(
        data: dataSelecionada!,
        servicoId: servicoSelecionado!,
        salaoId: widget.salaoId,
        profissionalId: profissionalParaBusca,
      );

      setState(() {
        horariosDisponiveis = horarios;
      });
    } catch (e) {
      debugPrint('Erro ao carregar horários: $e');
    } finally {
      setState(() {
        carregandoHorarios = false;
      });
    }
  }

  Future<void> confirmarAgendamento() async {
    if (horarioSelecionado == null || servicoSelecionado == null || clienteSelecionado == null || dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios (Cliente, Serviço e Horário)'),
        ),
      );
      return;
    }

    if (_modoAgendamento == 'por_profissional' && profissionalSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o profissional'),
        ),
      );
      return;
    }

    final partesHora = horarioSelecionado!.split(':');
    final hora = TimeOfDay(
      hour: int.parse(partesHora[0]),
      minute: int.parse(partesHora[1]),
    );

    final conflito = await agendamentoService.existeConflito(
      data: dataSelecionada!,
      hora: hora,
      servicoId: servicoSelecionado!,
      profissionalId: profissionalSelecionado,
    );

    if (conflito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horário já ocupado. Por favor, escolha outro.'),
        ),
      );
      return;
    }

    try {
      if (widget.agendamentoId != null) {
        await agendamentoService.atualizarHorario(
          widget.agendamentoId!,
          dataSelecionada!,
          hora,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horário do agendamento atualizado com sucesso'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final profissionalIdToUse = _modoAgendamento == 'por_profissional' ? profissionalSelecionado : null;

        final agendamento = AgendamentoModel(
          id: '',
          data: dataSelecionada!,
          hora: hora,
          profissionalId: profissionalIdToUse,
          servicoId: servicoSelecionado!,
          clienteId: clienteSelecionado!,
          salaoId: widget.salaoId,
          status: 'pendente',
          createdAt: DateTime.now(),
        );

        await agendamentoService.adicionar(agendamento);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento realizado com sucesso'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      debugPrint('Erro ao confirmar agendamento: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar: ${e.toString()}'),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> mostrarFormularioNovoCliente(BuildContext context) async {
    final nomeController = TextEditingController();
    final celularController = TextEditingController();
    final emailController = TextEditingController();
    bool carregando = false;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Novo Cliente',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: celularController,
                  decoration: const InputDecoration(labelText: 'Celular *'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [MaskedInputFormatter('(00) 00000-0000')],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: Theme.of(context).textTheme.bodyMedium),
            ),
            TextButton(
              onPressed: carregando ? null : () async {
                final nome = nomeController.text.trim();
                final celular = celularController.text.trim();
                final email = emailController.text.trim();

                final cliente = ClienteModel(
                  id: '', // novo cliente
                  nome: nome,
                  celular: celular,
                  email: email,
                  salaoId: widget.salaoId,
                );

                setState(() => carregando = true);

                try {
                  await _clienteService.adicionar(cliente);

                  final novoCliente = await Supabase.instance.client
                      .from('clientes')
                      .select()
                      .eq('salao_id', widget.salaoId)
                      .eq('celular', celular)
                      .order('created_at')
                      .limit(1)
                      .single();

                  Navigator.pop(context, novoCliente);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                } finally {
                  setState(() => carregando = false);
                }
              },
              child: carregando
                  ? const CircularProgressIndicator()
                  : Text('Salvar', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> mostrarFormularioNovoProfissional(BuildContext context) async {
    final nomeController = TextEditingController();
    String? especialidadeSelecionada;

    final especialidadesResponse = await Supabase.instance.client
        .from('especialidades')
        .select('id, nome')
        .eq('salao_id', widget.salaoId)
        .order('nome');
    final listaEspecialidades = List<Map<String, dynamic>>.from(especialidadesResponse);

    bool carregando = false;
    final theme = Theme.of(context);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Novo Profissional', style: theme.textTheme.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: especialidadeSelecionada,
                  decoration: const InputDecoration(labelText: 'Especialidade *'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Selecione')),
                    ...listaEspecialidades.map((esp) =>
                        DropdownMenuItem(value: esp['id'], child: Text(esp['nome']))),
                  ],
                  onChanged: (value) => especialidadeSelecionada = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: theme.textTheme.bodyMedium),
            ),
            ElevatedButton(
              onPressed: carregando ? null : () async {
                final nome = nomeController.text.trim();
                if (nome.isEmpty || especialidadeSelecionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha todos os campos')),
                  );
                  return;
                }

                setState(() => carregando = true);

                try {
                  final profissional = ProfissionalModel(
                    id: '',
                    nome: nome,
                    especialidadeId: especialidadeSelecionada!,
                    salaoId: widget.salaoId,
                  );
                  await _profissionalService.adicionar(profissional);

                  final novoProfissional = await Supabase.instance.client
                      .from('profissionais')
                      .select()
                      .eq('salao_id', widget.salaoId)
                      .eq('nome', nome)
                      .order('created_at')
                      .limit(1)
                      .single();

                  Navigator.pop(context, novoProfissional);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao salvar profissional: $e')),
                  );
                } finally {
                  setState(() => carregando = false);
                }
              },
              child: carregando
                  ? const CircularProgressIndicator()
                  : Text('Salvar', style: theme.textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hTheme = Theme.of(context).extension<HorarioTheme>()!;
    final dataFormatada = dataSelecionada != null
        ? DateFormat('dd/MM/yyyy').format(dataSelecionada!)
        : 'Data não definida';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Agendar para $dataFormatada'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        /*
        child: ListView(
          children: [
            if (modoEdicao)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '⚠️ Apenas o horário pode ser alterado neste agendamento.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            DropdownButtonFormField<String>(
              value: clientes.any((c) => c['id'] == clienteSelecionado) ? clienteSelecionado : null,
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Selecione')),
                ...clientes.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['nome']))),
              ],
              onChanged: modoEdicao ? null : (value) async {
                setState(() => clienteSelecionado = value);
                if (widget.agendamentoId == null) {
                  profissionalSelecionado = null;
                  especialidadeSelecionada = null;
                  servicoSelecionado = null;
                  servicos = [];
                  horariosDisponiveis = [];
                }
                if (_modoAgendamento == 'por_profissional' && profissionalSelecionado != null) {
                  await carregarEspecialidadesDoProfissional(profissionalSelecionado!);
                }
              },
            ),
            if (widget.podeAlterarCliente)
              TextButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Novo Cliente'),
                onPressed: () async {
                  final novoCliente = await mostrarFormularioNovoCliente(context);
                  if (novoCliente != null) {
                    setState(() {
                      clientes.add(novoCliente);
                      clienteSelecionado = novoCliente['id'];
                    });
                  }
                },
              ),
            const SizedBox(height: 16),

            // Modo por profissional
            if (_modoAgendamento == 'por_profissional') ...[
              if (profissionais.isEmpty)
                Text(
                  '🔴 Nenhum profissional encontrado para este salão.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (profissionais.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: profissionais.any((p) => p['id'] == profissionalSelecionado) ? profissionalSelecionado : null,
                  decoration: const InputDecoration(labelText: 'Profissional'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Selecione')),
                    ...profissionais.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['nome']))),
                  ],
                  onChanged: modoEdicao ? null : (value) async {
                    setState(() => profissionalSelecionado = value);
                    if (value != null) {
                      await carregarEspecialidadesDoProfissional(value);
                    } else {
                      setState(() {
                        especialidadeSelecionada = null;
                        servicoSelecionado = null;
                        servicos = [];
                        horariosDisponiveis = [];
                      });
                    }
                  },
                ),
                ////////////////////////////////
                if (widget.podeAlterarCliente)
                  TextButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Novo Profissional'),
                    onPressed: () async {
                      final novo = await mostrarFormularioNovoProfissional(context);
                      if (novo != null) {
                        setState(() {
                          profissionais.add(novo);
                          profissionalSelecionado = novo['id'];
                        });
                        // Carrega serviços da especialidade do novo profissional
                        await carregarEspecialidadesDoProfissional(novo['id']);
                      }
                    },
                  ),
                ////////////////////////////////
              const SizedBox(height: 16),
              if (profissionalSelecionado != null && especialidades.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: especialidades.any((e) => e['id'] == especialidadeSelecionada) ? especialidadeSelecionada : null,
                  decoration: const InputDecoration(labelText: 'Especialidade (do Profissional)'),
                  items: [
                    ...especialidades.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['nome']))),
                  ],
                  onChanged: modoEdicao ? null : (value) => setState(() => especialidadeSelecionada = value),
                ),
              const SizedBox(height: 16),
            ],

            // Modo por serviço
            if (_modoAgendamento == 'por_servico') ...[
              if (especialidades.isEmpty)
                Text(
                  '🔴 Nenhuma especialidade encontrada.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (especialidades.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: especialidades.any((e) => e['id'] == especialidadeSelecionada) ? especialidadeSelecionada : null,
                  decoration: const InputDecoration(labelText: 'Especialidade'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Selecione')),
                    ...especialidades.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['nome']))),
                  ],
                  onChanged: modoEdicao ? null : (value) async {
                    setState(() {
                      especialidadeSelecionada = value;
                      servicoSelecionado = null;
                      servicos = [];
                      carregandoServicos = true;
                    });
                    if (value != null) {
                      await carregarServicosDaEspecialidade(value);
                    } else {
                      setState(() => horariosDisponiveis = []);
                    }
                    setState(() => carregandoServicos = false);
                  },
                ),
              const SizedBox(height: 16),
            ],

            // Serviço
            DropdownButtonFormField<String>(
              value: servicos.any((s) => s['id'] == servicoSelecionado) ? servicoSelecionado : null,
              decoration: const InputDecoration(labelText: 'Serviço'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Selecione')),
                ...servicos.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['nome']))),
              ],
              onChanged: (modoEdicao || especialidadeSelecionada == null || servicos.isEmpty)
                  ? null
                  : (value) async {
                      setState(() => servicoSelecionado = value);
                      await carregarHorarios();
                    },
            ),
            const SizedBox(height: 16),

            if (especialidadeSelecionada != null && servicos.isEmpty && !carregandoServicos)
              Text(
                '🔴 Nenhum serviço encontrado para a especialidade selecionada.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),

            Text(
              'Horários disponíveis:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (carregandoHorarios)
              Center(child: Text('⏳ Carregando horários disponíveis...')),

            if (buscaHorariosIniciada && !carregandoHorarios && horariosDisponiveis.isEmpty)
              Text(
                '🔴 Nenhum horário cadastrado para este serviço na data selecionada.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            if (!carregandoHorarios && horariosDisponiveis.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: horariosDisponiveis.map((h) {
                  final ocupado = h['ocupado'] as bool;
                  final hora = h['hora'] as String;
                  final selecionado = horarioSelecionado == hora;

                  return ChoiceChip(
                    label: Text(hora),
                    selected: selecionado,
                    onSelected: ocupado ? null : (selected) => setState(() => horarioSelecionado = selected ? hora : null),
                    selectedColor: Colors.green,
                    disabledColor: Colors.grey.shade300,
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: confirmarAgendamento,
              child: Text(
                widget.agendamentoId != null ? 'Atualizar Agendamento' : 'Confirmar Agendamento',
              ),
            ),
          ],
        ),
        */
        child: ListView(
          children: [
            if (modoEdicao)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '⚠️ Apenas o horário pode ser alterado neste agendamento.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            DropdownButtonFormField<String>(
              value: clientes.any((c) => c['id'] == clienteSelecionado) ? clienteSelecionado : null,
              decoration: InputDecoration(
                labelText: 'Cliente',
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Selecione')),
                ...clientes.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['nome']))),
              ],
              onChanged: modoEdicao ? null : (value) async {
                setState(() => clienteSelecionado = value);
                if (widget.agendamentoId == null) {
                  profissionalSelecionado = null;
                  especialidadeSelecionada = null;
                  servicoSelecionado = null;
                  servicos = [];
                  horariosDisponiveis = [];
                }
                if (_modoAgendamento == 'por_profissional' && profissionalSelecionado != null) {
                  await carregarEspecialidadesDoProfissional(profissionalSelecionado!);
                }
              },
            ),

            if (widget.podeAlterarCliente)
              TextButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Novo Cliente'),
                onPressed: () async {
                  final novoCliente = await mostrarFormularioNovoCliente(context);
                  if (novoCliente != null) {
                    setState(() {
                      clientes.add(novoCliente);
                      clienteSelecionado = novoCliente['id'];
                    });
                  }
                },
              ),

            const SizedBox(height: 16),

            // Modo por profissional
            if (_modoAgendamento == 'por_profissional') ...[
              if (profissionais.isEmpty)
                Text(
                  '🔴 Nenhum profissional encontrado para este salão.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (profissionais.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: profissionais.any((p) => p['id'] == profissionalSelecionado) ? profissionalSelecionado : null,
                  decoration: InputDecoration(
                    labelText: 'Profissional',
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                    focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                    enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Selecione')),
                    ...profissionais.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['nome']))),
                  ],
                  onChanged: modoEdicao ? null : (value) async {
                    setState(() => profissionalSelecionado = value);
                    if (value != null) {
                      await carregarEspecialidadesDoProfissional(value);
                    } else {
                      setState(() {
                        especialidadeSelecionada = null;
                        servicoSelecionado = null;
                        servicos = [];
                        horariosDisponiveis = [];
                      });
                    }
                  },
                ),
              if (widget.podeAlterarCliente)
                TextButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Novo Profissional'),
                  onPressed: () async {
                    final novo = await mostrarFormularioNovoProfissional(context);
                    if (novo != null) {
                      setState(() {
                        profissionais.add(novo);
                        profissionalSelecionado = novo['id'];
                      });
                      await carregarEspecialidadesDoProfissional(novo['id']);
                    }
                  },
                ),
              const SizedBox(height: 16),
              if (profissionalSelecionado != null && especialidades.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: especialidades.any((e) => e['id'] == especialidadeSelecionada) ? especialidadeSelecionada : null,
                  decoration: InputDecoration(
                    labelText: 'Especialidade (do Profissional)',
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                    focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                    enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  ),
                  items: [
                    ...especialidades.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['nome']))),
                  ],
                  onChanged: modoEdicao ? null : (value) => setState(() => especialidadeSelecionada = value),
                ),
              const SizedBox(height: 16),
            ],

            // Modo por serviço
            if (_modoAgendamento == 'por_servico') ...[
              if (especialidades.isEmpty)
                Text(
                  '🔴 Nenhuma especialidade encontrada.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (especialidades.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: especialidades.any((e) => e['id'] == especialidadeSelecionada) ? especialidadeSelecionada : null,
                  decoration: InputDecoration(
                    labelText: 'Especialidade',
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                    focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                    enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Selecione')),
                    ...especialidades.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['nome']))),
                  ],
                  onChanged: modoEdicao ? null : (value) async {
                    setState(() {
                      especialidadeSelecionada = value;
                      servicoSelecionado = null;
                      servicos = [];
                      carregandoServicos = true;
                    });
                    if (value != null) {
                      await carregarServicosDaEspecialidade(value);
                    } else {
                      setState(() => horariosDisponiveis = []);
                    }
                    setState(() => carregandoServicos = false);
                  },
                ),
              const SizedBox(height: 16),
            ],

            // Serviço
            DropdownButtonFormField<String>(
              value: servicos.any((s) => s['id'] == servicoSelecionado) ? servicoSelecionado : null,
              decoration: InputDecoration(
                labelText: 'Serviço',
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Selecione')),
                ...servicos.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['nome']))),
              ],
              onChanged: (modoEdicao || especialidadeSelecionada == null || servicos.isEmpty)
                  ? null
                  : (value) async {
                      setState(() => servicoSelecionado = value);
                      await carregarHorarios();
                    },
            ),
            const SizedBox(height: 16),

            if (especialidadeSelecionada != null && servicos.isEmpty && !carregandoServicos)
              Text(
                '🔴 Nenhum serviço encontrado para a especialidade selecionada.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),

            Text(
              'Horários disponíveis:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (carregandoHorarios)
              Center(child: Text('⏳ Carregando horários disponíveis...')),

            if (buscaHorariosIniciada && !carregandoHorarios && horariosDisponiveis.isEmpty)
              Text(
                '🔴 Nenhum horário cadastrado para este serviço na data selecionada.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),

            if (!carregandoHorarios && horariosDisponiveis.isNotEmpty)
              /*
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: horariosDisponiveis.map((h) {
                  final ocupado = h['ocupado'] as bool;
                  final hora = h['hora'] as String;
                  final selecionado = horarioSelecionado == hora;

                  return ChoiceChip(
                    label: Text(hora, style: Theme.of(context).textTheme.bodyMedium),
                    selected: selecionado,
                    onSelected: ocupado ? null : (selected) => setState(() => horarioSelecionado = selected ? hora : null),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    disabledColor: Theme.of(context).disabledColor,
                    backgroundColor: Theme.of(context).cardTheme.color,
                  );
                }).toList(),
              ),
              */
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: horariosDisponiveis.map((h) {
                  final ocupado = h['ocupado'] as bool;
                  final hora = h['hora'] as String;
                  final selecionado = horarioSelecionado == hora;
                  final passado = h['passado'] as bool? ?? false;

                  Color background;
                  Color textColor;

                  if (selecionado) {
                    background = hTheme.selecionadoBackground;
                    textColor = hTheme.selecionadoText;
                  } else if (ocupado) {
                    background = hTheme.ocupadoBackground;
                    textColor = hTheme.ocupadoText;
                  } else if (passado) {
                    background = hTheme.passadoBackground;
                    textColor = hTheme.passadoText;
                  } else {
                    background = hTheme.livreBackground;
                    textColor = hTheme.livreText;
                  }

                  return ChoiceChip(
                    label: Text(hora, style: TextStyle(color: textColor)),
                    selected: selecionado,
                    onSelected: (ocupado || passado)
                        ? null
                        : (selected) => setState(() => horarioSelecionado = selected ? hora : null),
                    selectedColor: hTheme.selecionadoBackground,
                    backgroundColor: background,
                    disabledColor: background,
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: confirmarAgendamento,
              child: Text(
                widget.agendamentoId != null ? 'Atualizar Agendamento' : 'Confirmar Agendamento',
              ),
            ),
          ],
        ),

      ),
    );
  }
}
