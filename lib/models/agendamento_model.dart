import 'package:flutter/material.dart';

/// Enum para padronizar status do agendamento
enum AgendamentoStatus {
  pendente,
  confirmado,
  cancelado,
  reagendado,
}

class AgendamentoModel {
  final String id;
  final DateTime data;
  final TimeOfDay hora;
  final String? profissionalId; // pode ser null no modo por_servico
  final String servicoId;
  final String clienteId;
  final String salaoId;
  final AgendamentoStatus status;
  final DateTime createdAt;

  AgendamentoModel({
    required this.id,
    required this.data,
    required this.hora,
    this.profissionalId,
    required this.servicoId,
    required this.clienteId,
    required this.salaoId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      // ✅ Usar timestamp completo para consistência
      'data': data.toIso8601String(),
      'hora': '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
      'servico_id': servicoId,
      'cliente_id': clienteId,
      'salao_id': salaoId,
      'status': status.name, // enum convertido para string
      'created_at': createdAt.toIso8601String(),
    };

    if (id.isNotEmpty) {
      map['id'] = id;
    }

    map['profissional_id'] = (profissionalId != null && profissionalId!.isNotEmpty)
        ? profissionalId
        : null;

    return map;
  }

  factory AgendamentoModel.fromMap(Map<String, dynamic> map) {
    final partesHora = (map['hora'] as String).split(':');
    final hora = TimeOfDay(
      hour: int.parse(partesHora[0]),
      minute: int.parse(partesHora[1]),
    );

    return AgendamentoModel(
      id: map['id']?.toString() ?? '',
      // ✅ Parse de timestamp completo
      data: DateTime.tryParse(map['data'] ?? '') ?? DateTime.now(),
      hora: hora,
      profissionalId: map['profissional_id']?.toString(),
      servicoId: map['servico_id']?.toString() ?? '',
      clienteId: map['cliente_id']?.toString() ?? '',
      salaoId: map['salao_id']?.toString() ?? '',
      status: _parseStatus(map['status']),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
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