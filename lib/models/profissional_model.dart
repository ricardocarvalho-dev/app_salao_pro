class ProfissionalModel {
  final String id;
  final String nome;
  final String salaoId;

  /// Lista de IDs de especialidades vinculadas ao profissional
  List<String> especialidadeIds;

  /// Lista opcional com os nomes das especialidades (para exibição)
  List<String>? nomesEspecialidades;

  /// Define se o agendamento é por profissional ou por serviço/especialidade
  String modoAgendamento;

  ProfissionalModel({
    required this.id,
    required this.nome,
    required this.salaoId,
    required this.especialidadeIds,
    this.nomesEspecialidades,
    this.modoAgendamento = 'por_profissional', // valor padrão
  });

  ProfissionalModel copyWith({
    String? id,
    String? nome,
    String? salaoId,
    List<String>? especialidadeIds,
    List<String>? nomesEspecialidades,
    String? modoAgendamento,
  }) {
    return ProfissionalModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      salaoId: salaoId ?? this.salaoId,
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
      // ⚠️ Se já estiver usando a tabela de junção profissional_especialidades,
      // esse campo pode ser ignorado na persistência e usado apenas internamente.
      'especialidade_ids': especialidadeIds,
      'modo_agendamento': modoAgendamento,
    };
  }
}