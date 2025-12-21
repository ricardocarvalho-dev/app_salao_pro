import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_salao_pro/models/agendamento_model.dart';

class AgendamentoService {
  final SupabaseClient _supabase;
  final String salaoId;

  AgendamentoService(this.salaoId) : _supabase = Supabase.instance.client;

  Future<void> adicionar(AgendamentoModel agendamento) async {
    try {
      final agendamentoMap = agendamento.toMap();
      print('📦 Enviando para Supabase: $agendamentoMap');
      await _supabase.from('agendamentos').insert(agendamentoMap);
    } catch (e) {
      print('❌ Erro ao adicionar agendamento: $e');
      throw Exception('Falha ao adicionar agendamento.');
    }
  }

  Future<void> excluir(String agendamentoId) async {
    try {
      await _supabase.from('agendamentos').delete().eq('id', agendamentoId);
    } catch (e) {
      print('❌ Erro ao excluir agendamento: $e');
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
          .eq('data', data.toIso8601String().substring(0, 10));

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
      print('❌ Erro ao buscar agendamentos: $e');
      return [];
    }
  }

  Future<bool> existeConflito({
    required DateTime data,
    required TimeOfDay hora,
    required String servicoId,
    String? profissionalId,
  }) async {
    final horaStr =
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

    try {
      var query = _supabase
          .from('agendamentos')
          .select()
          .eq('salao_id', salaoId)
          .eq('data', data.toIso8601String().substring(0, 10))
          .eq('hora', horaStr)
          .eq('servico_id', servicoId);

      if (profissionalId != null && profissionalId.isNotEmpty) {
        query = query.eq('profissional_id', profissionalId);
      }

      final response = await query.limit(1);

      return response is List && response.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar conflito de horário: $e');
      return false;
    }
  }

  Future<void> criarAgendamentoPorServico({
    required String servicoId,
    required String clienteId,
    required DateTime data,
    required TimeOfDay hora,
  }) async {
    try {
      final horaStr =
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

      final servicoResponse = await _supabase
          .from('servicos')
          .select('especialidade_id')
          .eq('id', servicoId)
          .single();

      final especialidadeId = servicoResponse.data['especialidade_id'];

      final profissionaisResponse = await _supabase
          .from('profissionais')
          .select('id')
          .eq('salao_id', salaoId)
          .eq('especialidade_id', especialidadeId);

      final profissionais = profissionaisResponse.data as List<dynamic>;

      for (final profissional in profissionais) {
        final profissionalId = profissional['id'] as String;

        final conflito = await existeConflito(
          data: data,
          hora: hora,
          servicoId: servicoId,
          profissionalId: profissionalId,
        );

        if (!conflito) {
          final novoAgendamento = AgendamentoModel(
            id: '',
            data: data,
            hora: hora,
            profissionalId: profissionalId,
            servicoId: servicoId,
            clienteId: clienteId,
            salaoId: salaoId,
            status: 'pendente',
            createdAt: DateTime.now(),
          );

          await adicionar(novoAgendamento);
          return;
        }
      }

      throw Exception('Nenhum profissional disponível nesse horário');
    } catch (e) {
      print('❌ Erro ao criar agendamento por serviço: $e');
      throw Exception('Falha ao criar agendamento por serviço.');
    }
  }

  Future<List<AgendamentoModel>> buscarPorData(DateTime data) async {
    final response = await Supabase.instance.client
      .from('agendamentos')
      .select('*, clientes(nome)')
      .eq('salao_id', salaoId)
      .eq('data', data.toIso8601String().substring(0, 10));

    return response.map((map) => AgendamentoModel.fromMap({
      ...map,
      'cliente_nome': map['clientes']?['nome'], // injeta o nome do cliente
    })).toList();
  }

  Future<void> atualizarHorario(String agendamentoId, DateTime novaData, TimeOfDay novoHorario) async {
    final supabase = Supabase.instance.client;

    final novoHorarioStr = '${novoHorario.hour.toString().padLeft(2, '0')}:${novoHorario.minute.toString().padLeft(2, '0')}';

    await supabase
        .from('agendamentos')
        .update({
          'data': novaData.toIso8601String().substring(0, 10),
          'hora': novoHorarioStr,
          'status': 'reagendado',
          //'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', agendamentoId);
  }
  
}
