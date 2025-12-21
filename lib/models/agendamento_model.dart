import 'package:flutter/material.dart';

class AgendamentoModel {
  final String id;
  final String clienteId;
  final String? profissionalId;
  final String servicoId;
  final DateTime data;
  final TimeOfDay hora;
  final String status;
  final DateTime createdAt;
  final String salaoId;

  AgendamentoModel({
    required this.id,
    required this.clienteId,
    required this.profissionalId,
    required this.servicoId,
    required this.data,
    required this.hora,
    required this.status,
    required this.createdAt,
    required this.salaoId,
  });

  factory AgendamentoModel.fromMap(Map<String, dynamic> map) {
    final horaStr = map['hora'] as String? ?? '00:00';
    final horaParts = horaStr.split(':');

    return AgendamentoModel(
      id: map['id'] as String,
      //clienteId: map['cliente_id'] as String,
      clienteId: map['cliente_id']?.toString() ?? '',
      profissionalId: map['profissional_id'] as String?,
      servicoId: map['servico_id'] as String,
      data: DateTime.parse(map['data']).toLocal(),
      hora: TimeOfDay(
        hour: int.tryParse(horaParts[0]) ?? 0,
        minute: int.tryParse(horaParts[1]) ?? 0,
      ),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      salaoId: map['salao_id'] as String,
    );
  }

  static AgendamentoModel? fromMapSafe(Map<String, dynamic> map) {
    try {
      if (map['id'] == null || map['data'] == null || map['hora'] == null) return null;
      return AgendamentoModel.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    final map = {
      'cliente_id': clienteId,
      'profissional_id': profissionalId,
      'servico_id': servicoId,
      'data': data.toIso8601String().substring(0, 10),
      'hora': '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'salao_id': salaoId,
    };
    if (id.isNotEmpty && id != 'novo') {
      map['id'] = id;
    }
    return map;
  }

  AgendamentoModel copyWith({
    String? id,
    String? clienteId,
    String? profissionalId,
    String? servicoId,
    DateTime? data,
    TimeOfDay? hora,
    String? status,
    DateTime? createdAt,
    String? salaoId,
  }) {
    return AgendamentoModel(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      profissionalId: profissionalId ?? this.profissionalId,
      servicoId: servicoId ?? this.servicoId,
      data: data ?? this.data,
      hora: hora ?? this.hora,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      salaoId: salaoId ?? this.salaoId,
    );
  }
}
