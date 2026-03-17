import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agendamento_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../agendamento/agendamento_provider.dart';

class AgendamentoService {
  final SupabaseClient _supabase;
  final String salaoId;

  AgendamentoService(this.salaoId) : _supabase = Supabase.instance.client;

  /// ======================
  /// ADICIONAR AGENDAMENTO
  /// ======================
  Future<void> adicionar(
    AgendamentoModel agendamento,
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      final map = agendamento.toMap();

      // ✅ Validações obrigatórias
      if (map['cliente_id'] == null || (map['cliente_id'] as String).isEmpty) {
        throw Exception('Cliente obrigatório para o agendamento.');
      }
      if (map['servico_id'] == null || (map['servico_id'] as String).isEmpty) {
        throw Exception('Serviço obrigatório para o agendamento.');
      }
      if (map['data'] == null || map['hora'] == null) {
        throw Exception('Data e horário são obrigatórios.');
      }

      // ✅ Defesa contra strings vazias em UUID
      for (final k in ['id', 'profissional_id', 'servico_id', 'cliente_id', 'salao_id']) {
        if (map.containsKey(k) && map[k] is String && (map[k] as String).isEmpty) {
          if (k == 'id') {
            map.remove(k); // banco gera automaticamente
          } else {
            map[k] = null;
          }
        }
      }

      // ✅ Prevenção de duplicidade (CORRETA)
      var query = _supabase
          .from('agendamentos')
          .select()
          .eq('servico_id', agendamento.servicoId)
          .eq('data', _formatDate(agendamento.data))
          .eq('hora', _formatTime(agendamento.hora));

      // 🔑 Se for modo por profissional
      if (agendamento.profissionalId != null &&
          agendamento.profissionalId!.isNotEmpty) {
        query = query.eq('profissional_id', agendamento.profissionalId);
      } 
      // 🔑 Se for modo por serviço
      else {
        query = query.is_('profissional_id', null);
      }

      final existing = await query.maybeSingle();

      if (existing != null) {
        throw Exception('Horário já ocupado.');
      }

      // ✅ Inserção
      final inserted = await _supabase
          .from('agendamentos')
          .insert(map)
          .select()
          .single();

      final agendamentoId = inserted['id'] as String;

      // ✅ Marca horário como ocupado
      await marcarHorarioComoOcupado(
        servicoId: agendamento.servicoId,
        data: agendamento.data,
        hora: agendamento.hora,
        profissionalId: agendamento.profissionalId,
        agendamentoId: agendamentoId,
        clienteId: agendamento.clienteId,
        agendamentoStatus: agendamento.status.name,
      );

      // ✅ Atualiza provider para forçar refresh
      ref.read(agendamentoProvider.notifier).resetAgendamento();

      // ✅ Fecha a página
      //if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      debugPrint('Erro ao adicionar agendamento: $e');
      rethrow;
    }
  }

  /// ======================
  /// ADICIONAR AGENDAMENTO FORA DA GRADE D+30
  /// ======================
  /*
  Future<void> criarForaDaGrade({
    required String servicoId,
    String? profissionalId,
    required DateTime data,
    required String horario,
    required String clienteId,
  }) async {
    try {
      await _supabase.rpc(
        'criar_agendamento_fora_grade_validado',
        params: {
          'p_servico_id': servicoId,
          'p_profissional_id': profissionalId,
          'p_data': _formatDate(data),
          'p_horario': horario,
          'p_cliente_id': clienteId,
          'p_usuario_id': salaoId,
        },
      );
    } catch (e) {
      debugPrint('Erro ao criar agendamento fora da grade: $e');
      rethrow;
    }
  }
  */
  Future<void> criarForaDaGrade({
    required String servicoId,
    String? profissionalId,
    required DateTime data,
    required String horario,
    required String clienteId,
  }) async {
    try {
      await _supabase.rpc(
        'criar_agendamento_fora_grade_validado',
        params: {
          'p_servico_id': servicoId,
          'p_profissional_id':
              (profissionalId != null && profissionalId.isNotEmpty)
                  ? profissionalId
                  : null,
          'p_data': _formatDate(data),
          'p_horario': horario,
          'p_cliente_id': clienteId,
          'p_usuario_id': salaoId,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          'Esse horário acabou de ser ocupado por outro agendamento.',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('Erro ao criar agendamento fora da grade: $e');
      rethrow;
    }
  }  
  
  /// ======================
  /// EXCLUIR AGENDAMENTO
  /// ======================

  Future<void> excluir(String agendamentoId, WidgetRef ref) async {
    try {
      await _supabase.rpc(
        'excluir_agendamento',
        params: {'p_agendamento_id': agendamentoId},
      );

      // Atualiza provider
      ref.read(agendamentoProvider.notifier).resetAgendamento();
    } catch (e) {
      debugPrint('Erro ao excluir agendamento: $e');
      throw Exception('Falha ao excluir agendamento.');
    }
  }

  /// ======================
  /// BUSCAR AGENDAMENTOS
  /// ======================

  Future<List<AgendamentoModel>> getAgendamentos(
    DateTime data, {
    String? profissionalId,
    String? servicoId,
  }) async {
    try {
      var query = _supabase
          .from('agendamentos')
          .select('''
            id,
            data,
            hora,
            status,
            cliente:clientes ( id, nome ),
            servico:servicos ( id, nome ),
            profissional:profissionais ( id, nome )
          ''')
          .eq('salao_id', salaoId)
          .eq('data', _formatDate(data))
          .neq('status', 'cancelado');

      if (profissionalId != null && profissionalId.isNotEmpty) {
        query = query.eq('profissional_id', profissionalId);
      }

      if (servicoId != null && servicoId.isNotEmpty) {
        query = query.eq('servico_id', servicoId);
      }

      // 🔹 Timeout de 10 segundos
      final response = await query.order('hora').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Ops, a conexão está lenta. Tente atualizar a agenda.");
        },
      );

      if (response is! List) return [];

      return response
          .map((e) => AgendamentoModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      debugPrint('Erro ao buscar agendamentos: $e');
      // 🔹 Mensagem amigável para erros genéricos
      throw Exception("Falha ao carregar agendamentos. Verifique sua conexão.");
    }
  }

  /// ======================
  /// MARCAR HORÁRIO COMO OCUPADO
  /// ======================
  Future<void> marcarHorarioComoOcupado({
    required String servicoId,
    required DateTime data,
    required TimeOfDay hora,
    required String agendamentoId,
    required String clienteId,
    required String agendamentoStatus,
    String? profissionalId,
  }) async {
    try {
      final horaStr = _formatTime(hora);

      var query = _supabase
          .from('horarios_disponiveis')
          .update({
            'ocupado': true,
            'agendamento_id': agendamentoId,
            'cliente_id': clienteId,
            'agendamento_status': agendamentoStatus,
          })
          .eq('servico_id', servicoId)
          .eq('data', _formatDate(data))
          .eq('horario', horaStr);

      if (profissionalId != null && profissionalId.isNotEmpty) {
        query = query.eq('profissional_id', profissionalId);
      } else {
        query = query.is_('profissional_id', null);
      }

      await query;
    } catch (e) {
      debugPrint('Erro ao marcar horário como ocupado: $e');
      rethrow;
    }
  }

  /// ======================
  /// HELPERS DE FORMATO
  /// ======================
  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// ======================
  /// GERAR SLOTS PREVIEW (D+30)
  /// ======================
  Future<List<Map<String, dynamic>>> gerarSlotsPreview({
    required String servicoId,
    required DateTime data,
    String? profissionalId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'gerar_slots_preview',
        params: {
          'p_salao_id': salaoId,
          'p_servico_id': servicoId,
          'p_profissional_id':
              (profissionalId != null && profissionalId.isNotEmpty)
                  ? profissionalId
                  : null,
          'p_data': _formatDate(data),
        },
      );

      if (response == null || response is! List) {
        return [];
      }

      final now = DateTime.now();

      return response.map<Map<String, dynamic>>((row) {
        final timeStr =
            (row['horario'] ?? row['hora']).toString(); // defensivo
        final partes = timeStr.split(':');

        final hora =
            '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}';

        final dtSlot = DateTime(
          data.year,
          data.month,
          data.day,
          int.parse(partes[0]),
          int.parse(partes[1]),
        );

        return {
          'hora': hora,
          'ocupado': row['ocupado'] == true,
          'passado': dtSlot.isBefore(now),
        };
      }).toList()
        ..sort((a, b) =>
            (a['hora'] as String).compareTo(b['hora'] as String));
    } catch (e) {
      debugPrint('Erro ao gerar slots preview: $e');
      return [];
    }
  }

  /// ======================
  /// // 🟢 GRADE REAL (≤ D+30)
  /// ======================
  Future<List<Map<String, dynamic>>> buscarSlotsGradeReal({
    required String servicoId,
    required DateTime data,
    String? profissionalId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'buscar_slots_grade_real',
        params: {
          'p_salao_id': salaoId,
          'p_servico_id': servicoId,
          'p_data': _formatDate(data),
          'p_profissional_id':
              (profissionalId != null && profissionalId.isNotEmpty)
                  ? profissionalId
                  : null,
        },
      );

      if (response == null || response is! List) {
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erro ao buscar slots grade real: $e');
      return [];
    }
  }

   /// ======================
  /// ADICIONAR AGENDAMENTO GRADE <=D+30 VIA SERVIÇO (RPC)
  /// ======================
  Future<void> criarGradeNormal({
    required String servicoId,
    required String clienteId,
    required DateTime data,
    required String horario,
    String? profissionalId,
  }) async {
    try {
      await _supabase.rpc(
        'criar_agendamento_grade',
        params: {
          'p_salao_id': salaoId,
          'p_servico_id': servicoId,
          'p_cliente_id': clienteId,
          'p_data': _formatDate(data),
          'p_hora': horario,
          'p_status': 'pendente',
          'p_profissional_id':
              (profissionalId != null && profissionalId.isNotEmpty)
                  ? profissionalId
                  : null,
        },
      );
    } on PostgrestException catch (e) {
      // Código 23505 = unique violation no PostgreSQL
      if (e.code == '23505') {
        throw Exception('Horário acabou de ser ocupado por outro agendamento.');
      }

      rethrow;
    } catch (e) {
      rethrow;
    }
  }

}