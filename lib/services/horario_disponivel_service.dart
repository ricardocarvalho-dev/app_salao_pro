import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class HorarioDisponivelService {
  final supabase = Supabase.instance.client;

  Future<void> gerarHorariosDisponiveis({
    required String salaoId,
    required String especialidadeId,
    required String servicoId,
    String? profissionalId,
    required DateTime data,
    required List<String> horarios, // ex: ['09:00', '09:30', '10:00']
  }) async {
    final uuid = Uuid();

    final List<Map<String, dynamic>> horariosParaInserir = horarios.map((hora) {
      return {
        'id': uuid.v4(),
        'salao_id': salaoId,
        'especialidade_id': especialidadeId,
        'servico_id': servicoId,
        'profissional_id': profissionalId,
        'data': data.toIso8601String().split('T').first,
        'horario': hora,
        'ocupado': false,
        'created_at': DateTime.now().toIso8601String(),
      };
    }).toList();

    final response = await supabase
        .from('horarios_disponiveis')
        .insert(horariosParaInserir);

    if (response.error != null) {
      throw Exception('Erro ao gerar horários: ${response.error!.message}');
    }
  }
}
