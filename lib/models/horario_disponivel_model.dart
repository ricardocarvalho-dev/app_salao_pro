class HorarioDisponivelModel {
  final String id;
  final String salaoId;
  final String especialidadeId;
  final String servicoId;
  final String? profissionalId;
  final DateTime data;
  final String horario; // formato HH:mm
  final bool ocupado;
  final String? clienteId;
  final String? agendamentoId;
  final DateTime createdAt;

  HorarioDisponivelModel({
    required this.id,
    required this.salaoId,
    required this.especialidadeId,
    required this.servicoId,
    this.profissionalId,
    required this.data,
    required this.horario,
    required this.ocupado,
    this.clienteId,
    this.agendamentoId,
    required this.createdAt,
  });

  factory HorarioDisponivelModel.fromMap(Map<String, dynamic> map) {
    return HorarioDisponivelModel(
      id: map['id'],
      salaoId: map['salao_id'],
      especialidadeId: map['especialidade_id'],
      servicoId: map['servico_id'],
      profissionalId: map['profissional_id'],
      data: DateTime.parse(map['data']),
      horario: map['horario'],
      ocupado: map['ocupado'] ?? false,
      clienteId: map['cliente_id'],
      agendamentoId: map['agendamento_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'salao_id': salaoId,
      'especialidade_id': especialidadeId,
      'servico_id': servicoId,
      'profissional_id': profissionalId,
      'data': data.toIso8601String(),
      'horario': horario,
      'ocupado': ocupado,
      'cliente_id': clienteId,
      'agendamento_id': agendamentoId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
