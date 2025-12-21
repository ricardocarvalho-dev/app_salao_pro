class HorarioServicoModel {
  final String id;
  final String servicoId;
  final String diaSemana;
  final String horarioInicio; // formato HH:mm
  final String horarioFim;    // formato HH:mm
  final bool ativo;
  final DateTime createdAt;

  HorarioServicoModel({
    required this.id,
    required this.servicoId,
    required this.diaSemana,
    required this.horarioInicio,
    required this.horarioFim,
    required this.ativo,
    required this.createdAt,
  });

  factory HorarioServicoModel.fromMap(Map<String, dynamic> map) {
    return HorarioServicoModel(
      id: map['id'],
      servicoId: map['servico_id'],
      diaSemana: map['dia_semana'],
      horarioInicio: map['horario_inicio'],
      horarioFim: map['horario_fim'],
      ativo: map['ativo'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'servico_id': servicoId,
      'dia_semana': diaSemana,
      'horario_inicio': horarioInicio,
      'horario_fim': horarioFim,
      'ativo': ativo,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
