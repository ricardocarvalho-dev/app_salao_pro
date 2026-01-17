import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'agendamento_state.dart';

class AgendamentoController extends StateNotifier<AgendamentoState> {
  AgendamentoController() : super(AgendamentoState());

  // Selecionar ou limpar cliente
  void selecionarCliente(String? clienteId) {
    state = state.copyWith(clienteId: clienteId);
  }

  // Selecionar ou limpar profissional
  void selecionarProfissional(String? profissionalId) {
    state = state.copyWith(profissionalSelecionado: profissionalId);
  }

  // Selecionar ou limpar serviço
  void selecionarServico(String? servicoId) {
    state = state.copyWith(servicoSelecionado: servicoId);
  }

  // Selecionar ou limpar data
  void setDataSelecionada(DateTime? data) {
    state = state.copyWith(dataSelecionada: data);
  }

  // Selecionar ou limpar horário
  void setHorarioSelecionado(String? horario) {
    state = state.copyWith(horarioSelecionado: horario);
  }

  // Atualizar listas de clientes, profissionais e serviços
  void setClientes(List<dynamic> clientes) {
    state = state.copyWith(clientes: clientes);
  }

  void setProfissionais(List<dynamic> profissionais) {
    state = state.copyWith(profissionais: profissionais);
  }

  void setServicos(List<dynamic> servicos) {
    state = state.copyWith(servicos: servicos);
  }

  void setEspecialidades(List<dynamic> especialidades) {
    state = state.copyWith(especialidades: especialidades);
  }

  void setHorariosDisponiveis(List<HorarioSlot> horarios) {
    state = state.copyWith(horariosDisponiveis: horarios);
  }

  // ✅ Reset completo do agendamento
  void resetAgendamento() {
    state = AgendamentoState(
      clientes: state.clientes,
      profissionais: state.profissionais,
      servicos: state.servicos,
      especialidades: state.especialidades,
    );
  }

  // Exemplo de filtro de serviços por profissional
  List<Map<String, dynamic>> filtrarServicos(String? profissionalId) {
    // Aqui você pode implementar filtragem por especialidade, se necessário
    return List<Map<String, dynamic>>.from(state.servicos);
  }
}

// Provider
final agendamentoProvider = StateNotifierProvider<AgendamentoController, AgendamentoState>(
  (ref) => AgendamentoController(),
);
