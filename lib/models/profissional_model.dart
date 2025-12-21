class ProfissionalModel {
  final String id;
  final String nome;
  final String especialidadeId;
  final String salaoId;
  String? nomeEspecialidade; // ✅ sem final para permitir atribuição

  ProfissionalModel({
    required this.id,
    required this.nome,
    required this.especialidadeId,
    required this.salaoId,
    this.nomeEspecialidade,
  });

  ProfissionalModel copyWith({
    String? id,
    String? nome,
    String? especialidadeId,
    String? salaoId,
  }) {
    return ProfissionalModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      especialidadeId: especialidadeId ?? this.especialidadeId,
      salaoId: salaoId ?? this.salaoId,
    );
  }

  factory ProfissionalModel.fromMap(Map<String, dynamic> map) {
    return ProfissionalModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      especialidadeId: map['especialidade_id'] ?? '',
      salaoId: map['salao_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'especialidade_id': especialidadeId,
      'salao_id': salaoId,
    };
  }
}
