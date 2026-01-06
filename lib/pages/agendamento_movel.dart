import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart' as service;
import '../helpers/horario_helper.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../services/cliente_service.dart';
import '../models/cliente_model.dart';
import '../models/profissional_model.dart';
import '../services/profissional_service.dart';
import '../theme/horario_theme.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class AgendamentoMovelPage extends StatefulWidget {
  final String clienteId;
  final String salaoId;
  final DateTime dataSelecionada;
  final String modoAgendamento; // 'por_profissional' ou 'por_servico'
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
    this.podeAlterarCliente = true,
  });

  @override
  State<AgendamentoMovelPage> createState() => _AgendamentoMovelPageState();
}

class _AgendamentoMovelPageState extends State<AgendamentoMovelPage> {
  final ClienteService _clienteService = ClienteService();
  final HorarioHelper helper = HorarioHelper();
  late service.AgendamentoService agendamentoService;
  late ProfissionalService _profissionalService;

  // Estado
  String? horarioSelecionadoStr;
  String? profissionalSelecionado;
  String? especialidadeSelecionada;
  String? servicoSelecionado;
  String? clienteSelecionado;
  DateTime? dataSelecionada;
  bool _isLoading = true;
  bool carregandoServicos = false;
  bool carregandoHorarios = false;
  bool buscaHorariosIniciada = false;
  bool modoEdicao = false;
  late String _modoAgendamento; // dinâmico

  // Dados
  List<Map<String, dynamic>> profissionais = [];
  List<Map<String, dynamic>> especialidades = [];
  List<Map<String, dynamic>> servicos = [];
  List<Map<String, dynamic>> horariosDisponiveis = [];
  List<Map<String, dynamic>> clientes = [];

  /// Helper para formatar hora no padrão HH:mm 
  String formatHoraString(dynamic hora) { 
    if (hora == null) return ''; final s = hora.toString().trim(); if (s.isEmpty) return ''; final partes = s.split(':'); // ["09","00","00"] 
    if (partes.length >= 2) { return '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}'; } return s; // fallback 
  }
  
  @override
  void initState() {
    super.initState();
    _profissionalService = ProfissionalService();
    _modoAgendamento = widget.modoAgendamento.toLowerCase().trim();
    modoEdicao = widget.agendamentoId != null;
    dataSelecionada = widget.dataSelecionada;
    agendamentoService = service.AgendamentoService(widget.salaoId);

    // Preseleciona cliente para novos agendamentos
    if (widget.agendamentoId == null) {
      clienteSelecionado = widget.clienteId;
    }

    // Preseleciona profissional/serviço quando vier da AgendaPage
    profissionalSelecionado = widget.profissionalId;
    servicoSelecionado = widget.servicoId;

    carregarDadosIniciais();
  }

