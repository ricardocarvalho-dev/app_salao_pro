class EspecialidadeModel {
  final String id; // pode ser nulo na criação
  final String nome;
  final String salaoId;

  EspecialidadeModel({
    required this.id,
    required this.nome,
    required this.salaoId,
  });

  EspecialidadeModel copyWith({
    String? id,
    String? nome,
    String? salaoId,
  }) {
    return EspecialidadeModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      salaoId: salaoId ?? this.salaoId,
    );
  }

  factory EspecialidadeModel.fromMap(Map<String, dynamic> map) {
    return EspecialidadeModel(
      id: map['id']?.toString() ?? '', // garante String mesmo se vier int/uuid
      nome: map['nome'] ?? '',
      salaoId: map['salao_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'salao_id': salaoId,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }
}
