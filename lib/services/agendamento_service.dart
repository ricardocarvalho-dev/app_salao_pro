import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agendamento_model.dart';

class AgendamentoService {
  final SupabaseClient _supabase;
  final String salaoId;

  AgendamentoService(this.salaoId) : _supabase = Supabase.instance.client;

  Future<void> adicionar(AgendamentoModel agendamento) async {
    try {
      final map = agendamento.toMap();

      // Defesa extra: nunca enviar "" para colunas *_id
      for (final k in ['id', 'profissional_id', 'servico_id', 'cliente_id', 'salao_id']) {
        if (map.containsKey(k) && (map[k] is String) && (map[k] as String).isEmpty) {
          if (k == 'id') {
            map.remove(k); // deixa o banco gerar
          } else {
            map[k] = null; // uuid nulo
          }
        }
      }

      await _supabase.from('agendamentos').insert(map);
    } catch (e) {
      debugPrint('Erro ao adicionar agendamento: $e');
      throw Exception('Falha ao adicionar agendamento.');
    }
  }

  Future<void> excluir(String agendamentoId) async {
    try {
      await _supabase.from('agendamentos').delete().eq('id', agendamentoId);
    } catch (e) {
      debugPrint('Erro ao excluir agendamento: $e');
      throw Exception('Falha ao excluir agendamento.');
    }
  }

  Future<List<AgendamentoModel>> getAgendamentos(
    DateTime data, {
    String? profissionalId,
    String? servicoId,
  }) async {
    try {
      var query = _supabase
          .from('agendamentos')
          .select()
          .eq('salao_id', salaoId)
          .eq('data', _formatDate(data));

      if (profissionalId != null && profissionalId.isNotEmpty) {
        query = query.eq('profissional_id', profissionalId);
      }

      if (servicoId != null && servicoId.isNotEmpty) {
        query = query.eq('servico_id', servicoId);
      }

      final response = await query.order('hora');

      if (response == null || response is! List) return [];

      return response
          .map((map) => AgendamentoModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erro ao buscar agendamentos: $e');
      return [];
    }
  }

  Future<bool> existeConflito({
    required DateTime data,
    required TimeOfDay hora,
    required String servicoId,
    String? profissionalId,
  }) async {
    final horaStr = _formatTime(hora);

    try {
      var query = _supabase
          .from('agendamentos')
          .select()
          .eq('salao_id', salaoId)
          .eq('data', _formatDate(data))
          .eq('hora', horaStr)
          .eq('servico_id', servicoId);

      if (profissionalId != null && profissionalId.isNotEmpty) {
        query = query.eq('profissional_id', profissionalId);
      }

      final response = await query.limit(1);
      return response is List && response.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao verificar conflito de horário: $e');
      return false;
    }
  }

  Future<void> atualizarHorario(
    String agendamentoId,
    DateTime novaData,
    TimeOfDay novoHorario,
  ) async {
    try {
      await _supabase
          .from('agendamentos')
          .update({
            'data': _formatDate(novaData),
            'hora': _formatTime(novoHorario),
            'status': 'reagendado',
          })
          .eq('id', agendamentoId);
    } catch (e) {
      debugPrint('Erro ao atualizar horário: $e');
      throw Exception('Falha ao atualizar horário.');
    }
  }

  String _formatDate(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
