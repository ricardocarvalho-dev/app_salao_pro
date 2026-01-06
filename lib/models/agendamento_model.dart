import 'package:flutter/material.dart';

class AgendamentoModel {
  final String id;
  final DateTime data;
  final TimeOfDay hora;
  final String? profissionalId; // pode ser null no modo por_servico
  final String servicoId;
  final String clienteId;
  final String salaoId;
  final String status;
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
      'data': data.toIso8601String().substring(0, 10),
      'hora': '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
      'servico_id': servicoId,
      'cliente_id': clienteId,
      'salao_id': salaoId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };

    // Não enviar id vazio, deixa o banco gerar
    if (id.isNotEmpty) {
      map['id'] = id;
    }

    // profissional_id pode ser null
    if (profissionalId != null && profissionalId!.isNotEmpty) {
      map['profissional_id'] = profissionalId;
    } else {
      map['profissional_id'] = null;
    }

    return map;
  }

  factory AgendamentoModel.fromMap(Map<String, dynamic> map) {
    final partesHora = (map['hora'] as String).split(':');
    final hora = TimeOfDay(
      hour: int.parse(partesHora[0]),
      minute: int.parse(partesHora[1]),
    );

    return AgendamentoModel(
      id: map['id'] ?? '',
      data: DateTime.tryParse(map['data']) ?? DateTime.now(),
      hora: hora,
      profissionalId: map['profissional_id'],
      servicoId: map['servico_id'] ?? '',
      clienteId: map['cliente_id'] ?? '',
      salaoId: map['salao_id'] ?? '',
      status: map['status'] ?? 'pendente',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
