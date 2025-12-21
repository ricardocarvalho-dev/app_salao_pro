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
    
    final diaSemanaTexto = _diaSemana(data.weekday);

    // 1. Buscar duração do serviço
    final duracao = await _buscarDuracaoServico(servicoId);

    // 2. Buscar horário + ativo
    final faixa = await _buscarFaixaHorario(
      servicoId: servicoId,
      diaSemana: diaSemanaTexto,
    );

    // Se o serviço não atende neste dia
    if (faixa["ativo"] != true) return [];

    final inicio = _parseHora(data, faixa['horario_inicio']);
    final fim = _parseHora(data, faixa['horario_fim']);

    // 3. Buscar todos os agendamentos já ocupados
    final horasOcupadas = await _buscarHorasOcupadas(
      data: data,
      servicoId: servicoId,
      salaoId: salaoId,
      profissionalId: profissionalId,
    );

    // 4. Gerar horários
    return _gerarSlots(
      inicio: inicio,
      fim: fim,
      duracao: duracao,
      horasOcupadas: horasOcupadas,
    );
  }

  // ======================================================
  // MÉTODOS PRIVADOS (organização interna)
  // ======================================================

  /// Converte weekday numérico para texto igual ao banco
  String _diaSemana(int weekday) {
    const dias = {
      1: "Segunda",
      2: "Terça",
      3: "Quarta",
      4: "Quinta",
      5: "Sexta",
      6: "Sábado",
      7: "Domingo",
    };
    return dias[weekday]!;
  }

  /// Busca a duração do serviço
  Future<int> _buscarDuracaoServico(String servicoId) async {
    final res = await _db
        .from('servicos')
        .select('duracao_minutos')
        .eq('id', servicoId)
        .maybeSingle();

    if (res == null) {
      throw Exception("Serviço não encontrado");
    }

    return res['duracao_minutos'] as int;
  }

  /// Busca horário_inicio, horário_fim e ativo
  Future<Map<String, dynamic>> _buscarFaixaHorario({
    required String servicoId,
    required String diaSemana,
  }) async {
    final res = await _db
        .from('horarios_servicos')
        .select('horario_inicio, horario_fim, ativo')
        .eq('servico_id', servicoId)
        .eq('dia_semana', diaSemana)
        .maybeSingle();

    if (res == null) {
      throw Exception("Configuração de horário não encontrada para este dia");
    }

    return res;
  }

  /// Converte "HH:mm:ss" para DateTime
  DateTime _parseHora(DateTime data, String horaStr) {
    final p = horaStr.split(':').map(int.parse).toList();
    return DateTime(data.year, data.month, data.day, p[0], p[1]);
  }

  /*
  /// Busca todas as horas já ocupadas de uma vez só
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
        set.add(item['hora']);
      }
    }

    return set;
  }
  */

  /// Busca todas as horas já ocupadas de uma vez só
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

        // Normalizar HH:mm ou HH:mm:ss para HH:mm
        DateTime dt;
        if (horaOriginal.length == 8) {
          // Formato HH:mm:ss
          dt = DateFormat('HH:mm:ss').parse(horaOriginal);
        } else {
          // Formato HH:mm
          dt = DateFormat('HH:mm').parse(horaOriginal);
        }

        final horaFormatada = DateFormat('HH:mm').format(dt);
        set.add(horaFormatada);
      }
    }

    return set;
  }

  /// Gera lista de horários e marca como ocupado ou livre
  /*
  List<Map<String, dynamic>> _gerarSlots({
    required DateTime inicio,
    required DateTime fim,
    required int duracao,
    required Set<String> horasOcupadas,
  }) {
    final List<Map<String, dynamic>> horarios = [];
    var horaAtual = inicio;

    final agora = DateTime.now();
    final ehHoje =
        inicio.year == agora.year &&
        inicio.month == agora.month &&
        inicio.day == agora.day;

    while (horaAtual.add(Duration(minutes: duracao)).isBefore(fim) ||
        horaAtual.add(Duration(minutes: duracao)).isAtSameMomentAs(fim)) {

      final horaStr = DateFormat('HH:mm').format(horaAtual);

      bool ocupado = horasOcupadas.contains(horaStr);

      // 🔥 Bloquear horários já passados NO DIA ATUAL
      if (ehHoje && horaAtual.isBefore(agora)) {
        ocupado = true;
      }

      horarios.add({
        "hora": horaStr,
        "ocupado": ocupado,
      });

      horaAtual = horaAtual.add(Duration(minutes: duracao));
    }

    return horarios;
  }
  */
  List<Map<String, dynamic>> _gerarSlots({
    required DateTime inicio,
    required DateTime fim,
    required int duracao,
    required Set<String> horasOcupadas,
  }) {
    final List<Map<String, dynamic>> horarios = [];
    var horaAtual = inicio;

    final agora = DateTime.now();
    final ehHoje =
        inicio.year == agora.year &&
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