  Future<void> carregarDadosIniciais() async {
    final supabase = Supabase.instance.client;

    try {
      // Clientes
      final clientesResponse = await supabase
          .from('clientes')
          .select()
          .eq('salao_id', widget.salaoId);
      clientes = List<Map<String, dynamic>>.from(clientesResponse)
        ..sort((a, b) => (a['nome'] as String).toLowerCase().compareTo((b['nome'] as String).toLowerCase()));

      // Profissionais do salão
      final profsResponse = await supabase
          .from('profissionais')
          .select()
          .eq('salao_id', widget.salaoId)
          .order('nome');
      profissionais = List<Map<String, dynamic>>.from(profsResponse)
        ..sort((a, b) => (a['nome'] as String).toLowerCase().compareTo((b['nome'] as String).toLowerCase()));

      // Especialidades gerais do salão
      final especialidadesResponse = await supabase
          .from('especialidades')
          .select()
          .eq('salao_id', widget.salaoId)
          .order('nome');
      especialidades = List<Map<String, dynamic>>.from(especialidadesResponse)
        ..sort((a, b) => (a['nome'] as String).toLowerCase().compareTo((b['nome'] as String).toLowerCase()));

      // Se estiver editando, carregar dados do agendamento
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

        profissionalSelecionado = agendamentoResponse['profissional_id'];

        // Seta modo de agendamento
        _modoAgendamento = (profissionalSelecionado != null && profissionalSelecionado!.isNotEmpty)
            ? 'por_profissional'
            : 'por_servico';

        // Se for por profissional, carregar especialidades vinculadas
        if (_modoAgendamento == 'por_profissional' && profissionalSelecionado != null) {
          final especsResponse = await supabase
              .from('profissional_especialidades')
              .select('especialidade_id, especialidades(nome)')
              .eq('profissional_id', profissionalSelecionado!);

          final especs = List<Map<String, dynamic>>.from(especsResponse);

          if (especs.isNotEmpty) {
            especialidades = especs.map((e) => {
              'id': e['especialidade_id'].toString(),
              'nome': e['especialidades']['nome'].toString(),
            }).toList();

            especialidadeSelecionada = especialidades.first['id'];
            await carregarServicosDaEspecialidade(especialidadeSelecionada!);
          }

          if (servicoSelecionado != null) {
            await carregarHorarios();
          }
        }

        // Se for por serviço, carregar especialidade do serviço
        if (_modoAgendamento == 'por_servico' && servicoSelecionado != null) {
          final servicoResponse = await supabase
              .from('servicos')
              .select('id, nome, especialidade_id')
              .eq('id', servicoSelecionado!)
              .single();

          especialidadeSelecionada = servicoResponse['especialidade_id'].toString();
          await carregarServicosDaEspecialidade(especialidadeSelecionada!);
        }
      }

      // Se existe profissional selecionado fora da edição, carregar especialidades dele
      if (widget.agendamentoId == null &&
          profissionalSelecionado != null &&
          profissionalSelecionado!.isNotEmpty) {
        await carregarEspecialidadesDoProfissional(profissionalSelecionado!);
      }

      // Se já existe serviço selecionado, buscar horários
      if (servicoSelecionado != null && servicoSelecionado!.isNotEmpty) {
        await carregarHorarios();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> carregarEspecialidadesDoProfissional(String profissionalId) async {
    final supabase = Supabase.instance.client;

    setState(() {
      especialidadeSelecionada = null;
      servicos = [];
      servicoSelecionado = null;
      horariosDisponiveis = [];
      horarioSelecionadoStr = null;
    });

    // Busca todas as especialidades vinculadas ao profissional
    final especsResponse = await supabase
        .from('profissional_especialidades')
        .select('especialidade_id, especialidades(nome)')
        .eq('profissional_id', profissionalId);

    final especs = List<Map<String, dynamic>>.from(especsResponse);

    if (especs.isEmpty) return;

    // Converte para lista de mapas
    final listaEspecialidades = especs.map((e) => {
      'id': e['especialidade_id'].toString(),
      'nome': e['especialidades']['nome'].toString(),
    }).toList();

    setState(() {
      especialidades = listaEspecialidades;
      especialidadeSelecionada = null;
    });

    if (especialidadeSelecionada != null) {
      await carregarServicosDaEspecialidade(especialidadeSelecionada!);
    }
  }
  
  Future<void> carregarServicosDaEspecialidade(String especialidadeId) async {
    final supabase = Supabase.instance.client;

    setState(() {
      carregandoServicos = true;
    });

    try {
      final query = supabase
          .from('servicos')
          .select()
          .eq('salao_id', widget.salaoId)
          .eq('especialidade_id', especialidadeId)
          .order('nome');

      final servs = await query;
      final listaServicos = List<Map<String, dynamic>>.from(servs)
        ..sort((a, b) => (a['nome'] as String).toLowerCase().compareTo((b['nome'] as String).toLowerCase()));

      // Remove duplicados por id (caso existam)
      final idsUnicos = <String>{};
      final servicosFiltrados = listaServicos.where((s) => idsUnicos.add(s['id'].toString())).toList();

      final idsServicos = servicosFiltrados.map((s) => s['id'].toString()).toList();
      String? novoServicoSelecionado = servicoSelecionado;

      if (servicoSelecionado != null && !idsServicos.contains(servicoSelecionado)) {
        novoServicoSelecionado = null;
      }

      setState(() {
        servicos = servicosFiltrados;
        servicoSelecionado = novoServicoSelecionado;
        horariosDisponiveis = [];
        horarioSelecionadoStr = null;
      });

      // Se há exatamente um serviço, seleciona-o automaticamente e carrega horários
      if (servicos.length == 1 && servicoSelecionado == null) {
        setState(() {
          servicoSelecionado = servicos.first['id'].toString();
        });
        await carregarHorarios();
      } else if (servicoSelecionado != null) {
        await carregarHorarios();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar serviços: ${e.toString()}')),
      );
    } finally {
      setState(() {
        carregandoServicos = false;
      });
    }
  }

  Future<void> carregarHorarios() async {
    if (servicoSelecionado == null || servicoSelecionado!.isEmpty || dataSelecionada == null) {
      setState(() {
        horariosDisponiveis = <Map<String, dynamic>>[];
        horarioSelecionadoStr = null;
      });
      return;
    }

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('horarios_disponiveis')
          .select('id, servico_id, profissional_id, data, horario, ocupado')
          .eq('servico_id', servicoSelecionado!)
          .eq('data', DateFormat('yyyy-MM-dd').format(dataSelecionada!))
          .eq('ocupado', false)
          .order('horario');

      debugPrint('Response horarios_disponiveis: $response');
      debugPrint('servico=$servicoSelecionado data=${DateFormat('yyyy-MM-dd').format(dataSelecionada!)} modo=$_modoAgendamento prof=$profissionalSelecionado');

      var horarios = List<Map<String, dynamic>>.from(response);

      if (_modoAgendamento == 'por_servico') {
        horarios = horarios.where((h) => h['profissional_id'] == null).toList();
      } else if (_modoAgendamento == 'por_profissional') {
        if (profissionalSelecionado != null && profissionalSelecionado!.isNotEmpty) {
          horarios = horarios.where((h) => h['profissional_id'] == profissionalSelecionado).toList();
        } else {
          horarios = [];
        }
      }

      setState(() {
        horariosDisponiveis = horarios.map((h) {
          final horaFmt = formatHoraString(h['horario']);
          return {
            'id': h['id'],
            'hora': horaFmt,
            'profissional_id': h['profissional_id'],
          };
        }).toList();

        horariosDisponiveis.sort((a, b) => (a['hora'] as String).compareTo(b['hora'] as String));
        horarioSelecionadoStr = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar horários: ${e.toString()}')),
      );
      setState(() {
        horariosDisponiveis = <Map<String, dynamic>>[];
        horarioSelecionadoStr = null;
      });
    }
  }
  
  Future<void> confirmarAgendamento() async {
    if (horarioSelecionadoStr == null || servicoSelecionado == null || clienteSelecionado == null || dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios (Cliente, Serviço e Horário)'),
        ),
      );
      return;
    }

    if (_modoAgendamento == 'por_profissional' && (profissionalSelecionado == null || profissionalSelecionado!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o profissional')),
      );
      return;
    }

    final partesHora = horarioSelecionadoStr!.split(':');
    final hora = TimeOfDay(
      hour: int.parse(partesHora[0]),
      minute: int.parse(partesHora[1]),
    );

    // Verifica conflito conforme o modo
    final conflito = await agendamentoService.existeConflito(
      data: dataSelecionada!,
      hora: hora,
      servicoId: servicoSelecionado!,
      profissionalId: _modoAgendamento == 'por_profissional' ? profissionalSelecionado : null,
    );

    if (conflito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário já ocupado. Por favor, escolha outro.')),
      );
      return;
    }

