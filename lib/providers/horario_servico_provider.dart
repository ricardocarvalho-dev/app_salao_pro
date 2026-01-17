import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/horario_servico_model.dart';
import '../services/horario_servico_service.dart';

final horarioServicoProvider = StateNotifierProvider<
    HorarioServicoNotifier, AsyncValue<List<HorarioServicoModel>>>(
  (ref) => HorarioServicoNotifier(),
);

class HorarioServicoNotifier
    extends StateNotifier<AsyncValue<List<HorarioServicoModel>>> {
  HorarioServicoNotifier() : super(const AsyncLoading());

  final HorarioServicoService _service = HorarioServicoService();

  Future<void> carregarHorarios(String servicoId) async {
    try {
      state = const AsyncLoading();
      final lista = await _service.listarPorServico(servicoId);
      state = AsyncData(lista);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> adicionarHorario(HorarioServicoModel horario) async {
    await _service.adicionar(horario);
    await carregarHorarios(horario.servicoId);
  }

  Future<void> atualizarHorario(HorarioServicoModel horario) async {
    await _service.atualizar(horario);
    await carregarHorarios(horario.servicoId);
  }

  Future<void> excluirHorario(HorarioServicoModel horario) async {
    await _service.excluir(horario.id);
    await carregarHorarios(horario.servicoId);
  }

  Future<void> atualizarStatus(HorarioServicoModel horario, bool ativo) async {
    await _service.atualizarStatus(horario.id, ativo);
    await carregarHorarios(horario.servicoId);
  }
}
