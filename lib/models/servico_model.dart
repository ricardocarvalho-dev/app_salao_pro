class ServicoModel {
  final String id;
  final String nome;
  final String? descricao;
  final double preco;
  final int duracaoMinutos;
  final String salaoId;
  final String? especialidadeId;
  final DateTime? createdAt;
  final String? nomeEspecialidade;

  ServicoModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.preco,
    required this.duracaoMinutos,
    required this.salaoId,
    this.especialidadeId,
    this.createdAt,
    this.nomeEspecialidade, // precisa estar no construtor
  });

  ServicoModel copyWith({
    String? id,
    String? nome,
    String? descricao,
    double? preco,
    int? duracaoMinutos,
    String? salaoId,
    String? especialidadeId,
    DateTime? createdAt,
    String? nomeEspecialidade, // ✅ novo campo
  }) {
    return ServicoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      salaoId: salaoId ?? this.salaoId,
      especialidadeId: especialidadeId ?? this.especialidadeId,
      createdAt: createdAt ?? this.createdAt,
      nomeEspecialidade: nomeEspecialidade ?? this.nomeEspecialidade, // ✅ novo campo
    );
  }

  factory ServicoModel.fromMap(Map<String, dynamic> map) {
    return ServicoModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      preco: (map['preco'] ?? 0).toDouble(),
      duracaoMinutos: map['duracao_minutos'] ?? 0,
      salaoId: map['salao_id'] ?? '',
      especialidadeId: map['especialidade_id'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      nomeEspecialidade: map['especialidades']?['nome'], // ✅ corrigido aqui
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'duracao_minutos': duracaoMinutos,
      'salao_id': salaoId,
      'especialidade_id': especialidadeId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
