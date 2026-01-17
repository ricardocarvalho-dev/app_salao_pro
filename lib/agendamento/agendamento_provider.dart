import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'agendamento_controller.dart';
import 'agendamento_state.dart';

final agendamentoProvider =
    StateNotifierProvider<AgendamentoController, AgendamentoState>(
  (ref) => AgendamentoController(),
);
