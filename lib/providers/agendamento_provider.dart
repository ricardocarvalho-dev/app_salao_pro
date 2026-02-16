import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class HorarioSlot {
  final String id;
  final String hora; // "14:30"
  final bool ocupado;
  final bool passado;

  const HorarioSlot({
    required this.id,
    required this.hora,
    this.ocupado = false,
    this.passado = false,
  });
}

@immutable
class AgendamentoState {
  final String? clienteId;
  final String? profissionalSelecionado;
  final String? servicoSelecionado;
  final String modoAgendamento; // 'por_servico' ou 'por_profissional'
  final DateTime? dataSelecionada;
  final List<HorarioSlot> horariosDisponiveis;
  final String? horarioSelecionado;
  final String? clienteNome; // ✅ novo campo para armazenar o nome do cliente selecionado

  // Novos campos
  final List<Map<String, dynamic>> profissionais;
  final List<Map<String, dynamic>> servicos;
  final List<Map<String, dynamic>> clientes;
  final List<Map<String, dynamic>> profissionalEspecialidades; // ✅ novo campo

  final Map<String, String> mapaProfissionais;
  final Map<String, String> mapaServicos;
  final Map<String, String> mapaClientes;

  final DateTime? lastFetch; // 🔹 novo campo para controlar cache

  const AgendamentoState({
    this.clienteId,
    this.profissionalSelecionado,
    this.servicoSelecionado,
    this.modoAgendamento = 'por_servico',
    this.dataSelecionada,
    this.horariosDisponiveis = const [],
    this.horarioSelecionado,
    this.profissionais = const [],
    this.servicos = const [],
    this.clientes = const [],
    this.profissionalEspecialidades = const [], // ✅ inicializado vazio
    this.mapaProfissionais = const {},
    this.mapaServicos = const {},
    this.mapaClientes = const {},
    this.clienteNome,
    this.lastFetch,
  });

  AgendamentoState copyWith({
    String? clienteId,
    String? profissionalSelecionado,
    String? servicoSelecionado,
    String? modoAgendamento,
    DateTime? dataSelecionada,
    List<HorarioSlot>? horariosDisponiveis,
    String? horarioSelecionado,
    List<Map<String, dynamic>>? profissionais,
    List<Map<String, dynamic>>? servicos,
    List<Map<String, dynamic>>? clientes,
    List<Map<String, dynamic>>? profissionalEspecialidades, // ✅ novo
    Map<String, String>? mapaProfissionais,
    Map<String, String>? mapaServicos,
    Map<String, String>? mapaClientes,
    String? clienteNome,
    DateTime? lastFetch,
  }) {
    return AgendamentoState(
      clienteId: clienteId ?? this.clienteId,
      profissionalSelecionado: profissionalSelecionado ?? this.profissionalSelecionado,
      servicoSelecionado: servicoSelecionado ?? this.servicoSelecionado,
      modoAgendamento: modoAgendamento ?? this.modoAgendamento,
      dataSelecionada: dataSelecionada ?? this.dataSelecionada,
      horariosDisponiveis: horariosDisponiveis ?? this.horariosDisponiveis,
      horarioSelecionado: horarioSelecionado ?? this.horarioSelecionado,
      profissionais: profissionais ?? this.profissionais,
      servicos: servicos ?? this.servicos,
      clientes: clientes ?? this.clientes,
      profissionalEspecialidades: profissionalEspecialidades ?? this.profissionalEspecialidades, // ✅ novo
      mapaProfissionais: mapaProfissionais ?? this.mapaProfissionais,
      mapaServicos: mapaServicos ?? this.mapaServicos,
      mapaClientes: mapaClientes ?? this.mapaClientes,
      clienteNome: clienteNome ?? this.clienteNome,
    );
  }
}

class AgendamentoNotifier extends StateNotifier<AgendamentoState> {
  AgendamentoNotifier() : super(const AgendamentoState());

