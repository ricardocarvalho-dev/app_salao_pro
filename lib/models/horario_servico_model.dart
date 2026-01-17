class HorarioServicoModel {
  final String id;
  final String servicoId;
  final int diaSemana;
  final String horarioInicio;
  final String horarioFim;
  final bool ativo;

  HorarioServicoModel({
    required this.id,
    required this.servicoId,
    required this.diaSemana,
    required this.horarioInicio,
    required this.horarioFim,
    required this.ativo,
  });

  factory HorarioServicoModel.fromMap(Map<String, dynamic> map) {
    return HorarioServicoModel(
      id: map['id'] as String,
      servicoId: map['servico_id'] as String,
      diaSemana: map['dia_semana'] as int,
      horarioInicio: map['horario_inicio'] as String,
      horarioFim: map['horario_fim'] as String,
      ativo: map['ativo'] ?? true,
    );
  }
}