    try {
      if (widget.agendamentoId != null) {
        await agendamentoService.atualizarHorario(widget.agendamentoId!, dataSelecionada!, hora);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horário do agendamento atualizado com sucesso')),
        );
        Navigator.pop(context, true);
      } else {
        final profissionalIdToUse = _modoAgendamento == 'por_profissional' ? profissionalSelecionado : null;

        final agendamento = AgendamentoModel(
          id: '',
          data: dataSelecionada!,
          hora: hora,
          profissionalId: profissionalIdToUse, // por_servico => null
          servicoId: servicoSelecionado!,
          clienteId: clienteSelecionado!,
          salaoId: widget.salaoId,
          status: 'pendente',
          createdAt: DateTime.now(),
        );

        await agendamentoService.adicionar(agendamento);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento realizado com sucesso')),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      debugPrint('Erro ao confirmar agendamento: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar: ${e.toString()}')),
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
              onPressed: carregando
                  ? null
                  : () async {
                      final nome = nomeController.text.trim();
                      final celular = celularController.text.trim();
                      final email = emailController.text.trim();

                      if (nome.isEmpty || celular.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preencha os campos obrigatórios')),
                        );
                        return;
                      }

                      final cliente = ClienteModel(
                        id: '',
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

                        Navigator.pop(context, Map<String, dynamic>.from(novoCliente));
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
    List<String> especialidadesSelecionadas = [];

    final especialidadesResponse = await Supabase.instance.client
        .from('especialidades')
        .select('id, nome')
        .eq('salao_id', widget.salaoId)
        .order('nome');
    final listaEspecialidades = List<Map<String, dynamic>>.from(especialidadesResponse);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo Profissional'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome *')),
              const SizedBox(height: 12),
              MultiSelectDialogField<String>(
                items: listaEspecialidades
                    .map((esp) => MultiSelectItem<String>(esp['id'].toString(), esp['nome'].toString()))
                    .toList(),
                title: const Text("Especialidades"),
                buttonText: const Text("Selecione especialidades"),
                onConfirm: (values) => especialidadesSelecionadas = values,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeController.text.trim();
                if (nome.isEmpty || especialidadesSelecionadas.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha todos os campos')),
                  );
                  return;
                }

