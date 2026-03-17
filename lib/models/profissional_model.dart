class ProfissionalModel {
  final String id;
  final String nome;
  final String salaoId;
  final String celular; // <-- NOVO CAMPO
  List<String> especialidadeIds;
  List<String>? nomesEspecialidades;
  String modoAgendamento;

  ProfissionalModel({
    required this.id,
    required this.nome,
    required this.salaoId,
    required this.celular, // <-- ADICIONADO AQUI
    required this.especialidadeIds,
    this.nomesEspecialidades,
    this.modoAgendamento = 'por_profissional',
  });

  ProfissionalModel copyWith({
    String? id,
    String? nome,
    String? salaoId,
    String? celular, // <-- ADICIONADO AQUI
    List<String>? especialidadeIds,
    List<String>? nomesEspecialidades,
    String? modoAgendamento,
  }) {
    return ProfissionalModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      salaoId: salaoId ?? this.salaoId,
      celular: celular ?? this.celular, // <-- ADICIONADO AQUI
      especialidadeIds: especialidadeIds ?? this.especialidadeIds,
      nomesEspecialidades: nomesEspecialidades ?? this.nomesEspecialidades,
      modoAgendamento: modoAgendamento ?? this.modoAgendamento,
    );
  }

  factory ProfissionalModel.fromMap(Map<String, dynamic> map) {
    return ProfissionalModel(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      salaoId: map['salao_id']?.toString() ?? '',
      celular: map['celular']?.toString() ?? '', // <-- ADICIONADO AQUI
      especialidadeIds: (map['especialidade_ids'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      nomesEspecialidades: map['nomes_especialidades'] != null
          ? (map['nomes_especialidades'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      modoAgendamento: map['modo_agendamento']?.toString() ?? 'por_profissional',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'salao_id': salaoId,
      'celular': celular, // <-- ADICIONADO AQUI
      'modo_agendamento': modoAgendamento,
    };
  }
}