import 'package:flutter/material.dart';

class AgendamentoState {
  final String? clienteId;
  final String? profissionalSelecionado;
  final String? servicoSelecionado;
  final DateTime? dataSelecionada;
  final String? horarioSelecionado;
  final List<dynamic> clientes;
  final List<dynamic> profissionais;
  final List<dynamic> servicos;
  final List<dynamic> especialidades;
  final List<HorarioSlot> horariosDisponiveis;

  AgendamentoState({
    this.clienteId,
    this.profissionalSelecionado,
    this.servicoSelecionado,
    this.dataSelecionada,
    this.horarioSelecionado,
    this.clientes = const [],
    this.profissionais = const [],
    this.servicos = const [],
    this.especialidades = const [],
    this.horariosDisponiveis = const [],
  });

  AgendamentoState copyWith({
    String? clienteId,
    String? profissionalSelecionado,
    String? servicoSelecionado,
    DateTime? dataSelecionada,
    String? horarioSelecionado,
    List<dynamic>? clientes,
    List<dynamic>? profissionais,
    List<dynamic>? servicos,
    List<dynamic>? especialidades,
    List<HorarioSlot>? horariosDisponiveis,
  }) {
    return AgendamentoState(
      clienteId: clienteId ?? this.clienteId,
      profissionalSelecionado: profissionalSelecionado ?? this.profissionalSelecionado,
      servicoSelecionado: servicoSelecionado ?? this.servicoSelecionado,
      dataSelecionada: dataSelecionada ?? this.dataSelecionada,
      horarioSelecionado: horarioSelecionado ?? this.horarioSelecionado,
      clientes: clientes ?? this.clientes,
      profissionais: profissionais ?? this.profissionais,
      servicos: servicos ?? this.servicos,
      especialidades: especialidades ?? this.especialidades,
      horariosDisponiveis: horariosDisponiveis ?? this.horariosDisponiveis,
    );
  }
}

class HorarioSlot {
  final String id;
  final String hora;
  final bool ocupado;
  final bool passado;

  HorarioSlot({
    required this.id,
    required this.hora,
    this.ocupado = false,
    this.passado = false,
  });
}