                final profissional = ProfissionalModel(
                  id: '',
                  nome: nome,
                  salaoId: widget.salaoId,
                  especialidadeIds: especialidadesSelecionadas,
                  modoAgendamento: 'por_profissional', // fixo aqui
                );

                try {
                  await _profissionalService.adicionar(profissional);
                  final novoProfissional = await Supabase.instance.client
                      .from('profissionais')
                      .select()
                      .eq('salao_id', widget.salaoId)
                      .eq('nome', nome)
                      .order('created_at')
                      .limit(1)
                      .single();

                  Navigator.pop(context, Map<String, dynamic>.from(novoProfissional));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao salvar profissional: $e')),
                  );
                }
              },
              child: const Text('Salvar'),
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

            // Cliente
            DropdownButtonFormField<String>(
              value: clientes.any((c) => c['id'].toString() == clienteSelecionado) ? clienteSelecionado : null,
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
                ...clientes.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['nome'].toString()))),
              ],
              onChanged: modoEdicao
                  ? null
                  : (value) async {
                      setState(() => clienteSelecionado = value);
                      // Reset básico ao trocar cliente em novo agendamento
                      if (widget.agendamentoId == null) {
                        servicoSelecionado = null;
                        especialidadeSelecionada = null;
                        horariosDisponiveis = [];
                        horarioSelecionadoStr = null;
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
                      clienteSelecionado = novoCliente['id'].toString();
                    });
                  }
                },
              ),

            const SizedBox(height: 16),

            // Profissionais — sempre visível
            DropdownButtonFormField<String>(
              value: profissionais.any((p) => p['id'].toString() == profissionalSelecionado)
                  ? profissionalSelecionado
                  : null,
              decoration: InputDecoration(
                labelText: 'Profissional (opcional — selecione para agendar por profissional)',
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Selecione')),
                ...profissionais.map(
                  (p) => DropdownMenuItem(
                    value: p['id'].toString(),
                    child: Text(p['nome'].toString()),
                  ),
                ),
              ],
              onChanged: modoEdicao
                  ? null
                  : (value) async {
                      setState(() {
                        profissionalSelecionado = value;
                        _modoAgendamento = value != null ? 'por_profissional' : 'por_servico';

                        // Reset downstream
                        especialidadeSelecionada = null;
                        servicoSelecionado = null;
                        servicos = [];
                        horariosDisponiveis = [];
                        horarioSelecionadoStr = null;
                      });

                      if (value != null) {
                        // 🔧 Carrega apenas especialidades do profissional selecionado
                        await carregarEspecialidadesDoProfissional(value);
                      } else {
                        // 🔧 Retorna às especialidades gerais do salão
                        final especResponse = await Supabase.instance.client
                            .from('especialidades')
                            .select()
                            .eq('salao_id', widget.salaoId)
                            .order('nome');

                        setState(() {
                          especialidades = List<Map<String, dynamic>>.from(especResponse);
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
                      profissionalSelecionado = novo['id'].toString();
                      _modoAgendamento = 'por_profissional';
                    });
                    await carregarEspecialidadesDoProfissional(novo['id'].toString());
                  }
                },
              ),

            const SizedBox(height: 16),

            // Especialidade (dinâmica: do profissional se houver, geral se não houver)
            DropdownButtonFormField<String>(
              value: especialidades.any((e) => e['id'].toString() == especialidadeSelecionada)
                  ? especialidadeSelecionada
                  : null,
              decoration: InputDecoration(
                labelText: 'Especialidade (do Profissional)',
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Selecione')),
                ...especialidades.map(
                  (e) => DropdownMenuItem(
                    value: e['id'].toString(),
                    child: Text(e['nome'].toString()),
                  ),
                ),
              ],
              onChanged: modoEdicao
                  ? null
                  : (value) async {
                      setState(() {
                        especialidadeSelecionada = value;
                        // 🔧 Reset explícito
                        servicoSelecionado = null;
                        servicos = [];
                        horariosDisponiveis = [];
                        horarioSelecionadoStr = null;
                      });

                      // 🔧 Só carrega serviços se houver especialidade selecionada
                      if (value != null && value.isNotEmpty) {
                        await carregarServicosDaEspecialidade(value);
                      }
                    },
            ),

            const SizedBox(height: 16),
            // Serviço
            DropdownButtonFormField<String>(
              value: servicos.any((s) => s['id'].toString() == servicoSelecionado)
                  ? servicoSelecionado
                  : null,
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
                ...servicos.map(
                  (s) => DropdownMenuItem(
                    value: s['id'].toString(),
                    child: Text(s['nome'].toString()),
                  ),
                ),
              ],
              onChanged: modoEdicao
                  ? null
                  : (value) async {
                      setState(() {
                        servicoSelecionado = value;
                        // 🔧 Reset explícito dos horários e seleção
                        horariosDisponiveis = [];
                        horarioSelecionadoStr = null;
                      });

                      // 🔧 Só carrega horários se realmente houver serviço selecionado
                      if (value != null && value.isNotEmpty) {
                        await carregarHorarios();
                      }
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

            // Horários disponíveis
            Text(
              'Horários disponíveis:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (carregandoHorarios)
              const Center(child: CircularProgressIndicator()),

            if (buscaHorariosIniciada && !carregandoHorarios && horariosDisponiveis.isEmpty)
              Text(
                '🔴 Nenhum horário cadastrado para este serviço na data selecionada.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
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
                  final selecionado = horarioSelecionadoStr == hora;
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
                        : (selected) => setState(() => horarioSelecionadoStr = selected ? hora : null),
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
