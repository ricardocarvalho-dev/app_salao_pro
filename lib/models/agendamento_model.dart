import 'package:flutter/material.dart';

/// Enum para padronizar status do agendamento
enum AgendamentoStatus {
  pendente,
  confirmado,
  cancelado,
  reagendado,
}

class AgendamentoModel {
  // 🔹 Identificação
  final String id;
  final String salaoId;

  // 🔹 Data e hora
  final DateTime data;
  final TimeOfDay hora;

  // 🔹 Relacionamentos (IDs)
  final String clienteId;
  final String servicoId;
  final String? profissionalId; // null no modo por serviço

  // 🔹 Nomes (usados na listagem / JOIN)
  final String? clienteNome;
  final String? servicoNome;
  final String? profissionalNome;

  // 🔹 Status e controle
  final AgendamentoStatus status;
  final DateTime createdAt;

  AgendamentoModel({
    required this.id,
    required this.salaoId,
    required this.data,
    required this.hora,
    required this.clienteId,
    required this.servicoId,
    this.profissionalId,
    this.clienteNome,
    this.servicoNome,
    this.profissionalNome,
    required this.status,
    required this.createdAt,
  });

  /// 🔹 Usado para INSERT / UPDATE (CRUD)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'data': data.toIso8601String(),
      'hora':
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
      'servico_id': servicoId,
      'cliente_id': clienteId,
      'salao_id': salaoId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'profissional_id':
          (profissionalId != null && profissionalId!.isNotEmpty)
              ? profissionalId
              : null,
    };

    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  /// 🔹 Usado para leitura (Agenda / JOIN)
  factory AgendamentoModel.fromMap(Map<String, dynamic> map) {
    final partesHora = (map['hora'] as String).split(':');

    return AgendamentoModel(
      id: map['id']?.toString() ?? '',
      data: DateTime.tryParse(map['data'] ?? '') ?? DateTime.now(),
      hora: TimeOfDay(
        hour: int.parse(partesHora[0]),
        minute: int.parse(partesHora[1]),
      ),

      clienteId: map['cliente']?['id']?.toString() ?? '',
      servicoId: map['servico']?['id']?.toString() ?? '',
      profissionalId: map['profissional']?['id']?.toString(),

      clienteNome: map['cliente']?['nome'],
      servicoNome: map['servico']?['nome'],
      profissionalNome: map['profissional']?['nome'],

      status: _parseStatus(map['status']),
      salaoId: map['salao_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static AgendamentoStatus _parseStatus(dynamic value) {
    switch (value?.toString()) {
      case 'confirmado':
        return AgendamentoStatus.confirmado;
      case 'cancelado':
        return AgendamentoStatus.cancelado;
      case 'reagendado':
        return AgendamentoStatus.reagendado;
      default:
        return AgendamentoStatus.pendente;
    }
  }
}