  // ======================
  // CARREGAR LISTAS DO SUPABASE
  // ======================
  Future<void> carregarFiltros(String salaoId) async {
    final supabase = Supabase.instance.client;

    final p = await supabase
        .from('profissionais')
        .select()
        .eq('salao_id', salaoId)
        .eq('modo_agendamento', 'por_profissional') // ✅ apenas profissionais válidos
        .order('nome');

    final s = await supabase
        .from('servicos')
        .select()
        .eq('salao_id', salaoId)
        .order('nome');

    final c = await supabase
        .from('clientes')
        .select()
        .eq('salao_id', salaoId)
        .order('nome');

    final pe = await supabase
        .from('profissional_especialidades')
        .select();

    final profissionais = List<Map<String, dynamic>>.from(p ?? []);
    final servicos = List<Map<String, dynamic>>.from(s ?? []);
    final clientes = List<Map<String, dynamic>>.from(c ?? []);
    final profissionalEspecialidades = List<Map<String, dynamic>>.from(pe ?? []);

    state = state.copyWith(
      profissionais: profissionais,
      servicos: servicos,
      clientes: clientes,
      profissionalEspecialidades: profissionalEspecialidades, // ✅ novo
      mapaProfissionais: {
        for (var p in profissionais) p['id'].toString(): p['nome'].toString()
      },
      mapaServicos: {
        for (var s in servicos) s['id'].toString(): s['nome'].toString()
      },
      mapaClientes: {
        for (var c in clientes) c['id'].toString(): c['nome'].toString()
      },
    );
  }

  // ======================
  // FILTRAR SERVIÇOS POR PROFISSIONAL
  // ======================
  List<Map<String, dynamic>> filtrarServicos(String? profissionalId) {
    // ✅ Se profissionalId for null ou string vazia, retorna todos os serviços
    if (profissionalId == null || profissionalId.toString().isEmpty) {
      return state.servicos;
    }

    // ✅ Forçamos .toString() em ambos os lados para garantir a comparação
    final especialidadesIds = state.profissionalEspecialidades
        .where((pe) => pe['profissional_id'].toString() == profissionalId.toString())
        .map((pe) => pe['especialidade_id'].toString())
        .toList();

    if (especialidadesIds.isEmpty) return [];

    return state.servicos
        .where((s) => especialidadesIds.contains(s['especialidade_id'].toString()))
        .toList();
  }
  // ======================
  // CLIENTE
  // ======================
  /*
  void selecionarCliente(String? clienteId) {
    state = state.copyWith(clienteId: clienteId);
  }
  */
  /*
  void selecionarCliente(String? clienteId) {
    // Criamos uma nova instância para garantir que o null seja aceito
    state = AgendamentoState(
      profissionais: state.profissionais,
      servicos: state.servicos,
      clientes: state.clientes,
      profissionalEspecialidades: state.profissionalEspecialidades,
      mapaProfissionais: state.mapaProfissionais,
      mapaServicos: state.mapaServicos,
      mapaClientes: state.mapaClientes,
      dataSelecionada: state.dataSelecionada,
      modoAgendamento: state.modoAgendamento,
      // Atribuição direta (o que permite o null)
      clienteId: clienteId, 
      profissionalSelecionado: state.profissionalSelecionado,
      servicoSelecionado: state.servicoSelecionado,
      horariosDisponiveis: state.horariosDisponiveis,
      horarioSelecionado: state.horarioSelecionado,
    );
  } 
  */
  /*
  void selecionarCliente(String? clienteId) {
    // Verifica se o clienteId é válido e existe na lista de clientes
    final clienteSelecionado = clienteId != null
        ? state.clientes.firstWhere(
            (cliente) => cliente['id'] == clienteId, 
            orElse: () => <String, dynamic>{})  // Retorna um mapa vazio se não encontrado
        : null;

    debugPrint('Cliente selecionado: $clienteId');
    // Atualiza somente o campo clienteId no estado
    state = state.copyWith(
      clienteId: clienteId,
      // Atualiza o nome do cliente, se o clienteId for válido
      clienteNome: clienteSelecionado != null && clienteSelecionado.isNotEmpty 
          ? clienteSelecionado['nome']
          : null,
    );

    debugPrint('Estado atualizado: $clienteId');
  }
  */
  void selecionarCliente(String? clienteId) {
    Map<String, dynamic>? clienteSelecionado;

    if (clienteId != null) {
      clienteSelecionado = state.clientes.firstWhere(
        (cliente) => cliente['id'].toString() == clienteId.toString(),
        orElse: () => {},
      );
    }

    debugPrint('Cliente selecionado: $clienteId');

    state = state.copyWith(
      clienteId: clienteId,
      clienteNome: clienteSelecionado != null && clienteSelecionado.isNotEmpty
          ? clienteSelecionado['nome']?.toString()
          : null,
    );

    debugPrint(
      'Estado atualizado -> clienteId: ${state.clienteId}, nome: ${state.clienteNome}',
    );
  }

