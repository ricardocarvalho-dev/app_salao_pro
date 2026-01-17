// horario_helper.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HorarioHelper {
  final SupabaseClient _db = Supabase.instance.client;

  /// Método principal
  Future<List<Map<String, dynamic>>> gerarHorariosDoDia({
    required DateTime data,
    required String servicoId,
    required String salaoId,
    String? profissionalId,
  }) async {
    final diaSemanaInt = data.weekday % 7; // 1–7 → 0–6

    // 1. Buscar duração do serviço
    final duracao = await _buscarDuracaoServico(servicoId);

    // 2. Buscar faixa de horário ativa
    final faixa = await _buscarFaixaHorario(
      servicoId: servicoId,
      diaSemanaInt: diaSemanaInt,
    );

    if (faixa["ativo"] != true) return [];

    final inicio = _parseHora(data, faixa['horario_inicio']);
    final fim = _parseHora(data, faixa['horario_fim']);

    // 3. Buscar horários ocupados
    final horasOcupadas = await _buscarHorasOcupadas(
      data: data,
      servicoId: servicoId,
      salaoId: salaoId,
      profissionalId: profissionalId,
    );

    // 4. Gerar slots
    return _gerarSlots(
      inicio: inicio,
      fim: fim,
      duracao: duracao,
      horasOcupadas: horasOcupadas,
    );
  }

  /// Busca duração do serviço
  Future<int> _buscarDuracaoServico(String servicoId) async {
    final res = await _db
        .from('servicos')
        .select('duracao_minutos')
        .eq('id', servicoId)
        .maybeSingle();

    if (res == null) throw Exception("Serviço não encontrado");
    return res['duracao_minutos'] as int;
  }

  /// Busca faixa de horário ativa
  Future<Map<String, dynamic>> _buscarFaixaHorario({
    required String servicoId,
    required int diaSemanaInt,
  }) async {
    final res = await _db
        .from('horarios_servicos')
        .select('horario_inicio, horario_fim, ativo')
        .eq('servico_id', servicoId)
        .eq('dia_semana', diaSemanaInt)
        .maybeSingle();

    if (res == null) throw Exception("Horário não configurado para este dia");
    return res;
  }

  /// Converte "HH:mm:ss" para DateTime
  DateTime _parseHora(DateTime data, String horaStr) {
    final p = horaStr.split(':').map(int.parse).toList();
    return DateTime(data.year, data.month, data.day, p[0], p[1]);
  }

  /// Busca horários ocupados
  Future<Set<String>> _buscarHorasOcupadas({
    required DateTime data,
    required String servicoId,
    required String salaoId,
    String? profissionalId,
  }) async {
    final dataFormatada = DateFormat('yyyy-MM-dd').format(data);

    var query = _db
        .from('agendamentos')
        .select('hora')
        .eq('salao_id', salaoId)
        .eq('data', dataFormatada)
        .eq('servico_id', servicoId);

    if (profissionalId != null) {
      query = query.eq('profissional_id', profissionalId);
    }

    final res = await query;
    final set = <String>{};

    if (res is List) {
      for (final item in res) {
        final horaOriginal = item['hora'] as String;
        final dt = DateFormat(horaOriginal.length == 8 ? 'HH:mm:ss' : 'HH:mm').parse(horaOriginal);
        final horaFormatada = DateFormat('HH:mm').format(dt);
        set.add(horaFormatada);
      }
    }

    return set;
  }

  /// Gera slots com marcação de ocupado/passado
  List<Map<String, dynamic>> _gerarSlots({
    required DateTime inicio,
    required DateTime fim,
    required int duracao,
    required Set<String> horasOcupadas,
  }) {
    final List<Map<String, dynamic>> horarios = [];
    var horaAtual = inicio;

    final agora = DateTime.now();
    final ehHoje = inicio.year == agora.year &&
        inicio.month == agora.month &&
        inicio.day == agora.day;

    while (horaAtual.add(Duration(minutes: duracao)).isBefore(fim) ||
        horaAtual.add(Duration(minutes: duracao)).isAtSameMomentAs(fim)) {
      
      final horaStr = DateFormat('HH:mm').format(horaAtual);
      final ocupadoReal = horasOcupadas.contains(horaStr);
      final ehPassado = ehHoje && horaAtual.isBefore(agora);

      horarios.add({
        "hora": horaStr,
        "ocupado": ocupadoReal,
        "passado": ehPassado,
      });

      horaAtual = horaAtual.add(Duration(minutes: duracao));
    }

    return horarios;
  }
}