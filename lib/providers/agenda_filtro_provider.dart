import 'package:flutter_riverpod/flutter_riverpod.dart';

final agendaFiltroProvider =
    StateProvider<AgendaFiltroState>((ref) {
  return AgendaFiltroState();
});

class AgendaFiltroState {
  final String? profissionalId;
  final String? servicoId;

  AgendaFiltroState({
    this.profissionalId,
    this.servicoId,
  });

  AgendaFiltroState copyWith({
    String? profissionalId,
    String? servicoId,
  }) {
    return AgendaFiltroState(
      profissionalId: profissionalId ?? this.profissionalId,
      servicoId: servicoId ?? this.servicoId,
    );
  }
}