  // ======================
  // PROFISSIONAL
  // ======================
  void selecionarProfissional(String? profissionalId) {
    state = AgendamentoState(
      profissionais: state.profissionais,
      servicos: state.servicos,
      clientes: state.clientes,
      profissionalEspecialidades: state.profissionalEspecialidades, // ✅ Importante manter
      mapaProfissionais: state.mapaProfissionais,
      mapaServicos: state.mapaServicos,
      mapaClientes: state.mapaClientes,
      dataSelecionada: state.dataSelecionada,
      clienteId: state.clienteId,
      profissionalSelecionado: profissionalId, // ✅ Aceita null vindo da combo
      modoAgendamento: profissionalId != null ? 'por_profissional' : 'por_servico',
      servicoSelecionado: null, // ✅ Sempre reseta o serviço ao mudar o profissional
      horariosDisponiveis: [],
      horarioSelecionado: null,
    );
  }  
  // ======================
  // SERVIÇO
  // ======================
    // Alternativa recomendada: use uma nova instância para garantir o reset
void selecionarServico(String? servicoId) {
    // Criamos um novo estado completo. Isso permite que o servicoId seja null
    // e o Flutter entenda que deve resetar o combo para "Selecionar".
    state = AgendamentoState(
      profissionais: state.profissionais,
      servicos: state.servicos,
      clientes: state.clientes,
      profissionalEspecialidades: state.profissionalEspecialidades,
      mapaProfissionais: state.mapaProfissionais,
      mapaServicos: state.mapaServicos,
      mapaClientes: state.mapaClientes,
      dataSelecionada: state.dataSelecionada,
      clienteId: state.clienteId,
      profissionalSelecionado: state.profissionalSelecionado,
      modoAgendamento: state.modoAgendamento,
      servicoSelecionado: servicoId, // Aceita null corretamente agora
      horariosDisponiveis: [],
      horarioSelecionado: null,
    );
  }
  // ======================
  // DATA
  // ======================
  void setDataSelecionada(DateTime data) {
    state = state.copyWith(
      dataSelecionada: data,
      horariosDisponiveis: [],
      horarioSelecionado: null,
    );
  }

  // ======================
  // HORÁRIO
  // ======================
  void setHorarioSelecionado(String? hora) {
    state = state.copyWith(horarioSelecionado: hora);
  }

  void setHorariosDisponiveis(List<HorarioSlot> horarios) {
    state = state.copyWith(horariosDisponiveis: horarios);
  }

  // ======================
  // RESET COMPLETO
  // ======================
  void resetAgendamento() {
    state = const AgendamentoState();
  }

  // ======================
  // SETTERS PARA LISTAS (CORRIGIDOS PARA POPULAR OS MAPAS)
  // ======================
  /*
  void setClientes(List<Map<String, dynamic>> lista) {
    state = state.copyWith(
      clientes: lista,
      mapaClientes: {
        for (var c in lista) c['id'].toString(): c['nome'].toString()
      },
    );
  }
  */
  void setClientes(List<Map<String, dynamic>> lista) {
    state = state.copyWith(
      clientes: lista,
      clienteId: lista.isNotEmpty ? state.clienteId : null, // força null se vazio
      mapaClientes: {
        for (var c in lista) c['id'].toString(): c['nome'].toString()
      },
    );
  }

  /*
  void setProfissionais(List<Map<String, dynamic>> lista) {
    state = state.copyWith(
      profissionais: lista,
      mapaProfissionais: {
        for (var p in lista) p['id'].toString(): p['nome'].toString()
      },
    );
  }
  */

  void setProfissionais(List<Map<String, dynamic>> lista) {
    state = state.copyWith(
      profissionais: lista,
      profissionalSelecionado: lista.isNotEmpty ? state.profissionalSelecionado : null, // força null se vazio
      mapaProfissionais: {
        for (var p in lista) p['id'].toString(): p['nome'].toString()
      },
    );
  }

  void setServicos(List<Map<String, dynamic>> lista) {
    state = state.copyWith(
      servicos: lista,
      mapaServicos: {
        for (var s in lista) s['id'].toString(): s['nome'].toString()
      },
    );
  }

  void setEspecialidades(List<Map<String, dynamic>> lista) {
  state = state.copyWith(profissionalEspecialidades: lista);
  }

}

final agendamentoProvider =
    StateNotifierProvider<AgendamentoNotifier, AgendamentoState>(
        (ref) => AgendamentoNotifier());