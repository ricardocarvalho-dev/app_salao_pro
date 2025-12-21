class ClienteModel {
  final String id;
  final String nome;
  final String celular;
  final String salaoId;
  final String email; // Novo campo

  ClienteModel({
    required this.id,
    required this.nome,
    required this.celular,
    required this.salaoId,
    this.email = '',
  });

  ClienteModel copyWith({
    String? id,
    String? nome,
    String? celular,
    String? salaoId,
    String? email,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      celular: celular ?? this.celular,
      salaoId: salaoId ?? this.salaoId,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'celular': celular,
      'salao_id': salaoId,
      if (email.isNotEmpty) 'email': email,
    };
  }

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      celular: map['celular'] ?? '',
      salaoId: map['salao_id'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
